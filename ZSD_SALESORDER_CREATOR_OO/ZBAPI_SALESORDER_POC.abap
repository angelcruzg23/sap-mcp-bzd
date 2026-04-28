*&---------------------------------------------------------------------*
*& Report ZBAPI_SALESORDER_POC
*&---------------------------------------------------------------------*
*& PoC: Creación de Orden de Venta usando BAPI_SALESORDER_CREATEFROMDAT2
*&---------------------------------------------------------------------*
REPORT zbapi_salesorder_poc.

*----------------------------------------------------------------------*
* Data Declarations
*----------------------------------------------------------------------*
DATA: lv_vbeln TYPE vbak-vbeln,
      t001     TYPE string VALUE 'Datos de Cabecera',
      t002     TYPE string VALUE 'Datos de Posición'.

* BAPI Structures
DATA: ls_order_header_in    TYPE bapisdhd1,
      ls_order_header_inx   TYPE bapisdhd1x,
      lt_order_items_in     TYPE TABLE OF bapisditm,
      ls_order_items_in     TYPE bapisditm,
      lt_order_items_inx    TYPE TABLE OF bapisditmx,
      ls_order_items_inx    TYPE bapisditmx,
      lt_order_partners     TYPE TABLE OF bapiparnr,
      ls_order_partners     TYPE bapiparnr,
      lt_order_schedules_in TYPE TABLE OF bapischdl,
      ls_order_schedules_in TYPE bapischdl,
      lt_order_schedules_inx TYPE TABLE OF bapischdlx,
      ls_order_schedules_inx TYPE bapischdlx,
      lt_return             TYPE TABLE OF bapiret2,
      ls_return             TYPE bapiret2.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE t001.
PARAMETERS: p_auart TYPE vbak-auart DEFAULT 'OR' OBLIGATORY,    "Tipo de orden
            p_vkorg TYPE vbak-vkorg DEFAULT '1000' OBLIGATORY,  "Org. ventas
            p_vtweg TYPE vbak-vtweg DEFAULT '10' OBLIGATORY,    "Canal
            p_spart TYPE vbak-spart DEFAULT '00' OBLIGATORY,    "Sector
            p_kunnr TYPE kna1-kunnr DEFAULT '1000' OBLIGATORY.  "Cliente
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE t002.
PARAMETERS: p_matnr TYPE mara-matnr DEFAULT '1000' OBLIGATORY,  "Material
            p_menge TYPE bapisditmx-target_qty DEFAULT '10' OBLIGATORY. "Cantidad
SELECTION-SCREEN END OF BLOCK b2.

PARAMETERS: p_test TYPE c AS CHECKBOX DEFAULT 'X'.              "Test mode

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM create_sales_order.

*----------------------------------------------------------------------*
* End of Selection
*----------------------------------------------------------------------*
END-OF-SELECTION.

  IF lv_vbeln IS NOT INITIAL.
    WRITE: / 'Orden de venta creada exitosamente:', lv_vbeln.
  ELSE.
    WRITE: / 'No se pudo crear la orden de venta.'.
  ENDIF.

*&---------------------------------------------------------------------*
*& Form create_sales_order
*&---------------------------------------------------------------------*
FORM create_sales_order.

  " 1. Preparar datos de cabecera
  PERFORM prepare_header_data.

  " 2. Preparar datos de posiciones
  PERFORM prepare_item_data.

  " 3. Preparar partners (cliente)
  PERFORM prepare_partner_data.

  " 4. Preparar datos de reparto
  PERFORM prepare_schedule_data.

  " 5. Llamar a la BAPI
  PERFORM call_bapi.

  " 6. Procesar resultados
  PERFORM process_results.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form prepare_header_data
*&---------------------------------------------------------------------*
FORM prepare_header_data.

  " Datos de cabecera
  ls_order_header_in-doc_type   = p_auart.
  ls_order_header_in-sales_org  = p_vkorg.
  ls_order_header_in-distr_chan = p_vtweg.
  ls_order_header_in-division   = p_spart.
  ls_order_header_in-purch_no_c = 'POC-TEST-001'.

  " Indicadores de actualización
  ls_order_header_inx-doc_type   = 'X'.
  ls_order_header_inx-sales_org  = 'X'.
  ls_order_header_inx-distr_chan = 'X'.
  ls_order_header_inx-division   = 'X'.
  ls_order_header_inx-purch_no_c = 'X'.
  ls_order_header_inx-updateflag = 'I'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form prepare_item_data
