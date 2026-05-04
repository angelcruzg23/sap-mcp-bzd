FUNCTION ZSD_QUOTATION_SALSFRC_CREATE
  IMPORTING
    VALUE(SALESDOCUMENTIN) LIKE BAPIVBELN-VBELN OPTIONAL
    VALUE(QUOTATION_HEADER_IN) LIKE ZSD_BAPISDHD1
    VALUE(QUOTATION_HEADER_INX) LIKE BAPISDHD1X OPTIONAL
    VALUE(SENDER) LIKE BAPI_SENDER OPTIONAL
    VALUE(BINARY_RELATIONSHIPTYPE) LIKE BAPIRELTYPE-RELTYPE DEFAULT SPACE
    VALUE(INT_NUMBER_ASSIGNMENT) LIKE BAPIFLAG-BAPIFLAG DEFAULT SPACE
    VALUE(BEHAVE_WHEN_ERROR) LIKE BAPIFLAG-BAPIFLAG DEFAULT SPACE
    VALUE(LOGIC_SWITCH) LIKE BAPISDLS OPTIONAL
    VALUE(TESTRUN) LIKE BAPIFLAG-BAPIFLAG OPTIONAL
    VALUE(CONVERT) LIKE BAPIFLAG-BAPIFLAG DEFAULT SPACE
  EXPORTING
    VALUE(SALESDOCUMENT) LIKE BAPIVBELN-VBELN
  TABLES
    QUOTATION_ITEMS_IN LIKE ZST_SD_BAPISDITM OPTIONAL
    QUOTATION_ITEMS_INX LIKE BAPISDITMX OPTIONAL
    QUOTATION_PARTNERS LIKE BAPIPARNR
    QUOTATION_SCHEDULES_IN LIKE ZST_SD_BAPISCHDL OPTIONAL
    QUOTATION_SCHEDULES_INX LIKE BAPISCHDLX OPTIONAL
    QUOTATION_CONDITIONS_IN LIKE ZST_SD_BAPICOND OPTIONAL
    QUOTATION_CONDITIONS_INX LIKE BAPICONDX OPTIONAL
    QUOTATION_CFGS_REF LIKE BAPICUCFG OPTIONAL
    QUOTATION_CFGS_INST LIKE BAPICUINS OPTIONAL
    QUOTATION_CFGS_PART_OF LIKE BAPICUPRT OPTIONAL
    QUOTATION_CFGS_VALUE LIKE BAPICUVAL OPTIONAL
    QUOTATION_CFGS_BLOB LIKE BAPICUBLB OPTIONAL
    QUOTATION_CFGS_VK LIKE BAPICUVK OPTIONAL
    QUOTATION_CFGS_REFINST LIKE BAPICUREF OPTIONAL
    QUOTATION_KEYS LIKE BAPISDKEY OPTIONAL
    QUOTATION_TEXT LIKE BAPISDTEXT OPTIONAL
    PARTNERADDRESSES LIKE BAPIADDR1 OPTIONAL
    E_RETURN_T LIKE ZST_SD_BAPIRETURN OPTIONAL.




  CONSTANTS lc_zdg TYPE c LENGTH 3 VALUE 'ZDG'.
  CONSTANTS lc_003 TYPE c LENGTH 3 VALUE '003'.



  DATA: return TYPE TABLE OF  bapiret2.

  DATA: lt_extensionin  TYPE TABLE OF bapiparex,
        ls_extensionin  TYPE bapiparex,
        ls_bape_vbak    TYPE bape_vbak,
        ls_bape_vbakx   TYPE bape_vbakx,
        ls_quot_head_in TYPE bapisdhd1,
        wa_quote        LIKE LINE OF quotation_items_in,
        wa_schedules    LIKE LINE OF quotation_schedules_in,
        ls_bape_vbap    TYPE bape_vbap,
        ls_bape_vbapx   TYPE bape_vbapx.
  DATA: it_item_in  TYPE TABLE OF zst_sd_bapisditm,
        wa_item     LIKE LINE OF it_item_in,
        wa_return   LIKE LINE OF return,
        wa_e_return LIKE LINE OF e_return_t.

  DATA: order_header_in    LIKE  zsd_bapisdhead_cpq,
        order_items_in     TYPE TABLE OF  zst_sd_bapiitemin,
        wa_items           LIKE LINE OF order_items_in,
        order_partners     TYPE TABLE OF zst_sd_bapipartnr,
        order_schedule_in  TYPE TABLE OF  zst_sd_bapischdl,
        wa_schedule        LIKE LINE OF order_schedule_in,
        order_items_out    TYPE TABLE OF  zst_sd_bapiitemex,
        order_cfgs_ref     TYPE TABLE OF bapicucfg,
        order_cfgs_inst    TYPE TABLE OF  bapicuins,
        order_cfgs_part_of TYPE TABLE OF  bapicuprt,
        order_cfgs_value   TYPE TABLE OF  bapicuval,
        lt_return          TYPE TABLE OF bapireturn,
        ls_return          TYPE bapireturn,
        order_cfgs_blob    TYPE TABLE OF  bapicublb,
        order_ccard        TYPE TABLE OF  bapiccard,
        order_ccard_ex     TYPE TABLE OF bapiccard_ex,
        order_schedule_ex  TYPE TABLE OF  zst_sd_bapisdhedu,
        order_condition_ex TYPE TABLE OF  zst_sd_bapicond,
        order_incomplete   TYPE TABLE OF zst_sd_bapiincomp,
        messagetable       TYPE TABLE OF bapiret2,
        extensionin        TYPE TABLE OF  bapiparex,
