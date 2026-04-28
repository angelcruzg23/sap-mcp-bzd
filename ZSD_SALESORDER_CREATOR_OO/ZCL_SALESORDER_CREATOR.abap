CLASS zcl_salesorder_creator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_order_input,
             auart TYPE vbak-auart,
             vkorg TYPE vbak-vkorg,
             vtweg TYPE vbak-vtweg,
             spart TYPE vbak-spart,
             kunnr TYPE kna1-kunnr,
             matnr TYPE mara-matnr,
             menge TYPE bapisditmx-target_qty,
           END OF ty_order_input.

    TYPES: BEGIN OF ty_order_result,
             vbeln   TYPE vbak-vbeln,
             success TYPE abap_bool,
             message TYPE string,
           END OF ty_order_result.

    METHODS constructor
      IMPORTING
        iv_testrun TYPE abap_bool DEFAULT abap_false.

    METHODS create_sales_order
      IMPORTING
        is_input        TYPE ty_order_input
      RETURNING
        VALUE(rs_result) TYPE ty_order_result.

  PROTECTED SECTION.

  PRIVATE SECTION.
    DATA: mv_testrun TYPE abap_bool.

    METHODS prepare_header_data
      IMPORTING
        is_input              TYPE ty_order_input
      EXPORTING
        es_order_header_in    TYPE bapisdhd1
        es_order_header_inx   TYPE bapisdhd1x.

    METHODS prepare_item_data
      IMPORTING
        is_input             TYPE ty_order_input
      EXPORTING
        et_order_items_in    TYPE TABLE
        et_order_items_inx   TYPE TABLE.

    METHODS prepare_partner_data
      IMPORTING
        iv_kunnr          TYPE kna1-kunnr
      EXPORTING
        et_order_partners TYPE TABLE.

    METHODS prepare_schedule_data
      IMPORTING
        iv_menge              TYPE bapisditmx-target_qty
      EXPORTING
        et_order_schedules_in  TYPE TABLE
        et_order_schedules_inx TYPE TABLE.

    METHODS call_bapi
      IMPORTING
        is_order_header_in     TYPE bapisdhd1
        is_order_header_inx    TYPE bapisdhd1x
        it_order_items_in      TYPE TABLE
        it_order_items_inx     TYPE TABLE
        it_order_partners      TYPE TABLE
        it_order_schedules_in  TYPE TABLE
        it_order_schedules_inx TYPE TABLE
      EXPORTING
        ev_vbeln               TYPE vbak-vbeln
        et_return              TYPE bapiret2_t.

    METHODS process_return_messages
      IMPORTING
        it_return       TYPE bapiret2_t
      RETURNING
        VALUE(rv_success) TYPE abap_bool.

    METHODS commit_work.

    METHODS rollback_work.

ENDCLASS.

