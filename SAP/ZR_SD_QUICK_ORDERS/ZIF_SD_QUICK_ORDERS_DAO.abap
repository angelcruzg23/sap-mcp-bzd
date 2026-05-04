*----------------------------------------------------------------------*
* Interface ZIF_SD_QUICK_ORDERS_DAO
* Acceso a datos de pedidos de venta (VBAK + VBAP)
* Permite inyectar test doubles para ABAP Unit
*----------------------------------------------------------------------*
INTERFACE zif_sd_quick_orders_dao PUBLIC.

  TYPES: BEGIN OF ty_output,
           " Campos VBAK (cabecera)
           vbeln   TYPE vbak-vbeln,
           erdat   TYPE vbak-erdat,
           erzet   TYPE vbak-erzet,
           ernam   TYPE vbak-ernam,
           auart   TYPE vbak-auart,
           vkorg   TYPE vbak-vkorg,
           vtweg   TYPE vbak-vtweg,
           spart   TYPE vbak-spart,
           kunnr   TYPE vbak-kunnr,
           netwr   TYPE vbak-netwr,
           " Campos VBAP (posición)
           posnr   TYPE vbap-posnr,
           matnr   TYPE vbap-matnr,
           arktx   TYPE vbap-arktx,
           kwmeng  TYPE vbap-kwmeng,
           vrkme   TYPE vbap-vrkme,
           netwr_p TYPE vbap-netwr,
           werks   TYPE vbap-werks,
           lgort   TYPE vbap-lgort,
           pstyv   TYPE vbap-pstyv,
           abgru   TYPE vbap-abgru,
         END OF ty_output.

  TYPES: ty_output_t TYPE TABLE OF ty_output WITH EMPTY KEY.

  TYPES: ty_erdat_range TYPE RANGE OF sy-datum.
  TYPES: ty_auart_range TYPE RANGE OF vbak-auart.

  "! Obtiene pedidos de venta según filtros de selección
  "! @parameter it_erdat | Rango de fechas de creación
  "! @parameter it_auart | Rango de tipos de pedido
  "! @parameter et_data  | Datos resultantes
  METHODS get_orders
    IMPORTING it_erdat TYPE ty_erdat_range
              it_auart TYPE ty_auart_range
    EXPORTING et_data  TYPE ty_output_t.

ENDINTERFACE.
