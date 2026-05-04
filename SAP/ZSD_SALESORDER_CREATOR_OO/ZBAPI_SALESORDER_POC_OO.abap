*&---------------------------------------------------------------------*
*& Report ZBAPI_SALESORDER_POC_OO
*&---------------------------------------------------------------------*
*& PoC OO: Creación de Orden de Venta usando BAPI_SALESORDER_CREATEFROMDAT2
*& Versión Orientada a Objetos con ABAP Unit Tests
*&---------------------------------------------------------------------*
REPORT zbapi_salesorder_poc_oo.

*----------------------------------------------------------------------*
* Data Declarations
*----------------------------------------------------------------------*
DATA: go_creator TYPE REF TO zcl_salesorder_creator,
      gs_input   TYPE zcl_salesorder_creator=>ty_order_input,
      gs_result  TYPE zcl_salesorder_creator=>ty_order_result,
      t001       TYPE string VALUE 'Datos de Cabecera',
      t002       TYPE string VALUE 'Datos de Posición'.

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

PARAMETERS: p_test TYPE abap_bool AS CHECKBOX DEFAULT abap_true. "Test mode

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.

  TRY.
      " Crear instancia del creador de órdenes
      go_creator = NEW zcl_salesorder_creator( iv_testrun = p_test ).

      " Preparar datos de entrada
      gs_input-auart = p_auart.
      gs_input-vkorg = p_vkorg.
      gs_input-vtweg = p_vtweg.
      gs_input-spart = p_spart.
      gs_input-kunnr = p_kunnr.
      gs_input-matnr = p_matnr.
      gs_input-menge = p_menge.

      " Crear orden de venta
      gs_result = go_creator->create_sales_order( gs_input ).

      " Mostrar resultado
      IF gs_result-success = abap_true.
        WRITE: / icon_led_green AS ICON, gs_result-message.
        WRITE: / 'Número de orden:', gs_result-vbeln.
      ELSE.
        WRITE: / icon_led_red AS ICON, gs_result-message.
      ENDIF.

    CATCH cx_root INTO DATA(lx_error).
      WRITE: / icon_led_red AS ICON, 'Error:', lx_error->get_text( ).
  ENDTRY.

*----------------------------------------------------------------------*
* End of Selection
*----------------------------------------------------------------------*
END-OF-SELECTION.

  ULINE.
  IF p_test = abap_true.
    WRITE: / 'Modo: SIMULACIÓN (Test)'.
  ELSE.
    WRITE: / 'Modo: PRODUCTIVO'.
  ENDIF.
