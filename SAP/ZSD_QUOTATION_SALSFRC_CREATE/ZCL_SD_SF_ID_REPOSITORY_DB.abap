CLASS zcl_sd_sf_id_repository_db DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_sf_id_repository.

  PRIVATE SECTION.
    CONSTANTS: c_table_name TYPE tabname VALUE 'ZZSD_SFDC_QUOTES'.

ENDCLASS.

CLASS zcl_sd_sf_id_repository_db IMPLEMENTATION.

  METHOD zif_sd_sf_id_repository~exists.
    " Single Responsibility: Check database for existing Salesforce ID
    SELECT SINGLE @abap_true
      FROM (c_table_name)
      WHERE zzsalesforce_id = @iv_salesforce_id
      INTO @rv_exists.

    IF sy-subrc <> 0.
      rv_exists = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sd_sf_id_repository~get_document_by_sf_id.
    " Single Responsibility: Retrieve document number from database
    SELECT SINGLE vbeln
      FROM (c_table_name)
      WHERE zzsalesforce_id = @iv_salesforce_id
      INTO @rv_vbeln.
  ENDMETHOD.

  METHOD zif_sd_sf_id_repository~save.
    " Single Responsibility: Save Salesforce ID mapping to database
    DATA: ls_record TYPE REF TO data.

    FIELD-SYMBOLS: <fs_record> TYPE any,
                   <fv_sf_id>  TYPE any,
                   <fv_vbeln>  TYPE any.

    " Create dynamic structure for the table
    CREATE DATA ls_record TYPE (c_table_name).
    ASSIGN ls_record->* TO <fs_record>.

    ASSIGN COMPONENT 'ZZSALESFORCE_ID' OF STRUCTURE <fs_record> TO <fv_sf_id>.
    ASSIGN COMPONENT 'VBELN' OF STRUCTURE <fs_record> TO <fv_vbeln>.

    IF sy-subrc = 0.
      <fv_sf_id> = iv_salesforce_id.
      <fv_vbeln> = iv_vbeln.

      INSERT (c_table_name) FROM <fs_record>.
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE cx_sy_open_sql_db.
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
