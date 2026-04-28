*----------------------------------------------------------------------*
* Interfaz: ZIF_SD_STOCK_QUERY
* Descripción: Interfaz del orquestador de consulta de stock por planta
* Paquete: ZDEV_SD
*----------------------------------------------------------------------*
INTERFACE zif_sd_stock_query PUBLIC.

  "! Consulta el stock de un material por planta para una sociedad.
  "! Replica la información de la transacción MMBE incluyendo
  "! verificación de exclusiones KOTG504.
  "! @parameter iv_matnr      | Número de material (obligatorio)
  "! @parameter iv_bukrs      | Sociedad (obligatorio)
  "! @parameter ev_matnr_desc | Descripción del material en idioma EN
  "! @parameter et_messages   | Mensajes de error, warning o informativos
  "! @parameter rt_result     | Stock por planta con flag de exclusión
  METHODS get_stock_by_plant
    IMPORTING
      iv_matnr      TYPE matnr
      iv_bukrs      TYPE bukrs
    EXPORTING
      ev_matnr_desc TYPE makt-maktx
      et_messages   TYPE bapiret2_t
    RETURNING
      VALUE(rt_result) TYPE zty_sd_plant_stock_t.

ENDINTERFACE.
