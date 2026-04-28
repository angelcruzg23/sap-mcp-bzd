FUNCTION ZSD_PPD_REJ_UPDATE
  IMPORTING
    I_CPQ TYPE CHAR01 OPTIONAL
  EXPORTING
    UPDATE_FAILED TYPE C
    EMAIL TYPE AD_SMTPADR
  TABLES
    T_VBAP LIKE VBAP OPTIONAL
    TA_AGENTS LIKE ZFI_AGENT_STRUCT OPTIONAL
    TA_BAPIRET TYPE BAPIRET2_T OPTIONAL.



*&---------------------------------------------------------------------*
* 10/31/2016   BZDK913061           SUVARNARAKSH    CRQ38985/1073633   *
* Search Term : RS10272016                                             *
* Text : Use Deviation "From", when considering for Triggering Workflow*
*&---------------------------------------------------------------------*
* 03/26/2019   BZDK917002            KOTWALDEEPAL    CRQ92766/1877808  *
* Search Term : DK03262019                                             *
* Text : While removing the rejection reason code if it fails send email to
*        last agent and populate flag for passed/failed and email address
*
*&---------------------------------------------------------------------*
* 04/21/2026   CHG0436393                                              *
* Search Term : CHG0436393                                             *
* Text : Validate enqueue lock before calling BAPI_CUSTOMERQUOTATION_  *
*        CHANGE. Wait up to 2 minutes (24 retries x 5 sec) if the     *
*        quotation is locked by another user.                          *
*&---------------------------------------------------------------------*
  DATA:   ls_bapisdh1x TYPE bapisdh1x,
          ls_bapisditmx TYPE bapisditmx,
          ls_bapisditm TYPE bapisditm,
          ls_vbap TYPE vbap,
          i_salesorder TYPE vbeln_va.

  DATA:   lt_bapiret2 TYPE STANDARD TABLE OF bapiret2,
          lt_bapisditm TYPE STANDARD TABLE OF bapisditm ,
          lt_bapisditmx TYPE STANDARD TABLE OF bapisditmx.

** send mail
  DATA : lt_mess_bod  TYPE TABLE OF solisti1,
       lt_packlist  TYPE TABLE OF sopcklsti1,
       lt_receivers TYPE TABLE OF somlreci1,
       lt_param     TYPE TABLE OF zca_parameter_t.

  DATA : ls_mess_bod  TYPE solisti1,
         ls_packlist  TYPE sopcklsti1,
         ls_docdata   TYPE sodocchgi1,
         ls_receivers TYPE somlreci1,
         ls_param     TYPE zca_parameter_t.

  DATA : lv_adrno TYPE ad_addrnum,
         lv_perno TYPE ad_persnum,
         lv_email TYPE ad_smtpadr,
         lv_adrno1 TYPE ad_addrnum,
         lv_perno1 TYPE ad_persnum,
         lv_email1 TYPE ad_smtpadr,
         lv_ernam TYPE ernam,
         ls_vbak TYPE vbak.

  DATA: lv_count TYPE i,
        ls_bapiret2 TYPE bapiret2,
        lv_agents TYPE zfi_agent_struct.

* >>> BEGIN OF INSERT +CHG0436393
  CONSTANTS: lc_max_retries TYPE i VALUE 24,    "24 retries x 5 sec = 120 sec (2 min)
             lc_wait_secs   TYPE i VALUE 5.     "Seconds to wait between retries
  DATA: lv_retry_count  TYPE i,
        lv_lock_acquired TYPE abap_bool,
        lv_lock_user     TYPE sy-uname.
