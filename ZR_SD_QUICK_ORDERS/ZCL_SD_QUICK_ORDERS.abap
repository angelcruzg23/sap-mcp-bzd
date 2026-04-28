*----------------------------------------------------------------------*
* Class ZCL_SD_QUICK_ORDERS
* Lógica de negocio para consulta rápida de pedidos
* Depende de ZIF_SD_QUICK_ORDERS_DAO (DIP)
*----------------------------------------------------------------------*
CLASS zcl_sd_quick_orders DEFINITION PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Constructor con inyección de dependencias
    "! @parameter io_dao | Instancia del DAO (opcional, crea default si no se pasa)
    METHODS constructor
      IMPORTING io_dao TYPE REF TO zif_sd_quick_orders_dao OPTIONAL.

    "! Obtiene los pedidos según los filtros proporcionados
    "! @parameter it_erdat | Rango de fechas de creación
    "! @parameter it_auart | Rango de tipos de pedido
    "! @parameter et_data  | Datos resultantes
    "! @parameter ev_count | Cantidad de registros encontrados
    METHODS get_orders
      IMPORTING it_erdat TYPE zif_sd_quick_orders_dao=>ty_erdat_range
                it_auart TYPE zif_sd_quick_orders_dao=>ty_auart_range
      EXPORTING et_data  TYPE zif_sd_quick_orders_dao=>ty_output_t
                ev_count TYPE i.

    "! Indica si la última consulta devolvió datos
    "! @parameter rv_has_data | ABAP_TRUE si hay datos
    METHODS has_data
      RETURNING VALUE(rv_has_data) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mo_dao      TYPE REF TO zif_sd_quick_orders_dao.
    DATA mt_data     TYPE zif_sd_quick_orders_dao=>ty_output_t.
    DATA mv_has_data TYPE abap_bool.

ENDCLASS.

CLASS zcl_sd_quick_orders IMPLEMENTATION.

  METHOD constructor.
    IF io_dao IS BOUND.
      mo_dao = io_dao.
    ELSE.
      mo_dao = NEW zcl_sd_quick_orders_dao( ).
    ENDIF.
  ENDMETHOD.

  METHOD get_orders.
    CLEAR: et_data, ev_count, mt_data, mv_has_data.

    mo_dao->get_orders(
      EXPORTING it_erdat = it_erdat
                it_auart = it_auart
      IMPORTING et_data  = mt_data ).

    et_data  = mt_data.
    ev_count = lines( mt_data ).

    IF ev_count > 0.
      mv_has_data = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD has_data.
    rv_has_data = mv_has_data.
  ENDMETHOD.

ENDCLASS.
