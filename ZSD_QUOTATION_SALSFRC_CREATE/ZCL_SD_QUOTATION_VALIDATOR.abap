CLASS zcl_sd_quotation_validator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_quotation_validator.

    METHODS constructor
      IMPORTING
        io_sf_id_manager TYPE REF TO zif_sd_salesforce_id_manager.

  PRIVATE SECTION.
    DATA:
      mo_sf_id_manager TYPE REF TO zif_sd_salesforce_id_manager,
      mt_messages      TYPE bapiret2_t.

ENDCLASS.

CLASS zcl_sd_quotation_validator IMPLEMENTATION.

  METHOD constructor.
    mo_sf_id_manager = io_sf_id_manager.
  ENDMETHOD.

  METHOD zif_sd_quotation_validator~validate_salesforce_id.
    " Single Responsibility: Only validate Salesforce ID
    CLEAR mt_messages.

    IF iv_salesforce_id IS INITIAL.
      DATA(ls_message) = VALUE bapiret2(
        type       = 'E'
        id         = 'ZSD_CPQ'
        number     = '001'
        message    = 'Salesforce ID is required' ).
      APPEND ls_message TO mt_messages.
      rv_valid = abap_false.
      RETURN.
    ENDIF.

    " Check for duplicates using injected dependency
    IF mo_sf_id_manager->check_duplicate( iv_salesforce_id ) = abap_true.
      DATA(lv_existing_doc) = mo_sf_id_manager->get_existing_document( iv_salesforce_id ).
      ls_message = VALUE bapiret2(
        type       = 'E'
        id         = 'ZSD_CPQ'
        number     = '014'
        message    = |Salesforce ID already exists in document { lv_existing_doc }|
        message_v1 = lv_existing_doc ).
      APPEND ls_message TO mt_messages.
      rv_valid = abap_false.
      RETURN.
    ENDIF.

    rv_valid = abap_true.
  ENDMETHOD.

  METHOD zif_sd_quotation_validator~get_validation_messages.
    rt_messages = mt_messages.
  ENDMETHOD.

ENDCLASS.