* <<< END OF INSERT +CHG0436393

  IF t_vbap[] IS NOT INITIAL.

    CLEAR: ls_bapisdh1x, ls_bapisditmx, ls_bapisditmx.
    FREE: ls_bapisditmx, lt_bapisditmx.
    MOVE 'U' TO ls_bapisdh1x-updateflag.
    SORT t_vbap BY posnr.

    LOOP AT t_vbap INTO ls_vbap.
      MOVE: ls_vbap-posnr TO ls_bapisditm-itm_number,
            ' '           TO ls_bapisditm-reason_rej,
            ls_vbap-posnr TO ls_bapisditmx-itm_number,
            'X'           TO ls_bapisditmx-reason_rej,
            'U'           TO ls_bapisditmx-updateflag.

      APPEND: ls_bapisditm  TO lt_bapisditm,
              ls_bapisditmx TO lt_bapisditmx.

    ENDLOOP.

    CLEAR ls_vbap.
    READ TABLE t_vbap INTO ls_vbap INDEX 1 TRANSPORTING vbeln.

    IF ls_vbap-vbeln IS NOT INITIAL.
      MOVE ls_vbap-vbeln TO i_salesorder.
    ENDIF.

    DATA: gv_flag_ppd TYPE c.
    CLEAR gv_flag_ppd.
    MOVE 'X' TO gv_flag_ppd.
    EXPORT gv_flag_ppd TO MEMORY ID 'ZPPD_WF'.

* >>> BEGIN OF INSERT +CHG0436393
*   Validate enqueue lock before calling BAPI
    lv_retry_count  = 0.
    lv_lock_acquired = abap_false.

    WHILE lv_lock_acquired = abap_false AND lv_retry_count < lc_max_retries.
      CALL FUNCTION 'ENQUEUE_EVVBAKE'
        EXPORTING
          mode_vbak  = 'E'
          mandt      = sy-mandt
          vbeln      = i_salesorder
        EXCEPTIONS
          foreign_lock   = 1
          system_failure = 2
          OTHERS         = 3.

      IF sy-subrc = 0.
        lv_lock_acquired = abap_true.
      ELSE.
        lv_retry_count = lv_retry_count + 1.
        lv_lock_user = sy-msgv1. "User who holds the lock
        IF lv_retry_count < lc_max_retries.
          WAIT UP TO lc_wait_secs SECONDS.
        ENDIF.
      ENDIF.
    ENDWHILE.

*   If lock could not be acquired after max retries, treat as error
    IF lv_lock_acquired = abap_false.
      update_failed = 'X'.

      IF i_cpq = abap_true.
        ls_bapiret2-type    = 'E'.
        ls_bapiret2-id      = 'ZSD'.
        ls_bapiret2-number  = '000'.
        CONCATENATE 'Quotation' i_salesorder
          'is locked by user' lv_lock_user
          '- could not update after 2 min wait'
          INTO ls_bapiret2-message SEPARATED BY space.
        APPEND ls_bapiret2 TO ta_bapiret.
        RETURN.
      ENDIF.

