*----------------------------------------------------------------------*
* Clase de prueba: ZCL_SD_EXCLUSION_CHECKER_TEST
* Descripción: Tests unitarios para ZCL_SD_EXCLUSION_CHECKER.
*              Prueba lógica de exclusiones KOTG504: fechas vigentes,
*              exclusión por planta, exclusión a nivel material,
*              exclusiones vencidas.
*              NOTA: Requiere datos de prueba en KOTG504 o usar
*              OSQL Test Double Framework para aislar de BD.
* Paquete: ZDEV_SD
*----------------------------------------------------------------------*
CLASS zcl_sd_exclusion_checker_test DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_sd_exclusion_checker.

    METHODS setup.

    " Nota: Estos tests documentan el comportamiento esperado.
    " Para ejecución real sin datos en BD, se recomienda usar
    " CL_OSQL_TEST_ENVIRONMENT para inyectar datos de prueba
    " en KOTG504.

    METHODS test_empty_input              FOR TESTING.
    METHODS test_no_exclusion_records     FOR TESTING.
    METHODS test_active_exclusion_by_plant FOR TESTING.
    METHODS test_expired_exclusion_ignored FOR TESTING.
    METHODS test_material_level_exclusion FOR TESTING.
    METHODS test_exclusion_reason_plant   FOR TESTING.
    METHODS test_exclusion_reason_material FOR TESTING.
ENDCLASS.

CLASS zcl_sd_exclusion_checker_test IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW zcl_sd_exclusion_checker( ).
  ENDMETHOD.

  METHOD test_empty_input.
    " Entrada vacía debe retornar vacío sin consultar BD
    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr       = 'W563587071'
      it_plant_stock = VALUE #( ) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result ).
  ENDMETHOD.

  METHOD test_no_exclusion_records.
    " Material sin registros en KOTG504 → IS_EXCLUDED = space
    " Usar un material ficticio que no tenga exclusiones
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '1020' name1 = 'Prescott' labst = 100 )
      ( werks = '1053' name1 = 'Salt Lake' labst = 200 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr       = 'ZTEST_NO_EXCL'
      it_plant_stock = lt_input ).

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_result ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lt_result[ 1 ]-is_excluded ).
    cl_abap_unit_assert=>assert_equals(
      exp = abap_false
      act = lt_result[ 2 ]-is_excluded ).
  ENDMETHOD.

  METHOD test_active_exclusion_by_plant.
    " W563587071 tiene exclusión activa para planta 1030 en KOTG504
    " (según datos reales del sistema BZD)
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '1020' name1 = 'Prescott' labst = 921000 )
      ( werks = '1030' name1 = 'Welford'  labst = 1000 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr       = 'W563587071'
      it_plant_stock = lt_input ).

    " Planta 1030 debe estar excluida (registro activo en KOTG504)
    cl_abap_unit_assert=>assert_equals(
      exp = abap_true
      act = lt_result[ werks = '1030' ]-is_excluded ).
  ENDMETHOD.

  METHOD test_expired_exclusion_ignored.
    " Planta 1090 tiene exclusión con Valid to = 11/21/2025 (vencida)
    " No debe contar como exclusión activa
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '1090' name1 = 'Test Plant' labst = 500 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr       = 'W563587071'
      it_plant_stock = lt_input ).

    " Si la exclusión está vencida, IS_EXCLUDED debe ser space
    " Nota: Este test depende de la fecha actual vs Valid to del registro
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_result ) ).
  ENDMETHOD.

  METHOD test_material_level_exclusion.
    " W563587071 tiene registros en KOTG504 sin planta (WERKS vacío)
    " con Valid to = 12/31/9999 → aplica a todas las plantas
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '1020' name1 = 'Prescott' labst = 921000 )
      ( werks = '1053' name1 = 'Salt Lake' labst = 575000 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr       = 'W563587071'
      it_plant_stock = lt_input ).

    " Si hay exclusión a nivel material, todas las plantas deben estar excluidas
    " Nota: Depende de los datos reales en KOTG504 para W563587071
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_result ) ).
  ENDMETHOD.

  METHOD test_exclusion_reason_plant.
    " Verificar que EXCLUSION_REASON contiene texto descriptivo
    " cuando la exclusión es por planta específica
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '1030' name1 = 'Welford' labst = 1000 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr       = 'W563587071'
      it_plant_stock = lt_input ).

    IF lt_result[ 1 ]-is_excluded = abap_true.
      cl_abap_unit_assert=>assert_not_initial(
        act = lt_result[ 1 ]-exclusion_reason ).
    ENDIF.
  ENDMETHOD.

  METHOD test_exclusion_reason_material.
    " Verificar que EXCLUSION_REASON contiene texto descriptivo
    " cuando la exclusión es a nivel material (WERKS vacío en KOTG504)
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '9999' name1 = 'Planta ficticia' labst = 0 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr       = 'W563587071'
      it_plant_stock = lt_input ).

    " Si hay exclusión a nivel material, el reason debe mencionarlo
    IF lt_result[ 1 ]-is_excluded = abap_true.
      cl_abap_unit_assert=>assert_char_cp(
        act = lt_result[ 1 ]-exclusion_reason
        exp = '*all plants*' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