*&---------------------------------------------------------------------*
FORM prepare_item_data.

  " Posición 10
  ls_order_items_in-itm_number = '000010'.
  ls_order_items_in-material   = p_matnr.
  ls_order_items_in-target_qty = p_menge.
  APPEND ls_order_items_in TO lt_order_items_in.

  " Indicadores de actualización para posición
  ls_order_items_inx-itm_number = '000010'.
  ls_order_items_inx-material   = 'X'.
  ls_order_items_inx-target_qty = 'X'.
  ls_order_items_inx-updateflag = 'I'.
  APPEND ls_order_items_inx TO lt_order_items_inx.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form prepare_partner_data
*&---------------------------------------------------------------------*
FORM prepare_partner_data.

  " Solicitante (AG - Sold-to party)
  CLEAR ls_order_partners.
  ls_order_partners-partn_role = 'AG'.
  ls_order_partners-partn_numb = p_kunnr.
  APPEND ls_order_partners TO lt_order_partners.

  " Destinatario mercancías (WE - Ship-to party)
  CLEAR ls_order_partners.
  ls_order_partners-partn_role = 'WE'.
  ls_order_partners-partn_numb = p_kunnr.
  APPEND ls_order_partners TO lt_order_partners.

  " Responsable de pago (RE - Bill-to party)
  CLEAR ls_order_partners.
  ls_order_partners-partn_role = 'RE'.
  ls_order_partners-partn_numb = p_kunnr.
  APPEND ls_order_partners TO lt_order_partners.

  " Pagador (RG - Payer)
  CLEAR ls_order_partners.
  ls_order_partners-partn_role = 'RG'.
  ls_order_partners-partn_numb = p_kunnr.
  APPEND ls_order_partners TO lt_order_partners.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form prepare_schedule_data
*&---------------------------------------------------------------------*
FORM prepare_schedule_data.

  " Reparto para la posición 10
  ls_order_schedules_in-itm_number = '000010'.
  ls_order_schedules_in-sched_line = '0001'.
  ls_order_schedules_in-req_qty    = p_menge.
  APPEND ls_order_schedules_in TO lt_order_schedules_in.

  " Indicadores de actualización para reparto
  ls_order_schedules_inx-itm_number = '000010'.
  ls_order_schedules_inx-sched_line = '0001'.
  ls_order_schedules_inx-req_qty    = 'X'.
  ls_order_schedules_inx-updateflag = 'I'.
  APPEND ls_order_schedules_inx TO lt_order_schedules_inx.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form call_bapi
*&---------------------------------------------------------------------*
FORM call_bapi.

  WRITE: / 'Llamando a BAPI_SALESORDER_CREATEFROMDAT2...'.
  ULINE.

  CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
    EXPORTING
      order_header_in      = ls_order_header_in
      order_header_inx     = ls_order_header_inx
      testrun              = p_test
    IMPORTING
      salesdocument        = lv_vbeln
    TABLES
      return               = lt_return
      order_items_in       = lt_order_items_in
      order_items_inx      = lt_order_items_inx
      order_partners       = lt_order_partners
      order_schedules_in   = lt_order_schedules_in
      order_schedules_inx  = lt_order_schedules_inx.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form process_results
*&---------------------------------------------------------------------*
FORM process_results.

  DATA: lv_error TYPE c.

  " Mostrar mensajes de retorno
  WRITE: / 'Mensajes de retorno:'.
  ULINE.

  LOOP AT lt_return INTO ls_return.
    WRITE: / ls_return-type, ls_return-id, ls_return-number, ls_return-message.
    IF ls_return-type = 'E' OR ls_return-type = 'A'.
      lv_error = 'X'.
    ENDIF.
  ENDLOOP.

  " Si no hay errores y no es test, hacer commit
  IF lv_error IS INITIAL AND p_test IS INITIAL.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
    WRITE: / 'COMMIT realizado.'.
  ELSEIF p_test = 'X'.
    WRITE: / 'Modo TEST - No se realizó COMMIT.'.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    WRITE: / 'ROLLBACK realizado debido a errores.'.
  ENDIF.

ENDFORM.