*        partneraddresses  TYPE TABLE OF bapiaddr1,
        allowedplants      TYPE TABLE OF  zsd_allowd_plnts,

*        salesdocument LIKE  bapivbeln-vbeln,
        sold_to_party      LIKE  bapisoldto,
        ship_to_party      LIKE  bapishipto,
        billing_party      LIKE  bapipayer.
*        return  LIKE  bapireturn.

  DATA: lt_quotation_items_in     TYPE STANDARD TABLE OF bapisditm.
  DATA: lt_quotation_schedules_in TYPE STANDARD TABLE OF bapischdl.
  DATA: lt_quotation_conditions_in TYPE STANDARD TABLE OF bapicond.

  FIELD-SYMBOLS: <fs_items_in>  LIKE LINE OF quotation_items_in,
                 <fs_schedules> LIKE LINE OF quotation_schedules_in,
                 <fs_partner>   LIKE LINE OF quotation_partners,
                 <fs_cond>      LIKE LINE OF quotation_conditions_in.

*.ins.angecruz Check salesforce ID duplication
*.Import salesforce id controller
  DATA(lo_sf_id) = NEW zcl_sd_zfdc_controller_id( quotation_header_in-zzsalesforce_id  ).


  "Check if salesforce exists?
  DATA(lv_vbeln) = lo_sf_id->exists(  ).
  IF lv_vbeln IS NOT INITIAL .

    MESSAGE ID 'ZSD_CPQ' TYPE 'I' NUMBER 014 INTO DATA(lv_message) WITH lv_vbeln.
    wa_e_return-message = lv_message.
    wa_e_return-message_v1 = lv_vbeln.
    wa_e_return-type = 'E'.
    wa_e_return-log_no = '014'.
    APPEND wa_e_return TO e_return_t.
    EXIT.
  ENDIF.
*.end

  LOOP AT quotation_partners ASSIGNING <fs_partner>.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = <fs_partner>-partn_numb
      IMPORTING
        output = <fs_partner>-partn_numb.

  ENDLOOP.

  MOVE-CORRESPONDING quotation_header_in TO ls_quot_head_in.

  ls_bape_vbak-zzsalesforce_id  = quotation_header_in-zzsalesforce_id.
  ls_bape_vbakx-zzsalesforce_id = abap_true.
  ls_extensionin-structure      = 'BAPE_VBAK'.
  ls_extensionin+30             = ls_bape_vbak.
  APPEND ls_extensionin TO lt_extensionin.
  CLEAR ls_extensionin.
  ls_extensionin-structure  = 'BAPE_VBAKX'.
  ls_extensionin-valuepart1 = ls_bape_vbakx.
  APPEND ls_extensionin TO lt_extensionin.

  LOOP AT quotation_items_in INTO wa_quote.
    IF wa_quote-zzsalesforce_id IS NOT INITIAL.
      CLEAR: ls_bape_vbap, ls_bape_vbapx, ls_extensionin.
      ls_bape_vbap-vbeln            = salesdocument.
      ls_bape_vbapx-vbeln           = salesdocument.
      ls_bape_vbap-posnr            = wa_quote-itm_number.
      ls_bape_vbapx-posnr           = wa_quote-itm_number.
      ls_bape_vbap-zzsalesforce_id  = wa_quote-zzsalesforce_id.
      ls_bape_vbapx-zzsalesforce_id = abap_true.
      ls_extensionin-structure      = 'BAPE_VBAP'.
      ls_extensionin+30             = ls_bape_vbap.
      APPEND ls_extensionin TO lt_extensionin.
      CLEAR ls_extensionin.
      ls_extensionin-structure = 'BAPE_VBAPX'.
      ls_extensionin+30        = ls_bape_vbapx.
      APPEND ls_extensionin TO lt_extensionin.
    ENDIF.
  ENDLOOP.

  LOOP AT quotation_items_in ASSIGNING <fs_items_in>.
    IF <fs_items_in>-target_qu IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
        EXPORTING
          input          = <fs_items_in>-target_qu
        IMPORTING
          output         = <fs_items_in>-target_qu
        EXCEPTIONS
          unit_not_found = 1
          OTHERS         = 2.
    ENDIF.

    IF <fs_items_in>-sales_unit IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
        EXPORTING
          input          = <fs_items_in>-sales_unit
        IMPORTING
          output         = <fs_items_in>-sales_unit
        EXCEPTIONS
          unit_not_found = 1
          OTHERS         = 2.

    ENDIF.

