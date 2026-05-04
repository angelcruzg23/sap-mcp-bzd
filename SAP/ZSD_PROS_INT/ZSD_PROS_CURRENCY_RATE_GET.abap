FUNCTION ZSD_PROS_CURRENCY_RATE_GET
  IMPORTING
    VALUE(IT_CURRS) TYPE ZSDTT_TCURR
  EXPORTING
    VALUE(ET_RATE) TYPE ZSDTT_CURRENCY_RATE.

* Descripción:
*   Obtiene tasas de cambio de moneda desde la tabla TCURR para una
*   lista de combinaciones moneda origen/destino y fecha.
*
*   Recibe una tabla con pares de monedas (curr_from, curr_to) y fecha,
*   convierte las fechas al formato invertido de SAP (GDATU) y consulta
*   las tasas correspondientes en TCURR con un solo acceso a BD.
*
* Parámetros:
*   IT_CURRS  - Tabla de entrada con moneda origen, destino y fecha
*   ET_RATE   - Tabla de salida con los registros TCURR encontrados
*
* Notas:
*   - Solo retorna registros donde se encontró match exacto en TCURR
*   - Usa FOR ALL ENTRIES para evitar SELECT dentro de LOOP

* +CHG0434843 — BEGIN — Refactor: eliminar SELECT en LOOP, campos explícitos

  TYPES: BEGIN OF lty_lookup,
           fcurr TYPE tcurr-fcurr,
           tcurr TYPE tcurr-tcurr,
           gdatu TYPE tcurr-gdatu,
         END OF lty_lookup.

  DATA lt_lookup TYPE STANDARD TABLE OF lty_lookup.

  CHECK it_currs IS NOT INITIAL.

  " Preparar tabla auxiliar con fechas convertidas a formato invertido
  LOOP AT it_currs INTO DATA(ls_curr).
    DATA(lv_gdatu) = VALUE gdatu_inv( ).
    CONVERT INVERTED-DATE ls_curr-datum INTO DATE lv_gdatu.
    APPEND VALUE lty_lookup(
      fcurr = ls_curr-curr_from
      tcurr = ls_curr-curr_to
      gdatu = lv_gdatu
    ) TO lt_lookup.
  ENDLOOP.

  " Un solo SELECT con FOR ALL ENTRIES en lugar de SELECT por cada registro
  IF lt_lookup IS NOT INITIAL.
    SELECT kurst, fcurr, tcurr, gdatu, ukurs, ffact, tfact
      FROM tcurr
      FOR ALL ENTRIES IN @lt_lookup
      WHERE fcurr = @lt_lookup-fcurr
        AND tcurr = @lt_lookup-tcurr
        AND gdatu = @lt_lookup-gdatu
      INTO CORRESPONDING FIELDS OF TABLE @et_rate.
  ENDIF.

* +CHG0434843 — END

ENDFUNCTION.
