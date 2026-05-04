**&---------------------------------------------------------------------*
**&  Include           ZSDR_DAILY_INVOICE_REPORT_F01
**&---------------------------------------------------------------------*
*
FORM f_get_data .

  TYPES:BEGIN OF lty_invoice,
          vbeln      TYPE vbeln_vf,          "10  Billing Document
          fkart      TYPE fkart,             " 4  Billing Type
          vkorg      TYPE vkorg,             " 4  Sales Organization
          erdat      TYPE erdat,             " 8  Date on Which Record Was Created
          ernam      TYPE ernam,             "12  Name of Person who Created the Object
          kunag      TYPE kunag,             "10  Sold-to party
          kschl      TYPE sna_kschl,         " 4  Message type
          na_erdat   TYPE na_erdat,          " 8  Date on which status record was created
          usnam      TYPE usnam,             "12  User name
          tdcovtitle TYPE so_obj_des,        "50  Short description of contents
          datvr      TYPE na_datvr,          " 8  Processing date
          nacha      TYPE na_nacha,          " 1  Message transmission medium
          tdreceiver TYPE syprrec,           "12  Spool Recipient Name
          uhrvr      TYPE na_uhrvr,          " 6  Processing time
          objky	     TYPE na_objkey,         "30  Object key ( Billing Document )
        END OF lty_invoice.
  DATA: ltt_invoice TYPE TABLE OF lty_invoice,
        lti_invoice_nast TYPE TABLE OF lty_invoice,
        lti_nast    TYPE TABLE OF nast.

  TYPES:BEGIN OF lty_sood_t,
          objtp         TYPE so_obj_tp,         " 3  Code for document class
          objyr         TYPE so_obj_yr,         " 2  Object: Year from ID
          objno         TYPE so_obj_no,         "12  Object: Number from ID
          objdes        TYPE so_obj_des,        "50  Short description of contents,
        END OF lty_sood_t.
  DATA: ltt_sood_t_hashed TYPE HASHED TABLE OF lty_sood_t
                          WITH UNIQUE KEY objdes objtp objyr objno.
  TYPES:BEGIN OF lty_sood,
          objno         TYPE so_obj_no,         "12  Object: Number from ID
          objdes        TYPE so_obj_des,        "50  Short description of contents
          objtp         TYPE so_obj_tp,         " 3  Code for document class
          objyr         TYPE so_obj_yr,         " 2  Object: Year from ID
          objnam        TYPE so_obj_nam,        "12  Name of document, folder or distribution list
          cronam        TYPE so_cro_nam,        "12  Creator Name
          stat_date     TYPE so_stadate,        " 8  Date of status
          scomno        TYPE so_scom_no,        "12  SAPcomm: number of the ID
        END OF lty_sood.
  DATA:   ltt_sood   TYPE TABLE OF lty_sood,
          ltt_sood_hashed TYPE HASHED TABLE OF lty_sood
                          WITH UNIQUE KEY objdes objtp objyr objno.

  TYPES:BEGIN OF lty_sost,
          objtp      TYPE so_obj_tp,         " 3  Code for document class
          objyr      TYPE so_obj_yr,         " 2  Object: Year from ID
          objno      TYPE so_obj_no,         "12  Object: Number from ID
          rectp      TYPE so_rec_tp,         " 3  Recipient type from ID
          recno      TYPE so_rec_no,         "12  Recipient number from ID
          sndart     TYPE so_snd_art,        " 6  Transmission Method (Fax, Telex, ...)
          snddat     TYPE so_dat_sd,         " 8  Date On Which Object Was Sent
          sndtim     TYPE so_tim_sd,         " 6  Time at Which The Object Was Sent
          scdate     TYPE so_sc_date,        " 8  SAPcomm: Transfer date to SAPcomm
          sctime     TYPE so_sc_time,        " 6  SAPcomm: Transfer time to SAPcomm
          msgid      TYPE symsgid,           "20  Message Class
          msgty      TYPE symsgty,           " 1  Message Type
          msgno      TYPE symsgno,           " 3  Message Number
          msgv1      TYPE symsgv,            "50  Message Variable
          creator    TYPE so_sta_cr,         "12  User name responsible for creating status
          counter    TYPE so_sta_cnt,        " 5  Counter for status entries for this send process
        END OF lty_sost.
  DATA:   ltt_sost   TYPE TABLE OF lty_sost,
          ltt_sost_hashed TYPE HASHED TABLE OF lty_sost
                          WITH UNIQUE KEY objtp objyr objno recno counter,
          lti_nacha  TYPE TABLE OF dd07v,
          lti_messag TYPE TABLE OF nast_msg.

  DATA: lr_obj_tp TYPE RANGE OF so_obj_tp.

