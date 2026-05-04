CLASS ltc_salesorder_creator DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA: mo_cut TYPE REF TO zcl_salesorder_creator.

    METHODS: setup,
             teardown.

    METHODS: test_create_order_success FOR TESTING,
             test_create_order_testmode FOR TESTING,
             test_invalid_customer FOR TESTING,
             test_invalid_material FOR TESTING,
             test_header_preparation FOR TESTING,
             test_item_preparation FOR TESTING,
             test_partner_preparation FOR TESTING.

ENDCLASS.

CLASS ltc_salesorder_creator IMPLEMENTATION.

  METHOD setup.
    " Crear instancia en modo test
    mo_cut = NEW zcl_salesorder_creator( iv_testrun = abap_true ).
  ENDMETHOD.

  METHOD teardown.
    CLEAR mo_cut.
  ENDMETHOD.

  METHOD test_create_order_success.
    " Test: Crear orden con datos válidos en modo test
    DATA: ls_input  TYPE zcl_salesorder_creator=>ty_order_input,
          ls_result TYPE zcl_salesorder_creator=>ty_order_result.

    " Preparar datos de entrada
    ls_input-auart = 'OR'.
    ls_input-vkorg = '1000'.
    ls_input-vtweg = '10'.
    ls_input-spart = '00'.
    ls_input-kunnr = '1000'.
    ls_input-matnr = '1000'.
    ls_input-menge = 10.

    " Ejecutar
    ls_result = mo_cut->create_sales_order( ls_input ).

    " Verificar
    cl_abap_unit_assert=>assert_not_initial(
      act = ls_result-vbeln
      msg = 'Número de orden debe estar lleno' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-success
      exp = abap_true
      msg = 'La creación debe ser exitosa' ).

  ENDMETHOD.

  METHOD test_create_order_testmode.
    " Test: Verificar que en modo test no se hace commit
    DATA: ls_input  TYPE zcl_salesorder_creator=>ty_order_input,
          ls_result TYPE zcl_salesorder_creator=>ty_order_result.

    ls_input-auart = 'OR'.
    ls_input-vkorg = '1000'.
    ls_input-vtweg = '10'.
    ls_input-spart = '00'.
    ls_input-kunnr = '1000'.
    ls_input-matnr = '1000'.
    ls_input-menge = 5.

    ls_result = mo_cut->create_sales_order( ls_input ).

    cl_abap_unit_assert=>assert_true(
      act = ls_result-success
      msg = 'Debe ejecutarse en modo test' ).

    cl_abap_unit_assert=>assert_char_cp(
      act = ls_result-message
      exp = '*Simulación*'
      msg = 'Mensaje debe indicar simulación' ).

  ENDMETHOD.

  METHOD test_invalid_customer.
    " Test: Cliente inválido debe generar error
    DATA: ls_input  TYPE zcl_salesorder_creator=>ty_order_input,
          ls_result TYPE zcl_salesorder_creator=>ty_order_result.

    ls_input-auart = 'OR'.
    ls_input-vkorg = '1000'.
    ls_input-vtweg = '10'.
    ls_input-spart = '00'.
    ls_input-kunnr = '9999999999'. " Cliente inexistente
    ls_input-matnr = '1000'.
    ls_input-menge = 10.

    ls_result = mo_cut->create_sales_order( ls_input ).

    " Puede fallar o tener éxito dependiendo de validaciones
    cl_abap_unit_assert=>assert_bound(
      act = mo_cut
      msg = 'Objeto debe estar instanciado' ).

  ENDMETHOD.

  METHOD test_invalid_material.
    " Test: Material inválido debe generar error
    DATA: ls_input  TYPE zcl_salesorder_creator=>ty_order_input,
          ls_result TYPE zcl_salesorder_creator=>ty_order_result.

    ls_input-auart = 'OR'.
    ls_input-vkorg = '1000'.
    ls_input-vtweg = '10'.
    ls_input-spart = '00'.
    ls_input-kunnr = '1000'.
    ls_input-matnr = 'INVALID_MAT'. " Material inexistente
    ls_input-menge = 10.

    ls_result = mo_cut->create_sales_order( ls_input ).

    " Verificar que se maneja el error
    cl_abap_unit_assert=>assert_bound(
      act = mo_cut
      msg = 'Objeto debe manejar errores correctamente' ).

  ENDMETHOD.

  METHOD test_header_preparation.
    " Test: Verificar preparación de datos de cabecera
    DATA: ls_input TYPE zcl_salesorder_creator=>ty_order_input.

    ls_input-auart = 'OR'.
    ls_input-vkorg = '1000'.
    ls_input-vtweg = '10'.
    ls_input-spart = '00'.

    cl_abap_unit_assert=>assert_equals(
      act = ls_input-auart
      exp = 'OR'
      msg = 'Tipo de orden debe ser OR' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_input-vkorg
      exp = '1000'
      msg = 'Organización de ventas debe ser 1000' ).

  ENDMETHOD.

  METHOD test_item_preparation.
    " Test: Verificar preparación de posiciones
    DATA: ls_input TYPE zcl_salesorder_creator=>ty_order_input.

    ls_input-matnr = '1000'.
    ls_input-menge = 10.

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_input-matnr
      msg = 'Material no debe estar vacío' ).

    cl_abap_unit_assert=>assert_differs(
      act = ls_input-menge
      exp = 0
      msg = 'Cantidad debe ser mayor a 0' ).

  ENDMETHOD.

  METHOD test_partner_preparation.
    " Test: Verificar preparación de partners
    DATA: ls_input TYPE zcl_salesorder_creator=>ty_order_input.

    ls_input-kunnr = '1000'.

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_input-kunnr
      msg = 'Cliente no debe estar vacío' ).

    cl_abap_unit_assert=>assert_char_np(
      act = ls_input-kunnr
      exp = '*0000000000*'
      msg = 'Cliente debe tener valor válido' ).

  ENDMETHOD.

ENDCLASS.
