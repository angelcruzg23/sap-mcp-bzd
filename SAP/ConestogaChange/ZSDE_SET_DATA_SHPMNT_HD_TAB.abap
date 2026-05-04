*&---------------------------------------------------------------------*
*& 03/06/2017  RAKSHAN SUVARNA    BZDK913770      CRQ42434             *
*& Search Term : RS03062017                                            *
*& Description : Activate "Actual Delivery Date" field on TMS Info Tab *
*&---------------------------------------------------------------------*
*& 04/08/2026  ANGEL CRUZ          BZDKXXXXXX      CHG0432318          *
*& Search Term : AC04082026                                            *
*& Description : New Conestoga equipment type for US Bank              *
*&---------------------------------------------------------------------*
FUNCTION ZSDE_SET_DATA_SHPMNT_HD_TAB
  IMPORTING
    IS_LIKP TYPE LIKP.

  gv_vbeln = is_likp-vbeln.
  gv_carrier = is_likp-zcarrier.
  gv_zmile_rate = is_likp-zmile_rate.
  gv_ztot_miles = is_likp-ztot_miles.
  gv_zcom_stops = is_likp-zcom_stops.
  gv_zord_stops = is_likp-zord_stops.
  gv_zmilk_run = is_likp-zmilk_run.
  gv_zbol_wgt = is_likp-zbol_wgt.
  gv_zspot_rate = is_likp-zspot_rate.
  gv_ztknum = is_likp-ztknum.
  gv_shipdate = is_likp-zship_date.
  gv_zorigin_plant = is_likp-zorigin_plant.
  gv_ship_ident = is_likp-zshmt_ident.
  gv_zzactdeldate = is_likp-zzactdeldate.                    " +RS03062017
  gv_zzequipe_type = is_likp-zzequipe_type.                  " +AC04082026 CHG0432318

ENDFUNCTION.