* ── BEGIN FIX: EHP8 switch variable ──
  DATA: lv_ehp8_cutoff TYPE sy-datum.
* ── END FIX ──

  REFRESH: ltt_invoice, ltt_sood, ltt_sost.

  SELECT sign opti low high
    INTO TABLE lr_obj_tp
    FROM tvarvc
   WHERE name = 'ZSD_OBJ_TP'.

* ── BEGIN FIX: Read EHP8 cutoff date from TVARVC ──
* TVARVC variable: ZSD_DAILY_INV_EHP8_DATE (Type P)
* Before this date: original behavior (DELETE scomno records)
* After this date:  skip DELETE to avoid marking transmitted docs as Failed
  SELECT SINGLE low
    INTO lv_ehp8_cutoff
    FROM tvarvc
    WHERE name = 'ZSD_DAILY_INV_EHP8_DATE'
      AND type = 'P'.

  IF sy-subrc <> 0.
    " If variable does not exist, use original behavior (safe fallback)
    lv_ehp8_cutoff = '99991231'.
  ENDIF.
* ── END FIX ──

  " Information is extracted from the sales invoice table
  SELECT v1~vbeln v1~fkart v1~vkorg v1~erdat v1~ernam v1~kunag
         n1~kschl n1~erdat n1~usnam n1~tdcovtitle n1~datvr
*{ YC
         n1~nacha n1~tdreceiver n1~uhrvr v1~vbeln
*}
       INTO TABLE ltt_invoice
     FROM  vbrk AS v1
       LEFT OUTER JOIN nast AS n1  ON n1~objky EQ v1~vbeln
                                  AND n1~kappl EQ gc_appl
    WHERE v1~vbeln IN so_vbeln
    AND   v1~fkart IN so_fkart
    AND   v1~vkorg IN so_vkorg
    AND   v1~erdat IN so_erdat
    AND   v1~kunag IN so_kunag.

  DELETE ltt_invoice WHERE kschl NOT IN so_kschl.

  IF lines( ltt_invoice ) EQ 0.
    MESSAGE 'Data entered does not generate information' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*{ YC
  lti_invoice_nast = ltt_invoice.
  SORT lti_invoice_nast BY objky.
  DELETE ADJACENT DUPLICATES FROM lti_invoice_nast COMPARING objky.

  IF lti_invoice_nast IS NOT INITIAL.
    SELECT *
      INTO TABLE lti_nast
      FROM nast
       FOR ALL ENTRIES IN lti_invoice_nast
     WHERE objky EQ lti_invoice_nast-objky
       AND kappl EQ gc_appl.

    CLEAR: lti_invoice_nast.
  ENDIF.

  CALL FUNCTION 'DD_DOMVALUES_GET'
    EXPORTING
      domname        = 'NA_NACHA'
      text           = 'X'
      langu          = sy-langu
    TABLES
      dd07v_tab      = lti_nacha
    EXCEPTIONS
      wrong_textflag = 1
      OTHERS         = 2.

  READ TABLE lti_nacha INTO DATA(les_nacha)
  WITH KEY domvalue_l = '1'.
*}

  SORT ltt_invoice BY datvr ASCENDING.
  DESCRIBE TABLE ltt_invoice LINES DATA(lv_lines).

  DATA(lv_datvr_fedes) = so_erdat-low.
  DATA(gs_invoice)     = ltt_invoice[ lv_lines ].
  DATA(lv_datvr_fehas) = gs_invoice-datvr.

  so_datvr[] = VALUE #( sign = gc_inclusive option = gc_between
                    ( low = lv_datvr_fedes high = lv_datvr_fehas ) ).

  SORT ltt_invoice BY vbeln fkart vkorg.

  IF lr_obj_tp[] IS NOT INITIAL.
  " Information is extracted from the SAPoffice: Object definition table
  SELECT objtp objyr objno objdes INTO TABLE ltt_sood_t_hashed
    FROM sood
    WHERE crdat IN so_datvr
      AND objtp IN lr_obj_tp[].
  ENDIF.

  IF ltt_sood_t_hashed IS NOT INITIAL.

    DELETE ADJACENT DUPLICATES FROM ltt_sood_t_hashed COMPARING objdes objtp objyr objno.

    SELECT s1~objno s1~objdes s1~objtp s1~objyr s1~objnam s1~cronam
           s2~stat_date s2~scomno
         INTO TABLE ltt_sood
       FROM  sood AS s1
         INNER JOIN sost AS s2 ON s2~objtp EQ s1~objtp
                              AND s2~objyr EQ s1~objyr
                              AND s2~objno EQ s1~objno
         FOR ALL ENTRIES IN ltt_sood_t_hashed
             WHERE s1~objtp  = ltt_sood_t_hashed-objtp
             AND   s1~objyr  = ltt_sood_t_hashed-objyr
             AND   s1~objno  = ltt_sood_t_hashed-objno
             AND   s1~objdes = ltt_sood_t_hashed-objdes.

  ENDIF.

