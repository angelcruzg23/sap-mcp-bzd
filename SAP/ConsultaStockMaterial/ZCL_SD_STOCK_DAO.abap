*----------------------------------------------------------------------*
* Clase: ZCL_SD_STOCK_DAO
* Descripción: Data Access Object para consulta de stock por planta.
*              Implementa ZIF_SD_STOCK_DAO.
*              Centraliza todo acceso a tablas SAP: MARD, MARC, T001W,
*              T001K, MAKT, MARA, T001.
*              Sin lógica de negocio — solo acceso a datos.
* Paquete: ZSD_SF
* Compatibilidad: SAP_ABA 750 SP32
*----------------------------------------------------------------------*
CLASS zcl_sd_stock_dao DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_stock_dao.

ENDCLASS.

CLASS zcl_sd_stock_dao IMPLEMENTATION.

  METHOD zif_sd_stock_dao~get_plants_for_company.
    " JOIN T001K + T001W para obtener plantas de la sociedad
    SELECT t1w~werks
      FROM t001k AS t1k
      INNER JOIN t001w AS t1w ON t1w~bwkey = t1k~bwkey
      WHERE t1k~bukrs = @iv_bukrs
      INTO TABLE @DATA(lt_werks).

    rt_plants = VALUE zif_sd_stock_dao=>tty_werks_range(
      FOR ls_w IN lt_werks
      ( sign = 'I' option = 'EQ' low = ls_w-werks ) ).
  ENDMETHOD.

  METHOD zif_sd_stock_dao~get_material_stock.
    " Paso 1: Plantas donde el material existe y no está marcado para borrado
    SELECT matnr, werks
      FROM marc
      WHERE matnr = @iv_matnr
        AND werks IN @it_plants
        AND lvorm = @space
      INTO TABLE @DATA(lt_marc).

    CHECK lt_marc IS NOT INITIAL.

    " Paso 2: Stock desde MARD (FOR ALL ENTRIES sobre lt_marc)
    " Nota: EISBE no es campo de MARD — los campos de stock en MARD son:
    "   LABST (libre utilización), EINME (control calidad),
    "   SPEME (bloqueado), INSME (inspección)
    SELECT matnr, werks, labst, einme, speme
      FROM mard
      FOR ALL ENTRIES IN @lt_marc
      WHERE matnr = @lt_marc-matnr
        AND werks = @lt_marc-werks
      INTO TABLE @DATA(lt_mard).

    " Paso 3: Nombres de planta desde T001W
    SELECT werks, name1
      FROM t001w
      WHERE werks IN @it_plants
      INTO TABLE @DATA(lt_t001w).

    " Paso 4: Construir resultado con LOOP clásico
    " (VALUE # con LET + table expression OPTIONAL no es estable en 7.50 SP32)
    DATA ls_result TYPE zst_sd_plant_stock.

    LOOP AT lt_marc ASSIGNING FIELD-SYMBOL(<ls_marc>).
      CLEAR ls_result.
      ls_result-werks = <ls_marc>-werks.

      " Buscar nombre de planta
      READ TABLE lt_t001w ASSIGNING FIELD-SYMBOL(<ls_t001w>)
        WITH KEY werks = <ls_marc>-werks.
      IF sy-subrc = 0.
        ls_result-name1 = <ls_t001w>-name1.
      ENDIF.

      " Buscar stock — si no hay registro en MARD, queda en cero
      READ TABLE lt_mard ASSIGNING FIELD-SYMBOL(<ls_mard>)
        WITH KEY matnr = <ls_marc>-matnr
                 werks = <ls_marc>-werks.
      IF sy-subrc = 0.
        ls_result-labst = <ls_mard>-labst.
        ls_result-einme = <ls_mard>-einme.
        ls_result-speme = <ls_mard>-speme.
      ENDIF.

      APPEND ls_result TO rt_stock.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~get_material_description.
    SELECT SINGLE maktx FROM makt
      WHERE matnr = @iv_matnr
        AND spras = 'EN'
      INTO @rv_desc.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~validate_material.
    SELECT SINGLE matnr FROM mara
      WHERE matnr = @iv_matnr
      INTO @DATA(lv_matnr).
    rv_exists = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD zif_sd_stock_dao~validate_company.
    SELECT SINGLE bukrs FROM t001
      WHERE bukrs = @iv_bukrs
      INTO @DATA(lv_bukrs).
    rv_exists = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

ENDCLASS.
