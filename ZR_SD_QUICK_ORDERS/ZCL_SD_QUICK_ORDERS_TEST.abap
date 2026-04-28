*----------------------------------------------------------------------*
* Class ZCL_SD_QUICK_ORDERS_TEST
* ABAP Unit tests para ZCL_SD_QUICK_ORDERS
* Usa test double local (LTD_MOCK_DAO) para aislar del DB
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Test Double local — implementa ZIF_SD_QUICK_ORDERS_DAO
*----------------------------------------------------------------------*
CLASS ltd_mock_dao DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES zif_sd_quick_orders_dao.

    "! Permite inyectar datos de prueba desde el test
    METHODS set_mock_data
      IMPORTING it_data TYPE zif_sd_quick_orders_dao=>ty_output_t.

  PRIVATE SECTION.
    DATA mt_mock_data TYPE zif_sd_quick_orders_dao=>ty_output_t.

ENDCLASS.

CLASS ltd_mock_dao IMPLEMENTATION.

  METHOD zif_sd_quick_orders_dao~get_orders.
    et_data = mt_mock_data.
  ENDMETHOD.

  METHOD set_mock_data.
    mt_mock_data = it_data.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Clase de test principal
*----------------------------------------------------------------------*
CLASS zcl_sd_quick_orders_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut      TYPE REF TO zcl_sd_quick_orders.   "Class Under Test
    DATA mo_mock_dao TYPE REF TO ltd_mock_dao.

    METHODS setup.

    METHODS: get_orders_with_data       FOR TESTING,
             get_orders_empty_result    FOR TESTING,
             has_data_true_after_result FOR TESTING,
             has_data_false_when_empty  FOR TESTING,
             get_orders_count_matches   FOR TESTING,
             get_orders_filters_ignored FOR TESTING.

ENDCLASS.

