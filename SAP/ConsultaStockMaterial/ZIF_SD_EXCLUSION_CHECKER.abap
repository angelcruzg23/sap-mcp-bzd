*----------------------------------------------------------------------*
* Interfaz: ZIF_SD_EXCLUSION_CHECKER
* Descripción: Interfaz del verificador de exclusiones KOTG504.
*              Evalúa si las plantas están en la lista de exclusión
*              para un material dado.
* Paquete: ZDEV_SD
*----------------------------------------------------------------------*
INTERFACE zif_sd_exclusion_checker PUBLIC.

  "! Evalúa exclusiones KOTG504 para todas las plantas del resultado.
  "! Ejecuta una sola consulta a BD para todas las plantas (sin SELECT en LOOP).
  "! Asigna IS_EXCLUDED y EXCLUSION_REASON en cada entrada.
  "! @parameter iv_matnr       | Número de material
  "! @parameter it_plant_stock | Stock por planta (entrada sin flags de exclusión)
  "! @parameter rt_result      | Stock por planta con IS_EXCLUDED y EXCLUSION_REASON poblados
  METHODS check_exclusions
    IMPORTING
      iv_matnr       TYPE matnr
      it_plant_stock TYPE zty_sd_plant_stock_t
    RETURNING VALUE(rt_result) TYPE zty_sd_plant_stock_t.

ENDINTERFACE.
