INTERFACE zif_sd_salesforce_id_manager
  PUBLIC.

  " Interface Segregation Principle: Specific interface for Salesforce ID management
  METHODS check_duplicate
    IMPORTING
      iv_salesforce_id     TYPE zzsalesforce_id
    RETURNING
      VALUE(rv_exists)     TYPE abap_bool.

  METHODS get_existing_document
    IMPORTING
      iv_salesforce_id     TYPE zzsalesforce_id
    RETURNING
      VALUE(rv_vbeln)      TYPE vbeln_va.

  METHODS persist_salesforce_id
    IMPORTING
      iv_salesforce_id     TYPE zzsalesforce_id
      iv_salesdocument     TYPE bapivbeln-vbeln
    RETURNING
      VALUE(rv_success)    TYPE abap_bool.

ENDINTERFACE.