*     Reuse existing error notification logic for non-CPQ scenario
      CLEAR lv_count.
      DESCRIBE TABLE ta_agents LINES lv_count.
      READ TABLE ta_agents INTO lv_agents INDEX lv_count.

      CLEAR : lv_adrno, lv_perno, lv_email.
      SELECT SINGLE addrnumber persnumber FROM usr21
        INTO (lv_adrno, lv_perno)
        WHERE bname = lv_agents-app_user+2(12).
      IF sy-subrc EQ 0.
        SELECT SINGLE smtp_addr FROM adr6
          INTO lv_email
          WHERE addrnumber = lv_adrno
            AND persnumber = lv_perno.
      ENDIF.

      REFRESH lt_mess_bod.
      CONCATENATE 'Product Price Deviation (PPD) Quotation' i_salesorder
        'could not be updated because it is locked by user' lv_lock_user
        'after waiting 2 minutes.'
        INTO ls_mess_bod SEPARATED BY space.
      CONDENSE ls_mess_bod.
      APPEND ls_mess_bod TO lt_mess_bod.
      CLEAR ls_mess_bod.
      APPEND ls_mess_bod TO lt_mess_bod.

      CONCATENATE 'Next Action: Please ensure the quotation' i_salesorder
        'is not being edited by another user, then retry the approval'
        'or remove the Reason for Rejection manually.'
        INTO ls_mess_bod SEPARATED BY space.
      APPEND ls_mess_bod TO lt_mess_bod.
      CLEAR ls_mess_bod.
      APPEND ls_mess_bod TO lt_mess_bod.

      CONCATENATE 'Note : This is an autogenerated mail from'
        sy-sysid '-' sy-mandt INTO ls_mess_bod SEPARATED BY space.
      APPEND ls_mess_bod TO lt_mess_bod.

      CLEAR ls_docdata.
      ls_docdata-obj_name = 'SAPRPT'.
      CONCATENATE 'Lock Error PPD Quotation#' i_salesorder
        INTO ls_docdata-obj_descr SEPARATED BY space.
      ls_docdata-obj_langu = sy-langu.
      ls_docdata-sensitivty = 'C'.

      CLEAR : ls_packlist, lt_packlist[].
      REFRESH : lt_receivers, lt_param.
      CLEAR : ls_receivers, ls_param.
      ls_packlist-transf_bin = space.
      ls_packlist-head_start = 1.
      ls_packlist-head_num = 0.
      ls_packlist-body_start = 1.
      DESCRIBE TABLE lt_mess_bod LINES ls_packlist-body_num.
      ls_packlist-doc_type = 'RAW'.
      APPEND ls_packlist TO lt_packlist.

      ls_receivers-receiver = lv_email.
      ls_receivers-express  = 'X'.
      ls_receivers-com_type = 'INT'.
      ls_receivers-rec_type = 'U'.
      APPEND ls_receivers TO lt_receivers.

      CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
        EXPORTING
          document_data              = ls_docdata
          put_in_outbox              = 'X'
          commit_work                = 'X'
        TABLES
          packing_list               = lt_packlist
          contents_txt               = lt_mess_bod
          receivers                  = lt_receivers
        EXCEPTIONS
          too_many_receivers         = 1
          document_not_sent          = 2
          document_type_not_exist    = 3
          operation_no_authorization = 4
          parameter_error            = 5
          x_error                    = 6
          enqueue_error              = 7
          OTHERS                     = 8.

      IF lv_email IS NOT INITIAL.
        email = lv_email.
      ENDIF.

*     Raise error so WF step goes to ERROR status (restartable via SWPR)
      MESSAGE e000(zsd) WITH 'Quotation' i_salesorder 'locked by' lv_lock_user.
    ENDIF.
* <<< END OF INSERT +CHG0436393

    CALL FUNCTION 'BAPI_CUSTOMERQUOTATION_CHANGE'
      EXPORTING
        salesdocument        = i_salesorder
        quotation_header_inx = ls_bapisdh1x
      TABLES
        return               = lt_bapiret2
        quotation_item_in    = lt_bapisditm
        quotation_item_inx   = lt_bapisditmx.

    READ TABLE lt_bapiret2 WITH KEY type = 'E' TRANSPORTING NO FIELDS.
    IF sy-subrc NE 0.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
*            EXPORTING
**              wait = 'X'.

* >>> BEGIN OF INSERT +CHG0436393
*     Release our enqueue lock after successful BAPI + COMMIT
      CALL FUNCTION 'DEQUEUE_EVVBAKE'
        EXPORTING
          mode_vbak = 'E'
          mandt     = sy-mandt
          vbeln     = i_salesorder.
* <<< END OF INSERT +CHG0436393

*To send approval email to WF Initiator about the completion of the approval process.
      IF i_cpq = abap_true.
        RETURN.
      ENDIF.

      CLEAR ls_vbak.
      SELECT SINGLE * FROM vbak INTO ls_vbak WHERE vbeln = i_salesorder.
      IF sy-subrc EQ 0.
** send mail
* Populate message body.
        REFRESH lt_mess_bod.
* >>> BEGIN OF CHANGES +RS10272016
*        CONCATENATE 'Product Price Deviation (PPD) Quotation has been approved' '!' INTO ls_mess_bod
        WRITE i_salesorder TO ls_vbak-vbeln NO-ZERO LEFT-JUSTIFIED.
        CONCATENATE 'Your Product Price Deviation (PPD) Quotation' ls_vbak-vbeln 'has been approved, Please proceed with the creation of the Order' INTO ls_mess_bod
        SEPARATED BY space.
        CONDENSE ls_mess_bod.
        APPEND ls_mess_bod TO lt_mess_bod.
        APPEND INITIAL LINE TO lt_mess_bod.
        CLEAR ls_mess_bod.
