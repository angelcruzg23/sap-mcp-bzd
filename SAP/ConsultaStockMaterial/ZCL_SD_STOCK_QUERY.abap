*----------------------------------------------------------------------*
* Clase: ZCL_SD_STOCK_QUERY
* Descripción: Orquestador principal de consulta de stock por planta.
*              Implementa ZIF_SD_STOCK_QUERY.
*              Coordina validaciones, consulta de stock y verificación
*              de exclusiones KOTG504. No contiene ningún SELECT.
*              Usa inyección de dependencias (DIP).
* Paquete: ZDEV_SD
*----------------------------------------------------------------------*
CLASS zcl_sd_stock_query DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_stock_query.

    "! Constructor con inyección de dependencias.
    "! Si no se proveen dependencias, instancia las clases concretas por defecto.
    "! @parameter io_dao       | Implementación de ZIF_SD_STOCK_DAO (opcional)
    "! @parameter io_exclusion | Implementación de ZIF_SD_EXCLUSION_CHECKER (opcional)
    METHODS constructor
      IMPORTING
        io_dao       TYPE REF TO zif_sd_stock_dao       OPTIONAL
        io_exclusion TYPE REF TO zif_sd_exclusion_checker OPTIONAL.

  PRIVATE SECTION.
    DATA mo_dao       TYPE REF TO zif_sd_stock_dao.
    DATA mo_exclusion TYPE REF TO zif_sd_exclusion_checker.

    "! Agrega un mensaje de error a la tabla de mensajes.
    "! @parameter iv_text     | Texto del mensaje
    "! @parameter ct_messages | Tabla de mensajes (CHANGING)
    METHODS add_error_message
      IMPORTING iv_text     TYPE string
      CHANGING  ct_messages TYPE bapiret2_t.

    "! Agrega un mensaje informativo a la tabla de mensajes.
    "! @parameter iv_text     | Texto del mensaje
    "! @parameter ct_messages | Tabla de mensajes (CHANGING)
    METHODS add_info_message
      IMPORTING iv_text     TYPE string
      CHANGING  ct_messages TYPE bapiret2_t.

ENDCLASS.

CLASS zcl_sd_stock_query IMPLEMENTATION.

  METHOD constructor.
    mo_dao = COND #(
      WHEN io_dao IS BOUND THEN io_dao
      ELSE NEW zcl_sd_stock_dao( ) ).
    mo_exclusion = COND #(
      WHEN io_exclusion IS BOUND THEN io_exclusion
      ELSE NEW zcl_sd_exclusion_checker( ) ).
  ENDMETHOD.

  METHOD zif_sd_stock_query~get_stock_by_plant.
    CLEAR: rt_result, ev_matnr_desc, et_messages.

    " Paso 1: Validar parámetros de entrada
    IF iv_matnr IS INITIAL.
      add_error_message(
        EXPORTING iv_text     = 'Material number is required'
        CHANGING  ct_messages = et_messages ).
      RETURN.
    ENDIF.

    IF iv_bukrs IS INITIAL.
      add_error_message(
        EXPORTING iv_text     = 'Company code is required'
        CHANGING  ct_messages = et_messages ).
      RETURN.
    ENDIF.

    " Paso 2: Validar existencia en BD
    IF mo_dao->validate_material( iv_matnr ) = abap_false.
      add_error_message(
        EXPORTING iv_text     = |Material { iv_matnr } does not exist in the system|
        CHANGING  ct_messages = et_messages ).
      RETURN.
    ENDIF.

    IF mo_dao->validate_company( iv_bukrs ) = abap_false.
      add_error_message(
        EXPORTING iv_text     = |Company code { iv_bukrs } does not exist in the system|
        CHANGING  ct_messages = et_messages ).
      RETURN.
    ENDIF.

    " Paso 3: Obtener plantas de la sociedad
    DATA(lt_plants) = mo_dao->get_plants_for_company( iv_bukrs ).  " tipo tty_werks_range

    " Paso 4: Obtener stock por planta
    DATA(lt_stock) = mo_dao->get_material_stock(
      iv_matnr  = iv_matnr
      it_plants = lt_plants ).

    " Paso 5: Verificar si hay stock
    IF lt_stock IS INITIAL.
      add_info_message(
        EXPORTING iv_text     = |No stock found for material { iv_matnr } in company code { iv_bukrs }|
        CHANGING  ct_messages = et_messages ).
      RETURN.
    ENDIF.

    " Paso 6: Evaluar exclusiones KOTG504
    lt_stock = mo_exclusion->check_exclusions(
      iv_matnr       = iv_matnr
      it_plant_stock = lt_stock ).

    " Paso 7: Obtener descripción del material
    ev_matnr_desc = mo_dao->get_material_description( iv_matnr ).

    " Paso 8: Retornar resultado
    rt_result = lt_stock.
  ENDMETHOD.

  METHOD add_error_message.
    APPEND VALUE #(
      type       = 'E'
      id         = 'ZSD_STOCK'
      number     = '001'
      message    = iv_text
    ) TO ct_messages.
  ENDMETHOD.

  METHOD add_info_message.
    APPEND VALUE #(
      type       = 'I'
      id         = 'ZSD_STOCK'
      number     = '002'
      message    = iv_text
    ) TO ct_messages.
  ENDMETHOD.

ENDCLASS.
