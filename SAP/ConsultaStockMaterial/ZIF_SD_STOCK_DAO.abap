*----------------------------------------------------------------------*
* Interfaz: ZIF_SD_STOCK_DAO
* Descripción: Interfaz del Data Access Object para consulta de stock.
*              Abstrae todo acceso a tablas SAP (MARD, MARC, T001W,
*              T001K, MAKT, MARA, T001).
* Paquete: ZSD_SF
*----------------------------------------------------------------------*
INTERFACE zif_sd_stock_dao PUBLIC.

  TYPES: BEGIN OF ty_werks_range,
           sign   TYPE char1,
           option TYPE char2,
           low    TYPE werks_d,
           high   TYPE werks_d,
         END OF ty_werks_range,
         tty_werks_range TYPE TABLE OF ty_werks_range WITH DEFAULT KEY.

  "! Retorna el rango de plantas asociadas a una sociedad (T001K + T001W).
  "! @parameter iv_bukrs   | Sociedad
  "! @parameter rt_plants  | Rango de plantas (para uso en WHERE ... IN)
  METHODS get_plants_for_company
    IMPORTING iv_bukrs TYPE bukrs
    RETURNING VALUE(rt_plants) TYPE tty_werks_range.

  "! Retorna stock por planta para un material, solo plantas activas en MARC.
  "! Incluye LABST, EINME, SPEME, EISBE y NAME1 de T001W.
  "! @parameter iv_matnr  | Número de material
  "! @parameter it_plants | Rango de plantas a consultar
  "! @parameter rt_stock  | Stock por planta
  METHODS get_material_stock
    IMPORTING
      iv_matnr  TYPE matnr
      it_plants TYPE tty_werks_range
    RETURNING VALUE(rt_stock) TYPE zty_sd_plant_stock_t.

  "! Retorna la descripción del material en idioma EN desde MAKT.
  "! @parameter iv_matnr | Número de material
  "! @parameter rv_desc  | Descripción (MAKTX)
  METHODS get_material_description
    IMPORTING iv_matnr TYPE matnr
    RETURNING VALUE(rv_desc) TYPE makt-maktx.

  "! Verifica si el material existe en MARA.
  "! @parameter iv_matnr  | Número de material
  "! @parameter rv_exists | ABAP_TRUE si existe
  METHODS validate_material
    IMPORTING iv_matnr TYPE matnr
    RETURNING VALUE(rv_exists) TYPE abap_bool.

  "! Verifica si la sociedad existe en T001.
  "! @parameter iv_bukrs  | Sociedad
  "! @parameter rv_exists | ABAP_TRUE si existe
  METHODS validate_company
    IMPORTING iv_bukrs TYPE bukrs
    RETURNING VALUE(rv_exists) TYPE abap_bool.

ENDINTERFACE.
