*----------------------------------------------------------------------*
* Clase de prueba: ZCL_SD_STOCK_QUERY_TEST
* Descripción: Tests unitarios para ZCL_SD_STOCK_QUERY (orquestador).
*              Usa test doubles locales para ZIF_SD_STOCK_DAO y
*              ZIF_SD_EXCLUSION_CHECKER.
* Paquete: ZDEV_SD
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Test Double: DAO
*----------------------------------------------------------------------*
CLASS lcl_dao_double DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sd_stock_dao.
    DATA mt_stock_to_return  TYPE zty_sd_plant_stock_t.
    DATA mv_material_exists  TYPE abap_bool VALUE abap_true.
    DATA mv_company_exists   TYPE abap_bool VALUE abap_true.
    DATA mv_desc_to_return   TYPE makt-maktx VALUE 'S20 WATERBLOCK (25 CARTRIDGES)'.
    DATA mt_plants_to_return TYPE zif_sd_stock_dao=>tty_werks_range.
ENDCLASS.

CLASS lcl_dao_double IMPLEMENTATION.
  METHOD zif_sd_stock_dao~validate_material.
    rv_exists = mv_material_exists.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~validate_company.
    rv_exists = mv_company_exists.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~get_plants_for_company.
    rt_plants = mt_plants_to_return.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~get_material_stock.
    rt_stock = mt_stock_to_return.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~get_material_description.
    rv_desc = mv_desc_to_return.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Test Double: Exclusion Checker
*----------------------------------------------------------------------*
CLASS lcl_exclusion_double DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sd_exclusion_checker.
    DATA mt_result_to_return TYPE zty_sd_plant_stock_t.
    DATA mv_pass_through     TYPE abap_bool VALUE abap_true.
ENDCLASS.

CLASS lcl_exclusion_double IMPLEMENTATION.
  METHOD zif_sd_exclusion_checker~check_exclusions.
    IF mv_pass_through = abap_true.
      " Retorna la entrada sin modificar (sin exclusiones)
      rt_result = it_plant_stock.
    ELSE.
      " Retorna resultado pre-configurado
      rt_result = mt_result_to_return.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Clase de prueba principal
*----------------------------------------------------------------------*
CLASS zcl_sd_stock_query_test DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut       TYPE REF TO zcl_sd_stock_query.
    DATA mo_dao       TYPE REF TO lcl_dao_double.
    DATA mo_exclusion TYPE REF TO lcl_exclusion_double.

    METHODS setup.

    METHODS test_valid_material_and_company FOR TESTING.
    METHODS test_empty_matnr               FOR TESTING.
    METHODS test_empty_bukrs               FOR TESTING.
    METHODS test_material_not_found        FOR TESTING.
    METHODS test_company_not_found         FOR TESTING.
    METHODS test_no_stock_found            FOR TESTING.
    METHODS test_excluded_plant_flagged    FOR TESTING.
    METHODS test_non_excluded_plant        FOR TESTING.
    METHODS test_matnr_desc_populated      FOR TESTING.
ENDCLASS.