*.CHG0397042 US HBE - Update SFDC to SAP quote plant change
*.ins.angecruz Adding shipping point to the item position
    <fs_items_in>-ship_point = zcl_sd_get_shipping_point=>get_value(
        EXPORTING
            iv_vkorg = quotation_header_in-sales_org
            iv_vtweg = quotation_header_in-distr_chan
            iv_spart = quotation_header_in-division
            iv_vsbed = quotation_header_in-ship_type
            iv_matnr = <fs_items_in>-material
            iv_werks = <fs_items_in>-plant ).


*.end
  ENDLOOP.
  LOOP AT quotation_conditions_in ASSIGNING <fs_cond>.
    IF <fs_cond>-cond_unit IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
        EXPORTING
          input          = <fs_cond>-cond_unit
        IMPORTING
          output         = <fs_cond>-cond_unit
        EXCEPTIONS
          unit_not_found = 1
          OTHERS         = 2.

    ENDIF.
  ENDLOOP.

  SET PARAMETER ID 'ZSD_SHIPPING_TYPE' FIELD ls_quot_head_in-ship_type.
  SET PARAMETER ID 'ZSD_ENVIAR_IDOC' FIELD abap_true.


  lt_quotation_items_in     = CORRESPONDING #( quotation_items_in[] ).
  lt_quotation_schedules_in = CORRESPONDING #( quotation_schedules_in[] ).
  lt_quotation_conditions_in = CORRESPONDING #( quotation_conditions_in[] ).

  CALL FUNCTION 'BAPI_QUOTATION_CREATEFROMDATA2'
    EXPORTING
      salesdocumentin          = salesdocumentin
      quotation_header_in      = ls_quot_head_in
      quotation_header_inx     = quotation_header_inx
      sender                   = sender
      binary_relationshiptype  = binary_relationshiptype
      int_number_assignment    = int_number_assignment
      behave_when_error        = behave_when_error
      logic_switch             = logic_switch
      testrun                  = testrun
      convert                  = convert
    IMPORTING
      salesdocument            = salesdocument
    TABLES
      return                   = return
      quotation_items_in       = lt_quotation_items_in
      quotation_items_inx      = quotation_items_inx
      quotation_partners       = quotation_partners
      quotation_schedules_in   = lt_quotation_schedules_in
      quotation_schedules_inx  = quotation_schedules_inx
      quotation_conditions_in  = lt_quotation_conditions_in
      quotation_conditions_inx = quotation_conditions_inx
      quotation_cfgs_ref       = quotation_cfgs_ref
      quotation_cfgs_inst      = quotation_cfgs_inst
      quotation_cfgs_part_of   = quotation_cfgs_part_of
      quotation_cfgs_value     = quotation_cfgs_value
      quotation_cfgs_blob      = quotation_cfgs_blob
      quotation_cfgs_vk        = quotation_cfgs_vk
      quotation_cfgs_refinst   = quotation_cfgs_refinst
      quotation_keys           = quotation_keys
      quotation_text           = quotation_text
      extensionin              = lt_extensionin
      partneraddresses         = partneraddresses.

  quotation_items_in[]      = CORRESPONDING #( lt_quotation_items_in[] ).
  quotation_schedules_in[]  = CORRESPONDING #( lt_quotation_schedules_in[] ).
  quotation_conditions_in[] = CORRESPONDING #( lt_quotation_conditions_in[] ).


  SET PARAMETER ID 'ZSD_ENVIAR_IDOC' FIELD abap_false.
  LOOP AT quotation_schedules_in ASSIGNING <fs_schedules>.
    READ TABLE quotation_items_in INTO  wa_quote WITH KEY itm_number = <fs_schedules>-itm_number.
    IF sy-subrc EQ 0.
      <fs_schedules>-zzsalesforce_id = wa_quote-zzsalesforce_id.
    ENDIF.
  ENDLOOP.

  LOOP AT quotation_conditions_in ASSIGNING <fs_cond>.
    READ TABLE quotation_items_in INTO  wa_quote WITH KEY itm_number = <fs_cond>-itm_number.
    IF sy-subrc EQ 0.
      <fs_cond>-zzsalesforce_id = wa_quote-zzsalesforce_id.
    ENDIF.
    IF <fs_cond>-cond_unit IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
        EXPORTING
          input          = <fs_cond>-cond_unit
        IMPORTING
          output         = <fs_cond>-cond_unit
        EXCEPTIONS
          unit_not_found = 1
          OTHERS         = 2.

    ENDIF.
  ENDLOOP.
  LOOP AT quotation_items_in ASSIGNING <fs_items_in>.
    IF <fs_items_in>-target_qu IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
        EXPORTING
          input          = <fs_items_in>-target_qu
        IMPORTING
          output         = <fs_items_in>-target_qu
        EXCEPTIONS
          unit_not_found = 1
          OTHERS         = 2.
    ENDIF.

    IF <fs_items_in>-sales_unit IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
        EXPORTING
          input          = <fs_items_in>-sales_unit
        IMPORTING
          output         = <fs_items_in>-sales_unit
        EXCEPTIONS
          unit_not_found = 1
          OTHERS         = 2.
    ENDIF.
  ENDLOOP.

