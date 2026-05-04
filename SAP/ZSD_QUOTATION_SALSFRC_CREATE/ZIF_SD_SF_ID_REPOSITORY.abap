INTERFACE zif_sd_sf_id_repository
  PUBLIC.

  " Repository pattern: Abstract data access layer
  METHODS exists
    IMPORTING
      iv_salesforce_id TYPE zzsalesforce_id
    RETURNING
      VALUE(rv_exists) TYPE abap_bool.

  METHODS get_document_by_sf_id
    IMPORTING
      iv_salesforce_id TYPE zzsalesforce_id
    RETURNING
      VALUE(rv_vbeln)  TYPE vbeln_va.

  METHODS save
    IMPORTING
      iv_salesforce_id TYPE zzsalesforce_id
      iv_vbeln         TYPE vbeln_va
    RAISING
      cx_root.

ENDINTERFACE.
