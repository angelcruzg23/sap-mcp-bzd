*----------------------------------------------------------------------*
* Class ZCL_SD_QUICK_ORDERS_DAO
* Implementación real del acceso a datos (SELECT sobre VBAK/VBAP)
*----------------------------------------------------------------------*
CLASS zcl_sd_quick_orders_dao DEFINITION PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_quick_orders_dao.

ENDCLASS.

CLASS zcl_sd_quick_orders_dao IMPLEMENTATION.

  METHOD zif_sd_quick_orders_dao~get_orders.

    SELECT k~vbeln k~erdat k~erzet k~ernam k~auart
           k~vkorg k~vtweg k~spart k~kunnr k~netwr
           p~posnr p~matnr p~arktx p~kwmeng p~vrkme
           p~netwr AS netwr_p p~werks p~lgort p~pstyv p~abgru
      INTO TABLE et_data
      FROM vbak AS k
      INNER JOIN vbap AS p ON p~vbeln = k~vbeln
      WHERE k~erdat IN it_erdat
        AND k~auart IN it_auart
      ORDER BY k~vbeln k~erdat p~posnr.

  ENDMETHOD.

ENDCLASS.
