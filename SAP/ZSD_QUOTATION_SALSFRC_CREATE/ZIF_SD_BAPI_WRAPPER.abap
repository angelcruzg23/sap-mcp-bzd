INTERFACE zif_sd_bapi_wrapper
  PUBLIC.

  " Interface Segregation Principle: Specific interface for BAPI operations
  METHODS create_quotation
    IMPORTING
      is_request              TYPE zcl_sd_quotation_creator=>ty_quotation_request
      it_items_in             TYPE ztt_sd_bapisditm
      it_partners             TYPE STANDARD TABLE
      it_schedules_in         TYPE ztt_sd_bapischdl
      it_conditions_in        TYPE ztt_sd_bapicond
    EXPORTING
      ev_salesdocument        TYPE bapivbeln-vbeln
      et_return               TYPE bapiret2_t.

  METHODS commit_transaction.

  METHODS rollback_transaction.

ENDINTERFACE.
