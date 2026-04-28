*----------------------------------------------------------------------*
* Clase: ZCL_SD_EXCLUSION_CHECKER
* Descripción: Verificador de exclusiones KOTG504 para plantas.
*              Implementa ZIF_SD_EXCLUSION_CHECKER.
*              Una sola consulta a KOTG504 para todas las plantas;
*              sin SELECT en LOOP.
* Paquete: ZDEV_SD
*----------------------------------------------------------------------*
CLASS zcl_sd_exclusion_checker DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_exclusion_checker.

  PRIVATE SECTION.
    CONSTANTS gc_high_date TYPE dats VALUE '99991231'.
    CONSTANTS gc_app       TYPE char1 VALUE 'V'.
    CONSTANTS gc_kschl     TYPE char4 VALUE 'ZB01'.

ENDCLASS.

CLASS zcl_sd_exclusion_checker IMPLEMENTATION.

  METHOD zif_sd_exclusion_checker~check_exclusions.
    " Retornar vacío si no hay plantas que evaluar
    CHECK it_plant_stock IS NOT INITIAL.

    " Paso 1: Una sola consulta a KOTG504 para el material
    " Filtra registros activos: datab <= hoy AND (datbi >= hoy OR datbi = '99991231')
    SELECT kappl, kschl, werks, matnr, datab, datbi
      FROM kotg504
      WHERE matnr = @iv_matnr
        AND kappl = @gc_app
        AND kschl = @gc_kschl
        AND datab <= @sy-datum
        AND ( datbi >= @sy-datum OR datbi = @gc_high_date )
      INTO TABLE @DATA(lt_exclusions).

    " Paso 2: Copiar entrada como base del resultado
    rt_result = it_plant_stock.

    " Paso 3: Para cada planta en el resultado, verificar exclusión
    " (READ TABLE sobre lt_exclusions — sin SELECT en LOOP)
    LOOP AT rt_result ASSIGNING FIELD-SYMBOL(<ls_stock>).
      " Verificar exclusión específica por planta
      READ TABLE lt_exclusions TRANSPORTING NO FIELDS
        WITH KEY werks = <ls_stock>-werks.
      DATA(lv_excl_plant) = xsdbool( sy-subrc = 0 ).

      " Verificar exclusión a nivel material (WERKS vacío)
      READ TABLE lt_exclusions TRANSPORTING NO FIELDS
        WITH KEY werks = space.
      DATA(lv_excl_material) = xsdbool( sy-subrc = 0 ).

      IF lv_excl_plant = abap_true.
        <ls_stock>-is_excluded      = abap_true.
        <ls_stock>-exclusion_reason = |Plant { <ls_stock>-werks } excluded for material { iv_matnr } (KOTG504)|.
      ELSEIF lv_excl_material = abap_true.
        <ls_stock>-is_excluded      = abap_true.
        <ls_stock>-exclusion_reason = |Material { iv_matnr } excluded for all plants (KOTG504)|.
      ELSE.
        <ls_stock>-is_excluded      = abap_false.
        <ls_stock>-exclusion_reason = space.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
