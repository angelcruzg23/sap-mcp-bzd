*&---------------------------------------------------------------------*
*& Enhancement Implementation: ZSDE_TMS2SAP_DELIVERY_DATA
*& Program: MV50AFZ1 (User Exit for Delivery Processing)
*& Package: ZSD_SHIPPING_DELIVER
*&---------------------------------------------------------------------*
*& CHG0432318 - New Conestoga equipment type for US Bank
*& Author: ANGEL CRUZ
*& Date: 04/08/2026
*& Search Term: AC04082026
*&---------------------------------------------------------------------*
*& Description:
*& When TMS sends equipment type 'ZZ' (Conestoga), the enhancement
*& updates the new custom field ZZEQUIPE_TYPE in the delivery header
*& (LIKP). This avoids re-mapping in PI/PO. The field is only
*& populated when the Conestoga equipment type is received from TMS.
*&---------------------------------------------------------------------*
*& EXISTING CODE in the enhancement (before change):
*& The enhancement already handles the transfer of TMS data fields
*& into the delivery document (LIKP). The new lines below are added
*& at the end of the existing field assignments.
*&---------------------------------------------------------------------*

" =====================================================================
" BEGIN OF CHANGE - CHG0432318 - AC04082026
" New Conestoga equipment type for US Bank
" =====================================================================
"
" Context: This code runs inside the enhancement ZSDE_TMS2SAP_DELIVERY_DATA
" within MV50AFZ1. The enhancement is triggered when TMS sends shipment
" data to SAP and the delivery document is being updated.
"
" The variable ls_likp (or equivalent delivery header work area) and
" the TMS inbound data structure (ls_tms_data or equivalent) are
" available in scope from the existing enhancement code.
"
" Logic: Only update ZZEQUIPE_TYPE when TMS sends 'ZZ' (Conestoga).
" For any other equipment type, the field remains unchanged.
" This avoids the need for a new mapping in PI/PO.
" =====================================================================

*--- Conestoga equipment type handling (CHG0432318) ---*
" The shipping condition field (VSBED) carries the equipment type from TMS.
" Value 'ZZ' = Conestoga (ZZCONST). Only populate the new field when
" the Conestoga type is explicitly sent.

CONSTANTS: lc_conestoga_equip TYPE char2 VALUE 'ZZ'.        " +AC04082026

IF ls_tms_data-vsbed = lc_conestoga_equip.                  " +AC04082026
  ls_likp-zzequipe_type = lc_conestoga_equip.               " +AC04082026
ENDIF.                                                       " +AC04082026

" =====================================================================
" END OF CHANGE - CHG0432318 - AC04082026
" =====================================================================
