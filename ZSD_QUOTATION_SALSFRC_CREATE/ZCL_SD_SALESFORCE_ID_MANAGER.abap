CLASS zcl_sd_salesforce_id_manager DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_salesforce_id_manager.

    METHODS constructor
      IMPORTING
        io_repository TYPE REF TO zif_sd_sf_id_repository OPTIONAL.

  PRIVATE SECTION.
    DATA:
      mo_repository TYPE REF TO zif_sd_sf_id_repository.

ENDCLASS.

CLASS zcl_sd_salesforce_id_manager IMPLEMENTATION.

  METHOD constructor.
    " Dependency Inversion: Depend on abstraction, not concrete implementation
    IF io_repository IS BOUND.
      mo_repository = io_repository.
    ELSE.
      " Default implementation if none provided
      mo_repository = NEW zcl_sd_sf_id_repository_db( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_sd_salesforce_id_manager~check_duplicate.
    " Single Responsibility: Check if Salesforce ID exists
    rv_exists = mo_repository->exists( iv_salesforce_id ).
  ENDMETHOD.

  METHOD zif_sd_salesforce_id_manager~get_existing_document.
    " Single Responsibility: Get existing document by Salesforce ID
    rv_vbeln = mo_repository->get_document_by_sf_id( iv_salesforce_id ).
  ENDMETHOD.

  METHOD zif_sd_salesforce_id_manager~persist_salesforce_id.
    " Single Responsibility: Persist Salesforce ID mapping
    TRY.
        mo_repository->save(
          iv_salesforce_id = iv_salesforce_id
          iv_vbeln         = iv_salesdocument ).
        rv_success = abap_true.
      CATCH cx_root.
        rv_success = abap_false.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