CLASS zcl_sd_quick_orders_test IMPLEMENTATION.

  METHOD setup.
    " Crear mock DAO e inyectarlo en la clase bajo prueba
    mo_mock_dao = NEW ltd_mock_dao( ).
    mo_cut      = NEW zcl_sd_quick_orders( io_dao = mo_mock_dao ).
  ENDMETHOD.

  METHOD get_orders_with_data.
    " Given: mock con 2 registros
    DATA(lt_mock) = VALUE zif_sd_quick_orders_dao=>ty_output_t(
      ( vbeln = '0000000001' erdat = '20250101' auart = 'ZOR'
        posnr = '000010' matnr = 'MAT001' kwmeng = 10 )
      ( vbeln = '0000000001' erdat = '20250101' auart = 'ZOR'
        posnr = '000020' matnr = 'MAT002' kwmeng = 5 )
    ).
    mo_mock_dao->set_mock_data( lt_mock ).

    " When: consultar pedidos
    DATA: lt_result TYPE zif_sd_quick_orders_dao=>ty_output_t,
          lv_count  TYPE i.

    DATA(lt_erdat) = VALUE zif_sd_quick_orders_dao=>ty_erdat_range(
      ( sign = 'I' option = 'BT' low = '20250101' high = '20251231' )
    ).
    DATA(lt_auart) = VALUE zif_sd_quick_orders_dao=>ty_auart_range(
      ( sign = 'I' option = 'EQ' low = 'ZOR' )
    ).

    mo_cut->get_orders(
      EXPORTING it_erdat = lt_erdat
                it_auart = lt_auart
      IMPORTING et_data  = lt_result
                ev_count = lv_count ).

    " Then: se devuelven los 2 registros
    cl_abap_unit_assert=>assert_equals(
      act = lv_count
      exp = 2
      msg = 'Debe devolver 2 registros' ).

    cl_abap_unit_assert=>assert_not_initial(
      act = lt_result
      msg = 'La tabla resultado no debe estar vacía' ).
  ENDMETHOD.

  METHOD get_orders_empty_result.
    " Given: mock sin datos
    mo_mock_dao->set_mock_data( VALUE zif_sd_quick_orders_dao=>ty_output_t( ) ).

    " When
    DATA: lt_result TYPE zif_sd_quick_orders_dao=>ty_output_t,
          lv_count  TYPE i.

    mo_cut->get_orders(
      EXPORTING it_erdat = VALUE #( ( sign = 'I' option = 'EQ' low = '20250601' ) )
                it_auart = VALUE #( )
      IMPORTING et_data  = lt_result
                ev_count = lv_count ).

    " Then
    cl_abap_unit_assert=>assert_equals(
      act = lv_count
      exp = 0
      msg = 'Debe devolver 0 registros' ).

    cl_abap_unit_assert=>assert_initial(
      act = lt_result
      msg = 'La tabla resultado debe estar vacía' ).
  ENDMETHOD.

  METHOD has_data_true_after_result.
    " Given: mock con datos
    mo_mock_dao->set_mock_data( VALUE zif_sd_quick_orders_dao=>ty_output_t(
      ( vbeln = '0000000099' erdat = '20250315' auart = 'TA' posnr = '000010' )
    ) ).

    " When
    mo_cut->get_orders(
      EXPORTING it_erdat = VALUE #( ( sign = 'I' option = 'EQ' low = '20250315' ) )
                it_auart = VALUE #( )
      IMPORTING et_data  = DATA(lt_result)
                ev_count = DATA(lv_count) ).

    " Then
    cl_abap_unit_assert=>assert_true(
      act = mo_cut->has_data( )
      msg = 'has_data() debe ser TRUE cuando hay resultados' ).
  ENDMETHOD.

  METHOD has_data_false_when_empty.
    " Given: mock vacío
    mo_mock_dao->set_mock_data( VALUE zif_sd_quick_orders_dao=>ty_output_t( ) ).

    " When
    mo_cut->get_orders(
      EXPORTING it_erdat = VALUE #( ( sign = 'I' option = 'EQ' low = '20250101' ) )
                it_auart = VALUE #( )
      IMPORTING et_data  = DATA(lt_result)
                ev_count = DATA(lv_count) ).

    " Then
    cl_abap_unit_assert=>assert_false(
      act = mo_cut->has_data( )
      msg = 'has_data() debe ser FALSE cuando no hay resultados' ).
  ENDMETHOD.

  METHOD get_orders_count_matches.
    " Given: mock con 3 registros
    DATA(lt_mock) = VALUE zif_sd_quick_orders_dao=>ty_output_t(
      ( vbeln = '0000000010' posnr = '000010' matnr = 'MAT-A' )
      ( vbeln = '0000000010' posnr = '000020' matnr = 'MAT-B' )
      ( vbeln = '0000000020' posnr = '000010' matnr = 'MAT-C' )
    ).
    mo_mock_dao->set_mock_data( lt_mock ).

    " When
    DATA: lt_result TYPE zif_sd_quick_orders_dao=>ty_output_t,
          lv_count  TYPE i.

    mo_cut->get_orders(
      EXPORTING it_erdat = VALUE #( ( sign = 'I' option = 'EQ' low = '20250101' ) )
                it_auart = VALUE #( )
      IMPORTING et_data  = lt_result
                ev_count = lv_count ).

    " Then: count debe coincidir con lines( )
    cl_abap_unit_assert=>assert_equals(
      act = lv_count
      exp = lines( lt_result )
      msg = 'ev_count debe coincidir con el número de líneas' ).
  ENDMETHOD.

  METHOD get_orders_filters_ignored.
    " Verifica que el mock devuelve datos sin importar los filtros
    " (el filtrado real lo hace el DAO, no la clase de negocio)
    DATA(lt_mock) = VALUE zif_sd_quick_orders_dao=>ty_output_t(
      ( vbeln = '0000000050' auart = 'ZOR' posnr = '000010' )
    ).
    mo_mock_dao->set_mock_data( lt_mock ).

    " When: filtro con tipo de pedido diferente al mock
    DATA: lt_result TYPE zif_sd_quick_orders_dao=>ty_output_t,
          lv_count  TYPE i.

    mo_cut->get_orders(
      EXPORTING it_erdat = VALUE #( ( sign = 'I' option = 'EQ' low = '20250101' ) )
                it_auart = VALUE #( ( sign = 'I' option = 'EQ' low = 'TA' ) )
      IMPORTING et_data  = lt_result
                ev_count = lv_count ).

    " Then: el mock devuelve todo (confirma que la clase delega al DAO)
    cl_abap_unit_assert=>assert_equals(
      act = lv_count
      exp = 1
      msg = 'La clase debe delegar el filtrado al DAO' ).
  ENDMETHOD.

ENDCLASS.
