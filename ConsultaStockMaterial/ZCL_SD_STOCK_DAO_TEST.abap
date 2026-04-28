*----------------------------------------------------------------------*
* Clase de prueba: ZCL_SD_STOCK_DAO_TEST
* Descripción: Tests unitarios para ZCL_SD_STOCK_DAO.
*              Prueba consultas reales contra tablas SAP.
*              Requiere datos existentes en el sistema BZD 130.
*              Se recomienda usar CL_OSQL_TEST_ENVIRONMENT para
*              aislar de BD en tests automatizados.
* Paquete: ZDEV_SD
*----------------------------------------------------------------------*
CLASS zcl_sd_stock_dao_test DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_sd_stock_dao.

    METHODS setup.

    METHODS test_validate_material_exists     FOR TESTING.
    METHODS test_validate_material_not_exists FOR TESTING.
    METHODS test_validate_company_exists      FOR TESTING.
    METHODS test_validate_company_not_exists  FOR TESTING.
    METHODS test_get_plants_for_company       FOR TESTING.
    METHODS test_get_material_stock           FOR TESTING.
    METHODS test_get_material_description     FOR TESTING.
    METHODS test_get_stock_empty_plants       FOR TESTING.
ENDCLASS.

CLASS zcl_sd_stock_dao_test IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW zcl_sd_stock_dao( ).
  ENDMETHOD.

  METHOD test_validate_material_exists.
    " W563587071 existe en BZD 130
    DATA(lv_exists) = mo_cut->zif_sd_stock_dao~validate_material( 'W563587071' ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true act = lv_exists ).
  ENDMETHOD.

  METHOD test_validate_material_not_exists.
    DATA(lv_exists) = mo_cut->zif_sd_stock_dao~validate_material( 'ZZZNOEXISTE' ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lv_exists ).
  ENDMETHOD.

  METHOD test_validate_company_exists.
    " Sociedad 1000 (Amrize Building Envelope) existe en BZD 130
    DATA(lv_exists) = mo_cut->zif_sd_stock_dao~validate_company( '1000' ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true act = lv_exists ).
  ENDMETHOD.

  METHOD test_validate_company_not_exists.
    DATA(lv_exists) = mo_cut->zif_sd_stock_dao~validate_company( '9999' ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lv_exists ).
  ENDMETHOD.

  METHOD test_get_plants_for_company.
    " Sociedad 1000 debe tener plantas asociadas
    DATA(lt_plants) = mo_cut->zif_sd_stock_dao~get_plants_for_company( '1000' ).
    cl_abap_unit_assert=>assert_not_initial( act = lt_plants ).

    " Verificar que el rango tiene formato correcto
    cl_abap_unit_assert=>assert_equals(
      exp = 'I'
      act = lt_plants[ 1 ]-sign ).
    cl_abap_unit_assert=>assert_equals(
      exp = 'EQ'
      act = lt_plants[ 1 ]-option ).
  ENDMETHOD.

  METHOD test_get_material_stock.
    " Obtener plantas de sociedad 1000
    DATA(lt_plants) = mo_cut->zif_sd_stock_dao~get_plants_for_company( '1000' ).

    " Obtener stock de W563587071 en esas plantas
    DATA(lt_stock) = mo_cut->zif_sd_stock_dao~get_material_stock(
      iv_matnr  = 'W563587071'
      it_plants = lt_plants ).

    " Debe retornar al menos una planta con stock
    cl_abap_unit_assert=>assert_not_initial( act = lt_stock ).

    " Verificar que WERKS y NAME1 están poblados
    cl_abap_unit_assert=>assert_not_initial( act = lt_stock[ 1 ]-werks ).
    cl_abap_unit_assert=>assert_not_initial( act = lt_stock[ 1 ]-name1 ).
  ENDMETHOD.

  METHOD test_get_material_description.
    DATA(lv_desc) = mo_cut->zif_sd_stock_dao~get_material_description( 'W563587071' ).
    cl_abap_unit_assert=>assert_not_initial( act = lv_desc ).
  ENDMETHOD.

  METHOD test_get_stock_empty_plants.
    " Rango vacío de plantas debe retornar stock vacío
    DATA(lt_stock) = mo_cut->zif_sd_stock_dao~get_material_stock(
      iv_matnr = 'W563587071'
      it_plants = VALUE zif_sd_stock_dao=>tty_werks_range( ) ).

    cl_abap_unit_assert=>assert_initial( act = lt_stock ).
  ENDMETHOD.

ENDCLASS.