* ── BEGIN FIX: EHP8 switch — only delete scomno records for pre-EHP8 dates ──
* Original line: DELETE ltt_sood WHERE NOT scomno IS INITIAL.
* After EHP8, SAPconnect assigns scomno immediately upon transmission,
* so deleting these records incorrectly removes successfully sent documents.
  IF so_erdat-low < lv_ehp8_cutoff.
    " Pre-EHP8: original behavior
    DELETE ltt_sood WHERE NOT scomno IS INITIAL.
  ENDIF.
* ── END FIX ──

  FREE ltt_sood_t_hashed.

  IF lines( ltt_sood ) GT 0.
    " Information is extracted from the SAPoffice: Status log table
    SELECT s1~objtp s1~objyr s1~objno s1~rectp s1~recno s1~sndart
           s2~snddat s2~sndtim s2~scdate s2~sctime s1~msgid s1~msgty
           s1~msgno s1~msgv1 s1~creator s1~counter
         INTO TABLE ltt_sost
      FROM sost AS s1
        INNER JOIN soes AS s2 ON s2~rectp = s1~rectp
                             AND s2~recyr = s1~recyr
                             AND s2~recno = s1~recno
      FOR ALL ENTRIES IN ltt_sood
          WHERE objtp     EQ ltt_sood-objtp
          AND   objyr     EQ ltt_sood-objyr
          AND   objno     EQ ltt_sood-objno
          AND   counter   EQ ( SELECT MAX( counter ) FROM sost
                                 WHERE objtp EQ ltt_sood-objtp
                                 AND   objyr EQ ltt_sood-objyr
                                 AND   objno EQ ltt_sood-objno ).
  ENDIF.

  MOVE ltt_sost[] TO ltt_sost_hashed.

  CLEAR: ltt_sost.
  SORT ltt_sood BY objdes objtp objyr objno.
  DELETE ADJACENT DUPLICATES FROM ltt_sood COMPARING objdes objtp objyr objno.

  MOVE ltt_sood[] TO ltt_sood_hashed.
  CLEAR: gt_report, gs_report, ltt_sood.

  LOOP AT ltt_invoice INTO DATA(ls_invoice).
    MOVE-CORRESPONDING ls_invoice TO gs_report.

    IF so_erdat-high IS INITIAL.
      gs_report-erdat_to = so_erdat-low.
    ELSE.
      gs_report-erdat_to = so_erdat-high.
    ENDIF.

    READ TABLE ltt_sood_hashed INTO DATA(ls_sood)
         WITH KEY objdes = ls_invoice-tdcovtitle.
    IF sy-subrc EQ 0.
      gs_report-objdes     = ls_sood-objdes.
      gs_report-objtp      = ls_sood-objtp.
      gs_report-objyr      = ls_sood-objyr.
      gs_report-objno      = ls_sood-objno.
      READ TABLE ltt_sost_hashed INTO DATA(gs_sost)
           WITH KEY  objtp = ls_sood-objtp
                     objyr = ls_sood-objyr
                     objno = ls_sood-objno.
      IF sy-subrc EQ 0.
        MOVE-CORRESPONDING gs_sost TO gs_report.
        CASE gs_report-msgty.
          WHEN 'S' OR 'I'.
            gs_report-icon  = icon1.
            gs_report-vstat = |S|.
          WHEN 'W'.
            gs_report-icon  = icon2.
            gs_report-vstat = |W|.
          WHEN 'E'.
            gs_report-icon  = icon3.
            gs_report-vstat = |F|.
        ENDCASE.
        APPEND gs_report TO gt_report.
      ELSE.
        gs_report-icon  = icon3.
        gs_report-vstat = |F|.
        APPEND gs_report TO gt_report.
      ENDIF.
    ELSE.

