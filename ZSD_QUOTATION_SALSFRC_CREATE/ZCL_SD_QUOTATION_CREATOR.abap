CLASS zcl_sd_quotation_creator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_quotation_request,
        salesdocumentin          TYPE bapivbeln-vbeln,
        quotation_header_in      TYPE zsd_bapisdhd1,
        quotation_header_inx     TYPE bapisdhd1x,
        sender                   TYPE bapi_sender,
        binary_relationshiptype  TYPE bapireltype-reltype,
        int_number_assignment    TYPE bapiflag-bapiflag,
        behave_when_error        TYPE bapiflag-bapiflag,
        logic_switch             TYPE bapisdls,
        testrun                  TYPE bapiflag-bapiflag,
        convert                  TYPE bapiflag-bapiflag,
      END OF ty_quotation_request,

      BEGIN OF ty_quotation_response,
        salesdocument TYPE bapivbeln-vbeln,
        return_table  TYPE TABLE OF zst_sd_bapireturn WITH DEFAULT KEY,
      END OF ty_quotation_response.

    METHODS constructor
      IMPORTING
        io_validator       TYPE REF TO zif_sd_quotation_validator
        io_converter       TYPE REF TO zif_sd_data_converter
        io_bapi_wrapper    TYPE REF TO zif_sd_bapi_wrapper
        io_sf_id_manager   TYPE REF TO zif_sd_salesforce_id_manager.

    METHODS create_quotation
      IMPORTING
        is_request              TYPE ty_quotation_request
        it_items_in             TYPE ztt_sd_bapisditm
        it_items_inx            TYPE STANDARD TABLE
        it_partners             TYPE STANDARD TABLE
        it_schedules_in         TYPE ztt_sd_bapischdl
        it_schedules_inx        TYPE STANDARD TABLE
        it_conditions_in        TYPE ztt_sd_bapicond
        it_conditions_inx       TYPE STANDARD TABLE
        it_cfgs_ref             TYPE STANDARD TABLE
        it_cfgs_inst            TYPE STANDARD TABLE
        it_cfgs_part_of         TYPE STANDARD TABLE
        it_cfgs_value           TYPE STANDARD TABLE
        it_cfgs_blob            TYPE STANDARD TABLE
        it_cfgs_vk              TYPE STANDARD TABLE
        it_cfgs_refinst         TYPE STANDARD TABLE
        it_keys                 TYPE STANDARD TABLE
        it_text                 TYPE STANDARD TABLE
        it_partneraddresses     TYPE STANDARD TABLE
      EXPORTING
        es_response             TYPE ty_quotation_response.

  PRIVATE SECTION.
    DATA:
      mo_validator     TYPE REF TO zif_sd_quotation_validator,
      mo_converter     TYPE REF TO zif_sd_data_converter,
      mo_bapi_wrapper  TYPE REF TO zif_sd_bapi_wrapper,
      mo_sf_id_manager TYPE REF TO zif_sd_salesforce_id_manager.

ENDCLASS.

CLASS zcl_sd_quotation_creator IMPLEMENTATION.

  METHOD constructor.
    mo_validator     = io_validator.
    mo_converter     = io_converter.
    mo_bapi_wrapper  = io_bapi_wrapper.
    mo_sf_id_manager = io_sf_id_manager.
  ENDMETHOD.

  METHOD create_quotation.
    " Single Responsibility: Orchestrate the quotation creation process
    DATA: lv_salesdocument TYPE bapivbeln-vbeln,
          lt_return        TYPE TABLE OF bapiret2.

    " 1. Validate Salesforce ID (Dependency Inversion)
    IF mo_validator->validate_salesforce_id(
         is_request-quotation_header_in-zzsalesforce_id ) = abap_false.
      " Add error to response
      RETURN.
    ENDIF.

    " 2. Convert and prepare data (Single Responsibility)
    mo_converter->convert_partners( CHANGING ct_partners = it_partners ).
    mo_converter->convert_items( CHANGING ct_items = it_items_in ).
    mo_converter->convert_conditions( CHANGING ct_conditions = it_conditions_in ).

    " 3. Call BAPI (Dependency Inversion)
    mo_bapi_wrapper->create_quotation(
      EXPORTING
        is_request       = is_request
        it_items_in      = it_items_in
        it_partners      = it_partners
        it_schedules_in  = it_schedules_in
        it_conditions_in = it_conditions_in
      IMPORTING
        ev_salesdocument = lv_salesdocument
        et_return        = lt_return ).

    " 4. Persist Salesforce ID (Single Responsibility)
    IF line_exists( lt_return[ type = 'E' ] ) = abap_false.
      mo_sf_id_manager->persist_salesforce_id(
        iv_salesforce_id = is_request-quotation_header_in-zzsalesforce_id
        iv_salesdocument = lv_salesdocument ).

      mo_bapi_wrapper->commit_transaction( ).
    ENDIF.

    " 5. Build response
    es_response-salesdocument = lv_salesdocument.
    es_response-return_table  = CORRESPONDING #( lt_return ).

  ENDMETHOD.

ENDCLASS.
