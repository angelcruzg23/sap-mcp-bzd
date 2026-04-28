*&---------------------------------------------------------------------*
*& 03/06/2017  RAKSHAN SUVARNA    BZDK913770      CRQ42434             *
*& Search Term : RS03062017                                            *
*& Description : Activate "Actual Delivery Date" field on TMS Info Tab *
*&---------------------------------------------------------------------*
*& 04/08/2026  ANGEL CRUZ          BZDKXXXXXX      CHG0432318          *
*& Search Term : AC04082026                                            *
*& Description : New Conestoga equipment type for US Bank              *
*&---------------------------------------------------------------------*
FUNCTION-POOL zsde_shpmnt_delivry_hd_tab.   "MESSAGE-ID ..

* INCLUDE LZSDE_SHPMNT_DELIVRY_HD_TABD...    " Local class definition
* INCLUDE LZSDE_SHPMNT_DELIVRY_HD_TABP...    " Local class implementation

DATA: gv_vbeln        TYPE likp-vbeln,
      gv_carrier      TYPE likp-zcarrier,
      gv_zmile_rate   TYPE likp-zmile_rate,
      gv_ztot_miles   TYPE likp-ztot_miles,
      gv_zcom_stops   TYPE likp-zcom_stops,
      gv_zord_stops   TYPE likp-zord_stops,
      gv_zmilk_run    TYPE likp-zmilk_run,
      gv_zbol_wgt     TYPE likp-zbol_wgt,
      gv_zspot_rate   TYPE likp-zspot_rate,
      gv_ztknum       TYPE likp-ztknum,
      gv_shipdate     TYPE likp-zship_date,
      gv_zorigin_plant TYPE likp-zorigin_plant,
      gv_ship_ident   TYPE likp-zshmt_ident,
      gv_zzactdeldate TYPE likp-zzactdeldate,                " +RS03062017
      gv_zzequipe_type TYPE likp-zzequipe_type.              " +AC04082026 CHG0432318 Conestoga equipment type