*{ YC
      READ TABLE lti_nast INTO DATA(les_nast)
        WITH KEY objky = ls_invoice-objky
                 kschl = ls_invoice-kschl.

      IF sy-subrc IS INITIAL AND les_nast-nacha EQ 1.

        gs_report-sndart = les_nacha-ddtext.
        gs_report-rectp  = les_nast-tdreceiver.
        gs_report-snddat = les_nast-datvr.
        gs_report-sndtim = les_nast-uhrvr.

        CLEAR: lti_messag.
        CALL FUNCTION 'WFMC_PROTOCOL_GET'
          EXPORTING
            cps_nast  = les_nast
          TABLES
            messages  = lti_messag
          EXCEPTIONS
            not_found = 1
            OTHERS    = 2.
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.

        IF lti_messag IS NOT INITIAL.

          READ TABLE lti_messag INTO DATA(les_messag)
               INDEX lines( lti_messag ).

          gs_report-msgid = les_messag-arbgb.
          gs_report-msgty = les_messag-msgty.
          gs_report-msgno = les_messag-msgnr.
          gs_report-msgv1 = les_messag-msgv1.

        ENDIF.

        CASE les_nast-vstat.
          WHEN '0'.
            gs_report-icon  = icon2.
            gs_report-vstat = |W|.
          WHEN '1'.
            gs_report-icon  = icon1.
            gs_report-vstat = |S|.
          WHEN '2'.
            gs_report-icon  = icon3.
            gs_report-vstat = |F|.
          WHEN OTHERS.
            gs_report-icon  = icon3.
            gs_report-vstat = |F|.
        ENDCASE.

        APPEND gs_report TO gt_report.

      ELSE.
*}
        gs_report-icon  = icon3.
        gs_report-vstat = |F|.

        APPEND gs_report TO gt_report.
      ENDIF.

    ENDIF.
    CLEAR: gs_report,
           les_nast,
           les_messag.

  ENDLOOP.

ENDFORM.                    " F_GET_DATA
*
**
*&---------------------------------------------------------------------*
*&      Form  F_DISP_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_disp_data .
*..... It's called the ALV
  TRY.
      CALL METHOD cl_salv_table=>factory
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = gt_report.

      PERFORM enable_layout_settings.

    CATCH cx_salv_msg.
      "An error has occurred in ALV
      MESSAGE s899(salv_exception) DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