*.ins.angecruz Persist quotation generated
  DATA(lc_subrc) = lo_sf_id->create( salesdocument ).
*.end

  READ TABLE return TRANSPORTING NO FIELDS
    WITH KEY type = 'E'.
  IF sy-subrc NE 0.
    SET PARAMETER ID 'ZSD_SHIPPING_TYPE' FIELD space.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
    LOOP AT return INTO wa_return.
      MOVE-CORRESPONDING wa_return TO wa_e_return.
      APPEND wa_e_return TO e_return_t.
      CLEAR: wa_e_return.
    ENDLOOP.
    EXIT.
  ELSE.
    READ TABLE return ASSIGNING FIELD-SYMBOL(<fs_return>)
    WITH KEY id     = lc_zdg
             number = lc_003.
    IF sy-subrc IS INITIAL.
      <fs_return>-message = zcl_sd_sfdc_processing_voc=>get_sfdc_voc_text(  ).
    ENDIF.
  ENDIF.


  MOVE-CORRESPONDING ls_quot_head_in TO order_header_in.

*order_items_in
  LOOP AT quotation_items_in INTO wa_item.
    MOVE-CORRESPONDING wa_item TO wa_items.



    APPEND wa_items TO order_items_in.
  ENDLOOP.

  LOOP AT quotation_schedules_in INTO wa_schedules.
    MOVE-CORRESPONDING wa_schedules TO wa_schedule.
    APPEND wa_schedule TO order_schedule_in.
  ENDLOOP.
  MOVE-CORRESPONDING quotation_partners[] TO order_partners[].
  CALL FUNCTION 'ZSD_SALESORD_SALSFRC_SIMULATE'
    EXPORTING
      order_header_in    = order_header_in
*     CONVERT_PARVW_AUART       = ' '
    IMPORTING
      salesdocument      = salesdocument
      sold_to_party      = sold_to_party
      ship_to_party      = ship_to_party
      billing_party      = billing_party
      return             = ls_return
    TABLES
      order_items_in     = order_items_in
      order_partners     = order_partners
      order_schedule_in  = order_schedule_in
      order_items_out    = order_items_out
      order_cfgs_ref     = order_cfgs_ref
      order_cfgs_inst    = order_cfgs_inst
      order_cfgs_part_of = order_cfgs_part_of
      order_cfgs_value   = order_cfgs_value
      order_cfgs_blob    = order_cfgs_blob
      order_ccard        = order_ccard
      order_ccard_ex     = order_ccard_ex
      order_schedule_ex  = order_schedule_ex
      order_condition_ex = order_condition_ex
      order_incomplete   = order_incomplete
      messagetable       = messagetable
      extensionin        = extensionin
      partneraddresses   = partneraddresses
      allowedplants      = allowedplants
      e_return_t         = e_return_t.
  SET PARAMETER ID 'ZSD_SHIPPING_TYPE' FIELD space.

  LOOP AT return INTO wa_return.
    CLEAR wa_e_return.
    MOVE-CORRESPONDING wa_return TO wa_e_return.
    READ TABLE quotation_items_in INTO wa_quote INDEX wa_return-row.
    IF sy-subrc IS INITIAL.
      wa_e_return-zzpos      = wa_quote-itm_number. "Posicion.
      wa_e_return-zzsalesforce_id = wa_quote-zzsalesforce_id.
    ENDIF.
    APPEND wa_e_return TO e_return_t.
    CLEAR: wa_e_return.
  ENDLOOP.


ENDFUNCTION.
