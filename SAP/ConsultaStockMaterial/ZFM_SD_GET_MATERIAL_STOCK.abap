*----------------------------------------------------------------------*
* Function Module: ZFM_SD_GET_MATERIAL_STOCK
* Function Group:  ZFG_SD_STOCK_QUERY
* Descripción: FM RFC-enabled para consulta de stock de material
*              por planta para una sociedad. Replica la información
*              de la transacción MMBE incluyendo verificación de
*              exclusiones KOTG504.
*              Consumido por Mulesoft para integración con Salesforce.
* Paquete: ZDEV_SD
*----------------------------------------------------------------------*
FUNCTION zfm_sd_get_material_stock.
*"----------------------------------------------------------------------
*"*"Interfaz local:
*"  IMPORTING
*"     VALUE(IV_MATNR) TYPE  MATNR
*"     VALUE(IV_BUKRS) TYPE  BUKRS
*"  EXPORTING
*"     VALUE(EV_MATNR_DESC) TYPE  MAKT-MAKTX
*"  TABLES
*"     ET_PLANT_STOCK STRUCTURE  ZST_SD_PLANT_STOCK
*"     ET_MESSAGES STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  DATA lo_query TYPE REF TO zif_sd_stock_query.

  TRY.
      lo_query = NEW zcl_sd_stock_query( ).

      et_plant_stock[] = lo_query->get_stock_by_plant(
        EXPORTING
          iv_matnr      = iv_matnr
          iv_bukrs      = iv_bukrs
        IMPORTING
          ev_matnr_desc = ev_matnr_desc
          et_messages   = et_messages[] ).

    CATCH cx_root INTO DATA(lx_error).
      APPEND VALUE bapiret2(
        type       = 'E'
        id         = 'ZSD_STOCK'
        number     = '000'
        message    = lx_error->get_text( )
      ) TO et_messages[].
  ENDTRY.

ENDFUNCTION.