*.....SORT
  lo_sorts = lo_alv->get_sorts( ).
  TRY.
      lo_sorts->add_sort(
        columnname = 'VBELN'                  "Columna a ordenar
        position   = 1                        "1er criterio de ordenamiento
        sequence   = if_salv_c_sort=>sort_up  "Orden Ascendente
        subtotal   = abap_true ).             "Se utiliza para Subtotales
    CATCH cx_salv_data_error cx_salv_not_found cx_salv_existing .
      "An error has occurred in ALV
      MESSAGE s899(salv_exception) DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

**get ALV columns             Para HOTSPOT
  CALL METHOD lo_alv->get_columns                        "get all columns
    RECEIVING
      value = lo_columns.
  IF lo_columns IS NOT INITIAL.
    TRY.
        lo_column ?= lo_columns->get_column( 'VBELN' ).   "get VBELN columns to insert hotspot
      CATCH cx_salv_not_found.
        "An error has occurred in ALV
        MESSAGE s899(salv_exception) DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.

* Set the HotSpot for VBELN Column
    TRY.
        CALL METHOD lo_column->set_cell_type               "set cell type hotspot
          EXPORTING
            value = if_salv_c_cell_type=>hotspot.
        .
      CATCH cx_salv_data_error .
        "An error has occurred in ALV
        MESSAGE s899(salv_exception) DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.
  ENDIF.
  "END HOTSPOT
******* Event Register settings *******
  lo_events = lo_alv->get_event( ).
  CREATE OBJECT go_events.
  SET HANDLER go_events->on_double_click FOR lo_events.
  SET HANDLER go_events->on_link_click FOR lo_events.

  TRY.
** We optimize the columns of the ALV
      lo_columns = lo_alv->get_columns( ).
      lo_columns->set_optimize( abap_true ).

      lo_column ?= lo_columns->get_column( 'VBELN' ).
      lo_column->set_long_text( text-t01 ).
      lo_column->set_medium_text( text-t01 ).
      lo_column->set_short_text( 'N.Invoice' ).

      lo_column ?= lo_columns->get_column( 'ERDAT_TO' ).
      lo_column->set_long_text( 'Created To' ).
      lo_column->set_medium_text( 'Created To' ).
      lo_column->set_short_text( 'Created To' ).

    CATCH cx_salv_not_found.
      "An error has occurred in ALV
      MESSAGE s899(salv_exception) DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.


** Properties of ALV.
  lo_dset = lo_alv->get_display_settings( ).
  lo_dset->set_striped_pattern( abap_true ).
  lo_alv->get_functions( )->set_all( if_salv_c_bool_sap=>true ).     "ALL standard buttons

  lo_columns = lo_alv->get_columns( ).
* The COLOR column contains the color per cell or row
  lo_columns->set_color_column( 'COLOR' ).

  TRY.
* Set color for a column
      gs_color-col = 5.    "Green
      gs_color-int = 1.
      gs_color-inv = 0.
      lo_column ?= lo_columns->get_column( 'VBELN' ).
      lo_column->set_color( gs_color ).

      gs_color-col = 7.    "orange
      lo_column ?= lo_columns->get_column( 'FKART' ).
      lo_column->set_color( gs_color ).

      gs_color-col = 3.    "Yellow
      lo_column ?= lo_columns->get_column( 'ERDAT' ).
      lo_column->set_color( gs_color ).

      gs_color-col = 1.    "Blue
      lo_column ?= lo_columns->get_column( 'KSCHL' ).
      lo_column->set_color( gs_color ).

    CATCH cx_salv_not_found.
      "An error has occurred in ALV
      MESSAGE s899(salv_exception) DISPLAY LIKE 'E'.
      RETURN.

  ENDTRY.

  TRY.
      lo_column ?= lo_columns->get_column( columnname = 'OBJTP' ).
      lo_column->set_visible( value  = if_salv_c_bool_sap=>false ).

      lo_column ?= lo_columns->get_column( columnname = 'OBJYR' ).
      lo_column->set_visible( value  = if_salv_c_bool_sap=>false ).

      lo_column ?= lo_columns->get_column( columnname = 'MSGID' ).
      lo_column->set_visible( value  = if_salv_c_bool_sap=>false ).

      lo_column ?= lo_columns->get_column( columnname = 'MSGTY' ).
      lo_column->set_visible( value  = if_salv_c_bool_sap=>false ).

      lo_column ?= lo_columns->get_column( columnname = 'MSGNO' ).
      lo_column->set_visible( value  = if_salv_c_bool_sap=>false ).

    CATCH cx_salv_not_found.
  ENDTRY.


  lo_alv->display( ).
