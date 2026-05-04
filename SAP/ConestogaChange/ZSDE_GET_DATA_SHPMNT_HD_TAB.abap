*&---------------------------------------------------------------------*
*& 03/06/2017  RAKSHAN SUVARNA    BZDK913770      CRQ42434             *
*& Search Term : RS03062017                                            *
*& Description : Activate "Actual Delivery Date" field on TMS Info Tab *
*&---------------------------------------------------------------------*
*& 04/08/2026  ANGEL CRUZ          BZDKXXXXXX      CHG0432318          *
*& Search Term : AC04082026                                            *
*& Description : New Conestoga equipment type for US Bank              *
*&---------------------------------------------------------------------*
FUNCTION ZSDE_GET_DATA_SHPMNT_HD_TAB
  EXPORTING
    ES_LIKP TYPE LIKP.

  es_likp-vbeln = gv_vbeln.
  es_likp-zcarrier = gv_carrier.
  es_likp-zmile_rate = gv_zmile_rate.
  es_likp-ztot_miles = gv_ztot_miles.
  es_likp-zcom_stops = gv_zcom_stops.
  es_likp-zord_stops = gv_zord_stops.
  es_likp-zmilk_run = gv_zmilk_run.
  es_likp-zbol_wgt = gv_zbol_wgt.
  es_likp-zspot_rate = gv_zspot_rate.
  es_likp-ztknum = gv_ztknum.
  es_likp-zship_date = gv_shipdate.
  es_likp-zorigin_plant = gv_zorigin_plant.
  es_likp-zshmt_ident = gv_ship_ident.
  es_likp-zzactdeldate = gv_zzactdeldate.                    " +RS03062017
  es_likp-zzequipe_type = gv_zzequipe_type.                  " +AC04082026 CHG0432318

ENDFUNCTION.