CLASS zcl_salesorder_creator IMPLEMENTATION.

  METHOD constructor.
    mv_testrun = iv_testrun.
  ENDMETHOD.

  METHOD create_sales_order.
    DATA: ls_order_header_in    TYPE bapisdhd1,
          ls_order_header_inx   TYPE bapisdhd1x,
          lt_order_items_in     TYPE TABLE OF bapisditm,
          lt_order_items_inx    TYPE TABLE OF bapisditmx,
          lt_order_partners     TYPE TABLE OF bapiparnr,
          lt_order_schedules_in TYPE TABLE OF bapischdl,
          lt_order_schedules_inx TYPE TABLE OF bapischdlx,
          lt_return             TYPE bapiret2_t,
          lv_vbeln              TYPE vbak-vbeln.

    " Preparar datos
    prepare_header_data(
      EXPORTING is_input = is_input
      IMPORTING es_order_header_in = ls_order_header_in
                es_order_header_inx = ls_order_header_inx ).

    prepare_item_data(
      EXPORTING is_input = is_input
      IMPORTING et_order_items_in = lt_order_items_in
                et_order_items_inx = lt_order_items_inx ).

    prepare_partner_data(
      EXPORTING iv_kunnr = is_input-kunnr
      IMPORTING et_order_partners = lt_order_partners ).

    prepare_schedule_data(
      EXPORTING iv_menge = is_input-menge
      IMPORTING et_order_schedules_in = lt_order_schedules_in
                et_order_schedules_inx = lt_order_schedules_inx ).

    " Llamar BAPI
    call_bapi(
      EXPORTING
        is_order_header_in = ls_order_header_in
        is_order_header_inx = ls_order_header_inx
        it_order_items_in = lt_order_items_in
        it_order_items_inx = lt_order_items_inx
        it_order_partners = lt_order_partners
        it_order_schedules_in = lt_order_schedules_in
        it_order_schedules_inx = lt_order_schedules_inx
      IMPORTING
        ev_vbeln = lv_vbeln
        et_return = lt_return ).

    " Procesar resultado
    rs_result-vbeln = lv_vbeln.
    rs_result-success = process_return_messages( lt_return ).

    IF rs_result-success = abap_true.
      IF mv_testrun = abap_false.
        commit_work( ).
        rs_result-message = |Orden { lv_vbeln } creada exitosamente|.
      ELSE.
        rs_result-message = |Simulación exitosa - Orden: { lv_vbeln }|.
      ENDIF.
    ELSE.
      rollback_work( ).
      rs_result-message = 'Error al crear la orden de venta'.
    ENDIF.

  ENDMETHOD.

  METHOD prepare_header_data.
    es_order_header_in-doc_type   = is_input-auart.
    es_order_header_in-sales_org  = is_input-vkorg.
    es_order_header_in-distr_chan = is_input-vtweg.
    es_order_header_in-division   = is_input-spart.
    es_order_header_in-purch_no_c = 'POC-OO-001'.

    es_order_header_inx-doc_type   = abap_true.
    es_order_header_inx-sales_org  = abap_true.
    es_order_header_inx-distr_chan = abap_true.
    es_order_header_inx-division   = abap_true.
    es_order_header_inx-purch_no_c = abap_true.
    es_order_header_inx-updateflag = 'I'.
  ENDMETHOD.

  METHOD prepare_item_data.
    DATA: ls_order_items_in  TYPE bapisditm,
          ls_order_items_inx TYPE bapisditmx.

    ls_order_items_in-itm_number = '000010'.
    ls_order_items_in-material   = is_input-matnr.
    ls_order_items_in-target_qty = is_input-menge.
    APPEND ls_order_items_in TO et_order_items_in.

    ls_order_items_inx-itm_number = '000010'.
    ls_order_items_inx-material   = abap_true.
    ls_order_items_inx-target_qty = abap_true.
    ls_order_items_inx-updateflag = 'I'.
    APPEND ls_order_items_inx TO et_order_items_inx.
  ENDMETHOD.

  METHOD prepare_partner_data.
    DATA: ls_partner TYPE bapiparnr.

    " Solicitante (AG)
    ls_partner-partn_role = 'AG'.
    ls_partner-partn_numb = iv_kunnr.
    APPEND ls_partner TO et_order_partners.

    " Destinatario (WE)
    CLEAR ls_partner.
    ls_partner-partn_role = 'WE'.
    ls_partner-partn_numb = iv_kunnr.
    APPEND ls_partner TO et_order_partners.

    " Responsable de pago (RE)
    CLEAR ls_partner.
    ls_partner-partn_role = 'RE'.
    ls_partner-partn_numb = iv_kunnr.
    APPEND ls_partner TO et_order_partners.

    " Pagador (RG)
    CLEAR ls_partner.
    ls_partner-partn_role = 'RG'.
    ls_partner-partn_numb = iv_kunnr.
    APPEND ls_partner TO et_order_partners.
  ENDMETHOD.

  METHOD prepare_schedule_data.
    DATA: ls_schedule_in  TYPE bapischdl,
          ls_schedule_inx TYPE bapischdlx.

    ls_schedule_in-itm_number = '000010'.
    ls_schedule_in-sched_line = '0001'.
    ls_schedule_in-req_qty    = iv_menge.
    APPEND ls_schedule_in TO et_order_schedules_in.

    ls_schedule_inx-itm_number = '000010'.
    ls_schedule_inx-sched_line = '0001'.
    ls_schedule_inx-req_qty    = abap_true.
    ls_schedule_inx-updateflag = 'I'.
    APPEND ls_schedule_inx TO et_order_schedules_inx.
  ENDMETHOD.

  METHOD call_bapi.
    CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
      EXPORTING
        order_header_in      = is_order_header_in
        order_header_inx     = is_order_header_inx
        testrun              = mv_testrun
      IMPORTING
        salesdocument        = ev_vbeln
      TABLES
        return               = et_return
        order_items_in       = it_order_items_in
        order_items_inx      = it_order_items_inx
        order_partners       = it_order_partners
        order_schedules_in   = it_order_schedules_in
        order_schedules_inx  = it_order_schedules_inx.
  ENDMETHOD.

  METHOD process_return_messages.
    DATA: ls_return TYPE bapiret2.

    rv_success = abap_true.

    LOOP AT it_return INTO ls_return.
      IF ls_return-type = 'E' OR ls_return-type = 'A'.
        rv_success = abap_false.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD commit_work.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

  METHOD rollback_work.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ENDMETHOD.

ENDCLASS.