ENDFORM.                    " F_DISP_DATA


*&---------------------------------------------------------------------*
*&      Form  ALV_F4
*&---------------------------------------------------------------------*
FORM alv_f4 .
  is_variant-report = sy-repid.

  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      is_variant = is_variant
      i_save     = 'A'
    IMPORTING
      es_variant = is_variant
    EXCEPTIONS
      not_found  = 2.
  IF sy-subrc = 2.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    p_layout = is_variant-variant.
  ENDIF.

ENDFORM.                                                    " ALV_F4
*&---------------------------------------------------------------------*
FORM enable_layout_settings.
*&---------------------------------------------------------------------*
  DATA layout_settings TYPE REF TO cl_salv_layout.
  DATA layout_key      TYPE salv_s_layout_key.

  layout_settings = lo_alv->get_layout( ).

  layout_key-report = sy-repid.
  layout_settings->set_key( layout_key ).

  layout_settings->set_save_restriction( if_salv_c_layout=>restrict_none ).
ENDFORM.                    "enable_layout_settings

*&---------------------------------------------------------------------*
*&      Form
*&---------------------------------------------------------------------*
FORM get_bill_info USING row    TYPE salv_de_row
                         column TYPE salv_de_column.
  IF column EQ 'VBELN'.
    CLEAR : gs_report.
    READ TABLE gt_report INTO DATA(gs_repor) INDEX row.
    IF sy-subrc EQ 0.
      SET PARAMETER ID 'VF'   FIELD gs_repor-vbeln.
      CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDIF.
ENDFORM.                    "get_bill_info
*&---------------------------------------------------------------------*
*&      Form  F_INI_DATA
*&---------------------------------------------------------------------*
FORM f_ini_data .
  REFRESH: gt_parameter, so_vkorg, so_fkart, so_kschl.
  SELECT * FROM zca_parameter_t INTO TABLE gt_parameter
    WHERE zapplication EQ gc_application
    AND   zobjkey      EQ gc_objkey
    AND   zsingle      EQ gc_vkorg.

  so_vkorg[] = VALUE #( FOR gs_parameter IN gt_parameter
              ( sign = gc_inclusive option = gc_equal low = gs_parameter-zrange_low ) ).

  REFRESH gt_parameter.
  SELECT * FROM zca_parameter_t INTO TABLE gt_parameter
    WHERE zapplication EQ gc_application
    AND   zobjkey      EQ gc_objkey
    AND   zsingle      EQ gc_fkart.

  so_fkart[] = VALUE #( FOR gs_parameter IN gt_parameter
              ( sign = gc_inclusive option = gc_equal low = gs_parameter-zrange_low ) ).

  REFRESH gt_parameter.
  SELECT * FROM zca_parameter_t INTO TABLE gt_parameter
    WHERE zapplication EQ gc_application
    AND   zobjkey      EQ gc_objkey
    AND   zsingle      EQ gc_kschl.

  so_kschl[] = VALUE #( FOR gs_parameter IN gt_parameter
              ( sign = gc_inclusive option = gc_equal low = gs_parameter-zrange_low ) ).

  gv_fecha_proc = sy-datum - 1.
  so_erdat[] = VALUE #( sign = gc_inclusive option = gc_equal ( low = gv_fecha_proc ) ).

ENDFORM.                    " F_INI_DATA