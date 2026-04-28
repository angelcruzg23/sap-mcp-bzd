*&---------------------------------------------------------------------*
*& Report ZR_SD_QUICK_ORDERS
*&---------------------------------------------------------------------*
*& Consulta rápida de pedidos de venta (VBAK + VBAP)
*& Filtro por fecha de creación y tipo de pedido
*& Usa ZCL_SD_QUICK_ORDERS con inyección de dependencias (testeable)
*&---------------------------------------------------------------------*
REPORT zr_sd_quick_orders.

*----------------------------------------------------------------------*
* Pantalla de selección
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS: s_erdat FOR sy-datum OBLIGATORY,  "Fecha de creación
                  s_auart FOR vbak-auart.            "Tipo de pedido
SELECTION-SCREEN END OF BLOCK b01.

*----------------------------------------------------------------------*
* Variables
*----------------------------------------------------------------------*
DATA: go_service TYPE REF TO zcl_sd_quick_orders,
      gt_output  TYPE zif_sd_quick_orders_dao=>ty_output_t,
      gv_count   TYPE i,
      go_alv     TYPE REF TO cl_salv_table.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

  go_service = NEW zcl_sd_quick_orders( ).

  go_service->get_orders(
    EXPORTING it_erdat = s_erdat[]
              it_auart = s_auart[]
    IMPORTING et_data  = gt_output
              ev_count = gv_count ).

  IF go_service->has_data( ) = abap_false.
    MESSAGE s001(00) WITH 'No se encontraron pedidos para la selección'.
    RETURN.
  ENDIF.

  PERFORM display_alv.

*&---------------------------------------------------------------------*
*& Form DISPLAY_ALV
*&---------------------------------------------------------------------*
FORM display_alv.

  DATA: lo_columns TYPE REF TO cl_salv_columns_table,
        lo_display TYPE REF TO cl_salv_display_settings,
        lo_funcs   TYPE REF TO cl_salv_functions_list.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = go_alv
        CHANGING  t_table      = gt_output ).

      lo_funcs = go_alv->get_functions( ).
      lo_funcs->set_all( abap_true ).

      lo_display = go_alv->get_display_settings( ).
      lo_display->set_striped_pattern( abap_true ).
      lo_display->set_list_header( 'Consulta rápida de pedidos de venta' ).

      lo_columns = go_alv->get_columns( ).
      lo_columns->set_optimize( abap_true ).

      PERFORM set_column_text USING lo_columns 'VBELN'   'Pedido'.
      PERFORM set_column_text USING lo_columns 'ERDAT'   'Fecha creación'.
      PERFORM set_column_text USING lo_columns 'ERZET'   'Hora creación'.
      PERFORM set_column_text USING lo_columns 'ERNAM'   'Creado por'.
      PERFORM set_column_text USING lo_columns 'AUART'   'Tipo pedido'.
      PERFORM set_column_text USING lo_columns 'VKORG'   'Org. ventas'.
      PERFORM set_column_text USING lo_columns 'VTWEG'   'Canal dist.'.
      PERFORM set_column_text USING lo_columns 'SPART'   'Sector'.
      PERFORM set_column_text USING lo_columns 'KUNNR'   'Solicitante'.
      PERFORM set_column_text USING lo_columns 'NETWR'   'Valor neto cab.'.
      PERFORM set_column_text USING lo_columns 'POSNR'   'Posición'.
      PERFORM set_column_text USING lo_columns 'MATNR'   'Material'.
      PERFORM set_column_text USING lo_columns 'ARKTX'   'Descripción mat.'.
      PERFORM set_column_text USING lo_columns 'KWMENG'  'Cantidad'.
      PERFORM set_column_text USING lo_columns 'VRKME'   'UM venta'.
      PERFORM set_column_text USING lo_columns 'NETWR_P' 'Valor neto pos.'.
      PERFORM set_column_text USING lo_columns 'WERKS'   'Centro'.
      PERFORM set_column_text USING lo_columns 'LGORT'   'Almacén'.
      PERFORM set_column_text USING lo_columns 'PSTYV'   'Tipo posición'.
      PERFORM set_column_text USING lo_columns 'ABGRU'   'Motivo rechazo'.

      go_alv->display( ).

    CATCH cx_salv_msg cx_salv_not_found INTO DATA(lx_error).
      MESSAGE lx_error->get_text( ) TYPE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_COLUMN_TEXT
*&---------------------------------------------------------------------*
FORM set_column_text USING io_columns TYPE REF TO cl_salv_columns_table
                           iv_field   TYPE lvc_fname
                           iv_text    TYPE string.

  DATA: lo_column TYPE REF TO cl_salv_column.

  TRY.
      lo_column = io_columns->get_column( iv_field ).
      lo_column->set_medium_text( CONV #( iv_text ) ).
      lo_column->set_long_text( CONV #( iv_text ) ).
    CATCH cx_salv_not_found.
  ENDTRY.

ENDFORM.