**        CONCATENATE 'Quotation#' i_salesorder INTO ls_mess_bod SEPARATED BY space.
**        CLEAR ls_mess_bod.
**        APPEND ls_mess_bod TO lt_mess_bod.
**        APPEND ls_mess_bod TO lt_mess_bod.
**        APPEND ls_mess_bod TO lt_mess_bod.
* <<< END   OF CHANGES +RS10272016
        CONCATENATE 'NB : This is an autogenerated mail from' sy-sysid sy-mandt INTO ls_mess_bod SEPARATED BY space.
        APPEND ls_mess_bod TO lt_mess_bod.

*General data
*Fill the document data.
        CLEAR ls_docdata.
        ls_docdata-obj_name = 'SAPRPT'.
        CONCATENATE 'Approved PPD Quotation#' ls_vbak-vbeln INTO ls_docdata-obj_descr SEPARATED BY space.
        ls_docdata-obj_langu = sy-langu.
        ls_docdata-sensitivty = 'C'.

*Describe the body of the message ie packing list
        CLEAR : ls_packlist, lt_packlist[].
        REFRESH : lt_receivers, lt_param.
        CLEAR : ls_receivers, ls_param.
        ls_packlist-transf_bin = space.
        ls_packlist-head_start = 1.
        ls_packlist-head_num = 0.
        ls_packlist-body_start = 1.
        DESCRIBE TABLE lt_mess_bod LINES ls_packlist-body_num.
        ls_packlist-doc_type = 'RAW'.
        APPEND ls_packlist TO lt_packlist.

** Get Receiver List
        CLEAR : lv_adrno, lv_perno, lv_email.
        SELECT SINGLE addrnumber persnumber FROM usr21 INTO (lv_adrno, lv_perno) WHERE bname = ls_vbak-ernam.
        IF sy-subrc EQ 0.
          SELECT SINGLE smtp_addr FROM adr6 INTO lv_email WHERE addrnumber = lv_adrno AND persnumber = lv_perno.
        ENDIF.
        ls_receivers-receiver = lv_email.
        ls_receivers-express  = 'X'.
        ls_receivers-com_type = 'INT'.
        ls_receivers-rec_type = 'U'.
        APPEND ls_receivers TO lt_receivers.

        CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
          EXPORTING
            document_data              = ls_docdata
            put_in_outbox              = 'X'
            commit_work                = 'X'
          TABLES
            packing_list               = lt_packlist
            contents_txt               = lt_mess_bod
            receivers                  = lt_receivers
          EXCEPTIONS
            too_many_receivers         = 1
            document_not_sent          = 2
            document_type_not_exist    = 3
            operation_no_authorization = 4
            parameter_error            = 5
            x_error                    = 6
            enqueue_error              = 7
            OTHERS                     = 8.
        IF sy-subrc EQ 0.
*Implement suitable error handling here
        ENDIF.
      ENDIF.
    ELSE.

* >>> BEGIN OF INSERT +CHG0436393
*     Release our enqueue lock after failed BAPI
      CALL FUNCTION 'DEQUEUE_EVVBAKE'
        EXPORTING
          mode_vbak = 'E'
          mandt     = sy-mandt
          vbeln     = i_salesorder.
* <<< END OF INSERT +CHG0436393

      IF i_cpq = abap_true.
        MESSAGE i046(zsd) INTO ls_bapiret2-message.
        APPEND ls_bapiret2 TO ta_bapiret.

        MESSAGE i047(zsd) INTO ls_bapiret2-message.
        APPEND ls_bapiret2 TO ta_bapiret.

        LOOP AT lt_bapiret2 ASSIGNING FIELD-SYMBOL(<fs_bapiret2>).
          ls_bapiret2-message = <fs_bapiret2>-message.
          APPEND ls_bapiret2 TO ta_bapiret.
        ENDLOOP.

        RETURN.
      ENDIF.

**    Begin of insert by DK03262019
*      If the rejection reason code update failed populate the flag for failure and send email
*      to last agent
      update_failed = 'X'.