CLASS zcl_sd_stock_query_test IMPLEMENTATION.

  METHOD setup.
    mo_dao       = NEW lcl_dao_double( ).
    mo_exclusion = NEW lcl_exclusion_double( ).

    " Configurar datos por defecto del DAO
    mo_dao->mt_plants_to_return = VALUE #(
      ( sign = 'I' option = 'EQ' low = '1020' )
      ( sign = 'I' option = 'EQ' low = '1053' ) ).

    mo_dao->mt_stock_to_return = VALUE #(
      ( werks = '1020' name1 = 'Prescott Production'
        labst = 921000 einme = 0 speme = 0 eisbe = 320000 )
      ( werks = '1053' name1 = 'Salt Lake City Production'
        labst = 575000 einme = 0 speme = 0 eisbe = 320000 ) ).

    mo_cut = NEW zcl_sd_stock_query(
      io_dao       = mo_dao
      io_exclusion = mo_exclusion ).
  ENDMETHOD.

  METHOD test_valid_material_and_company.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING
        iv_matnr      = 'W563587071'
        iv_bukrs      = '1000'
      IMPORTING
        ev_matnr_desc = DATA(lv_desc)
        et_messages   = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_result ) ).
    cl_abap_unit_assert=>assert_initial( act = lt_messages ).
    cl_abap_unit_assert=>assert_not_initial( act = lv_desc ).
  ENDMETHOD.

  METHOD test_empty_matnr.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING
        iv_matnr      = space
        iv_bukrs      = '1000'
      IMPORTING
        ev_matnr_desc = DATA(lv_desc)
        et_messages   = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_messages ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'E' act = lt_messages[ 1 ]-type ).
  ENDMETHOD.

  METHOD test_empty_bukrs.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING
        iv_matnr      = 'W563587071'
        iv_bukrs      = space
      IMPORTING
        ev_matnr_desc = DATA(lv_desc)
        et_messages   = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_messages ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'E' act = lt_messages[ 1 ]-type ).
  ENDMETHOD.

  METHOD test_material_not_found.
    mo_dao->mv_material_exists = abap_false.

    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING
        iv_matnr      = 'NOEXISTE'
        iv_bukrs      = '1000'
      IMPORTING
        ev_matnr_desc = DATA(lv_desc)
        et_messages   = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result ).
    cl_abap_unit_assert=>assert_equals( exp = 'E' act = lt_messages[ 1 ]-type ).
  ENDMETHOD.

  METHOD test_company_not_found.
    mo_dao->mv_company_exists = abap_false.

    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING
        iv_matnr      = 'W563587071'
        iv_bukrs      = '9999'
      IMPORTING
        ev_matnr_desc = DATA(lv_desc)
        et_messages   = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result ).
    cl_abap_unit_assert=>assert_equals( exp = 'E' act = lt_messages[ 1 ]-type ).
  ENDMETHOD.

  METHOD test_no_stock_found.
    mo_dao->mt_stock_to_return = VALUE #( ).

    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING
        iv_matnr      = 'W563587071'
        iv_bukrs      = '1000'
      IMPORTING
        ev_matnr_desc = DATA(lv_desc)
        et_messages   = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_messages ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'I' act = lt_messages[ 1 ]-type ).
  ENDMETHOD.

  METHOD test_excluded_plant_flagged.
    " Configurar exclusion double para retornar planta excluida
    mo_exclusion->mv_pass_through = abap_false.
    mo_exclusion->mt_result_to_return = VALUE #(
      ( werks = '1020' name1 = 'Prescott Production'
        labst = 921000 is_excluded = abap_false )
      ( werks = '1053' name1 = 'Salt Lake City Production'
        labst = 575000 is_excluded = abap_true
        exclusion_reason = 'Planta excluida (KOTG504)' ) ).

    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING
        iv_matnr      = 'W563587071'
        iv_bukrs      = '1000'
      IMPORTING
        ev_matnr_desc = DATA(lv_desc)
        et_messages   = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lt_result[ werks = '1053' ]-is_excluded ).
  ENDMETHOD.

  METHOD test_non_excluded_plant.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING
        iv_matnr      = 'W563587071'
        iv_bukrs      = '1000'
      IMPORTING
        ev_matnr_desc = DATA(lv_desc)
        et_messages   = DATA(lt_messages) ).

    " Con pass_through = true, ninguna planta está excluida
    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lt_result[ werks = '1020' ]-is_excluded ).
  ENDMETHOD.

  METHOD test_matnr_desc_populated.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING
        iv_matnr      = 'W563587071'
        iv_bukrs      = '1000'
      IMPORTING
        ev_matnr_desc = DATA(lv_desc)
        et_messages   = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'S20 WATERBLOCK (25 CARTRIDGES)'
      act = lv_desc ).
  ENDMETHOD.

ENDCLASS.
