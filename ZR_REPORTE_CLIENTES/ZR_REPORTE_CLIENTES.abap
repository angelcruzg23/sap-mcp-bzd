*&---------------------------------------------------------------------*
*& Report ZR_REPORTE_CLIENTES
*&---------------------------------------------------------------------*
*& Reporte ALV de datos maestros de clientes (KNA1)
*& Muestra los 10 campos principales filtrado por código de cliente.
*&---------------------------------------------------------------------*
REPORT zr_reporte_clientes.

*----------------------------------------------------------------------*
* Pantalla de selección
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS: s_kunnr FOR kna1-kunnr.  "Código de cliente
SELECTION-SCREEN END OF BLOCK b01.

*----------------------------------------------------------------------*
* Tipos
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_cliente,
         kunnr TYPE kna1-kunnr,   "Número de cliente
         land1 TYPE kna1-land1,   "País
         name1 TYPE kna1-name1,   "Nombre 1
         name2 TYPE kna1-name2,   "Nombre 2
         ort01 TYPE kna1-ort01,   "Ciudad
         pstlz TYPE kna1-pstlz,   "Código postal
         regio TYPE kna1-regio,   "Región
         sortl TYPE kna1-sortl,   "Término de búsqueda
         stras TYPE kna1-stras,   "Calle
         telf1 TYPE kna1-telf1,   "Teléfono
       END OF ty_cliente.

*----------------------------------------------------------------------*
* Variables
*----------------------------------------------------------------------*
DATA: lt_clientes TYPE TABLE OF ty_cliente,
      lo_alv      TYPE REF TO cl_salv_table,
      lo_columns  TYPE REF TO cl_salv_columns_table,
      lo_column   TYPE REF TO cl_salv_column,
      lo_funcs    TYPE REF TO cl_salv_functions_list,
      lo_display  TYPE REF TO cl_salv_display_settings,
      lx_msg      TYPE REF TO cx_salv_msg,
      lx_not_found TYPE REF TO cx_salv_not_found.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

  " Selección de datos
  SELECT kunnr land1 name1 name2 ort01
         pstlz regio sortl stras telf1
    FROM kna1
    INTO TABLE lt_clientes
    WHERE kunnr IN @s_kunnr.

  IF lt_clientes IS INITIAL.
    MESSAGE 'No se encontraron clientes con los filtros indicados' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " Construcción del ALV con CL_SALV_TABLE
  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_alv
        CHANGING  t_table      = lt_clientes ).

      " Habilitar funciones estándar (filtro, ordenar, exportar, etc.)
      lo_funcs = lo_alv->get_functions( ).
      lo_funcs->set_all( abap_true ).

      " Configuración de display
      lo_display = lo_alv->get_display_settings( ).
      lo_display->set_striped_pattern( abap_true ).
      lo_display->set_list_header( 'Reporte de Clientes - KNA1' ).

      " Títulos de columnas
      lo_columns = lo_alv->get_columns( ).
      lo_columns->set_optimize( abap_true ).

      lo_column = lo_columns->get_column( 'KUNNR' ).
      lo_column->set_short_text( 'Cliente' ).
      lo_column->set_medium_text( 'Nro Cliente' ).
      lo_column->set_long_text( 'Número de Cliente' ).

      lo_column = lo_columns->get_column( 'LAND1' ).
      lo_column->set_short_text( 'País' ).

      lo_column = lo_columns->get_column( 'NAME1' ).
      lo_column->set_short_text( 'Nombre 1' ).

      lo_column = lo_columns->get_column( 'NAME2' ).
      lo_column->set_short_text( 'Nombre 2' ).

      lo_column = lo_columns->get_column( 'ORT01' ).
      lo_column->set_short_text( 'Ciudad' ).

      lo_column = lo_columns->get_column( 'PSTLZ' ).
      lo_column->set_short_text( 'Cód.Post.' ).

      lo_column = lo_columns->get_column( 'REGIO' ).
      lo_column->set_short_text( 'Región' ).

      lo_column = lo_columns->get_column( 'SORTL' ).
      lo_column->set_short_text( 'Búsqueda' ).

      lo_column = lo_columns->get_column( 'STRAS' ).
      lo_column->set_short_text( 'Calle' ).

      lo_column = lo_columns->get_column( 'TELF1' ).
      lo_column->set_short_text( 'Teléfono' ).

      lo_alv->display( ).

    CATCH cx_salv_msg INTO lx_msg.
      MESSAGE lx_msg->get_text( ) TYPE 'E'.
    CATCH cx_salv_not_found INTO lx_not_found.
      MESSAGE lx_not_found->get_text( ) TYPE 'E'.
  ENDTRY.