**    End of insert by DK03262019

      CLEAR lv_count.
      DESCRIBE TABLE ta_agents LINES lv_count.
      READ TABLE ta_agents INTO lv_agents INDEX lv_count.

      CLEAR : lv_adrno, lv_perno, lv_email.
      SELECT SINGLE addrnumber persnumber FROM usr21 INTO (lv_adrno, lv_perno) WHERE bname = lv_agents-app_user+2(12).
      IF sy-subrc EQ 0.
        SELECT SINGLE smtp_addr FROM adr6 INTO lv_email WHERE addrnumber = lv_adrno AND persnumber = lv_perno.
      ENDIF.
** send mail
* Populate message body.
      REFRESH lt_mess_bod.
      CONCATENATE 'Product Price Deviation (PPD) Quotation has not been completely approved due to below errors' ':' INTO ls_mess_bod
      SEPARATED BY space.
      APPEND ls_mess_bod TO lt_mess_bod.
      CLEAR: ls_mess_bod, ls_mess_bod.
      LOOP AT lt_bapiret2 INTO ls_bapiret2.
        MOVE ls_bapiret2-message TO ls_mess_bod.
        APPEND ls_mess_bod TO lt_mess_bod.
      ENDLOOP.
      ls_mess_bod = ''.
      APPEND ls_mess_bod TO lt_mess_bod.
      CLEAR ls_mess_bod.
      CONCATENATE 'Quotation#' i_salesorder INTO ls_mess_bod SEPARATED BY space.
      CLEAR ls_mess_bod.
      APPEND ls_mess_bod TO lt_mess_bod.
      CLEAR ls_mess_bod.
      CONCATENATE 'Next Action:' 'Please update the quote:' i_salesorder 'manually. Remove Reason for Rejection (Price suggestion Not Approved(PPD)) manually from the line items.' INTO ls_mess_bod SEPARATED BY space.
      APPEND ls_mess_bod TO lt_mess_bod.
      clear ls_mess_bod.
      APPEND ls_mess_bod TO lt_mess_bod.
      APPEND ls_mess_bod TO lt_mess_bod.
      CONCATENATE 'Note : This is an autogenerated mail from' sy-sysid '-' sy-mandt INTO ls_mess_bod SEPARATED BY space.
      APPEND ls_mess_bod TO lt_mess_bod.

* General data
* Fill the document data.
      CLEAR ls_docdata.
      ls_docdata-obj_name = 'SAPRPT'.
      CONCATENATE 'Error during PPD Approval-Quote#' i_salesorder INTO ls_docdata-obj_descr SEPARATED BY space.
      ls_docdata-obj_langu = sy-langu.
      ls_docdata-sensitivty = 'C'.

*Describe the body of the message ie packing list
      CLEAR : ls_packlist, lt_packlist[].
      REFRESH : lt_receivers, lt_param.
      CLEAR : ls_receivers, ls_param.
      ls_packlist-transf_bin = space.
      ls_packlist-head_start = 1.
      ls_packlist-head_num = 0.
      ls_packlist-body_start = 1.
      DESCRIBE TABLE lt_mess_bod LINES ls_packlist-body_num.
      ls_packlist-doc_type = 'RAW'.
      APPEND ls_packlist TO lt_packlist.

** Get Receiver List
      ls_receivers-receiver = lv_email.
      ls_receivers-express  = 'X'.
      ls_receivers-com_type = 'INT'.
      ls_receivers-rec_type = 'U'.
      APPEND ls_receivers TO lt_receivers.

      CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
        EXPORTING
          document_data              = ls_docdata
          put_in_outbox              = 'X'
          commit_work                = 'X'
        TABLES
          packing_list               = lt_packlist
          contents_txt               = lt_mess_bod
          receivers                  = lt_receivers
        EXCEPTIONS
          too_many_receivers         = 1
          document_not_sent          = 2
          document_type_not_exist    = 3
          operation_no_authorization = 4
          parameter_error            = 5
          x_error                    = 6
          enqueue_error              = 7
          OTHERS                     = 8.
      IF sy-subrc EQ 0.
*Implement suitable error handling here
      ENDIF.

**Begin of insert by DK03262019
**If the rejection reason code update failed/passed populate the email to check log
      IF lv_email IS NOT INITIAL.
        email = lv_email.
      ENDIF.
**End of insert by DK03262019
    ENDIF.
  ENDIF.

*ENDIF.




ENDFUNCTION.