*&---------------------------------------------------------------------*
*& Report ZR_SD_DEMO_KIRO
*&---------------------------------------------------------------------*
*& Muestra las últimas 20 cotizaciones filtradas por clase de documento
*& Creado como demo de Kiro + SAP MCP
*&---------------------------------------------------------------------*
REPORT zr_sd_demo_kiro.

PARAMETERS:     p_erdat TYPE erdat DEFAULT sy-datum.
SELECT-OPTIONS: s_auart FOR vbak-auart DEFAULT 'ZQT2'.

START-OF-SELECTION.

  DATA lt_docs TYPE TABLE OF vbak.

  SELECT vbeln auart ernam erdat netwr waerk
    FROM vbak
    INTO CORRESPONDING FIELDS OF TABLE lt_docs
    UP TO 20 ROWS
    WHERE auart IN s_auart
      AND erdat <= p_erdat
    ORDER BY erdat DESCENDING vbeln DESCENDING.

  IF lt_docs IS INITIAL.
    MESSAGE 'No se encontraron documentos con los filtros indicados' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  TRY.
      DATA lo_salv TYPE REF TO cl_salv_table.

      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_salv
        CHANGING  t_table      = lt_docs ).

      DATA(lo_columns) = lo_salv->get_columns( ).
      lo_columns->set_optimize( abap_true ).

      " Ocultar campos que no necesitamos
      DATA(lo_col) = lo_columns->get_column( 'MANDT' ).
      lo_col->set_visible( abap_false ).

      lo_salv->get_display_settings( )->set_list_header(
        |Documentos de venta hasta { p_erdat DATE = USER }| ).

      lo_salv->display( ).

    CATCH cx_salv_msg cx_salv_not_found INTO DATA(lx_error).
      MESSAGE lx_error->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.
