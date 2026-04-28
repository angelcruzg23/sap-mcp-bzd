FUNCTION zsd_quotation_salsfrc_create_v2.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SALESDOCUMENTIN) LIKE  BAPIVBELN-VBELN OPTIONAL
*"     VALUE(QUOTATION_HEADER_IN) LIKE  ZSD_BAPISDHD1
*"     VALUE(QUOTATION_HEADER_INX) LIKE  BAPISDHD1X OPTIONAL
*"     VALUE(SENDER) LIKE  BAPI_SENDER OPTIONAL
*"     VALUE(BINARY_RELATIONSHIPTYPE) LIKE  BAPIRELTYPE-RELTYPE
*"       DEFAULT SPACE
*"     VALUE(INT_NUMBER_ASSIGNMENT) LIKE  BAPIFLAG-BAPIFLAG
*"       DEFAULT SPACE
*"     VALUE(BEHAVE_WHEN_ERROR) LIKE  BAPIFLAG-BAPIFLAG DEFAULT SPACE
*"     VALUE(LOGIC_SWITCH) LIKE  BAPISDLS OPTIONAL
*"     VALUE(TESTRUN) LIKE  BAPIFLAG-BAPIFLAG OPTIONAL
*"     VALUE(CONVERT) LIKE  BAPIFLAG-BAPIFLAG DEFAULT SPACE
*"  EXPORTING
*"     VALUE(SALESDOCUMENT) LIKE  BAPIVBELN-VBELN
*"  TABLES
*"      QUOTATION_ITEMS_IN LIKE  ZST_SD_BAPISDITM OPTIONAL
*"      QUOTATION_ITEMS_INX LIKE  BAPISDITMX OPTIONAL
*"      QUOTATION_PARTNERS LIKE  BAPIPARNR
*"      QUOTATION_SCHEDULES_IN LIKE  ZST_SD_BAPISCHDL OPTIONAL
*"      QUOTATION_SCHEDULES_INX LIKE  BAPISCHDLX OPTIONAL
*"      QUOTATION_CONDITIONS_IN LIKE  ZST_SD_BAPICOND OPTIONAL
*"      QUOTATION_CONDITIONS_INX LIKE  BAPICONDX OPTIONAL
*"      QUOTATION_CFGS_REF LIKE  BAPICUCFG OPTIONAL
*"      QUOTATION_CFGS_INST LIKE  BAPICUINS OPTIONAL
*"      QUOTATION_CFGS_PART_OF LIKE  BAPICUPRT OPTIONAL
*"      QUOTATION_CFGS_VALUE LIKE  BAPICUVAL OPTIONAL
*"      QUOTATION_CFGS_BLOB LIKE  BAPICUBLB OPTIONAL
*"      QUOTATION_CFGS_VK LIKE  BAPICUVK OPTIONAL
*"      QUOTATION_CFGS_REFINST LIKE  BAPICUREF OPTIONAL
*"      QUOTATION_KEYS LIKE  BAPISDKEY OPTIONAL
*"      QUOTATION_TEXT LIKE  BAPISDTEXT OPTIONAL
*"      PARTNERADDRESSES LIKE  BAPIADDR1 OPTIONAL
*"      E_RETURN_T LIKE  ZST_SD_BAPIRETURN OPTIONAL
*"----------------------------------------------------------------------
*" SOLID Refactored Version
*" Created by: Kiro AI Assistant
*" Date: 2026-03-10
*"
*" Principles Applied:
*" - Single Responsibility: Each class has one reason to change
*" - Open/Closed: Open for extension, closed for modification
*" - Liskov Substitution: Interfaces can be substituted with implementations
*" - Interface Segregation: Specific interfaces for specific purposes
*" - Dependency Inversion: Depend on abstractions, not concretions
*"----------------------------------------------------------------------

  DATA: lo_creator       TYPE REF TO zcl_sd_quotation_creator,
        lo_validator     TYPE REF TO zif_sd_quotation_validator,
        lo_converter     TYPE REF TO zif_sd_data_converter,
        lo_bapi_wrapper  TYPE REF TO zif_sd_bapi_wrapper,
        lo_sf_id_manager TYPE REF TO zif_sd_salesforce_id_manager,
        ls_request       TYPE zcl_sd_quotation_creator=>ty_quotation_request,
        ls_response      TYPE zcl_sd_quotation_creator=>ty_quotation_response.

  " Dependency Injection: Create dependencies
  lo_sf_id_manager = NEW zcl_sd_salesforce_id_manager( ).
  lo_validator     = NEW zcl_sd_quotation_validator( lo_sf_id_manager ).
  lo_converter     = NEW zcl_sd_data_converter( ).
  lo_bapi_wrapper  = NEW zcl_sd_bapi_wrapper( ).

  " Create main orchestrator with injected dependencies
  lo_creator = NEW zcl_sd_quotation_creator(
    io_validator     = lo_validator
    io_converter     = lo_converter
    io_bapi_wrapper  = lo_bapi_wrapper
    io_sf_id_manager = lo_sf_id_manager ).

  " Build request structure
  ls_request = VALUE #(
    salesdocumentin         = salesdocumentin
    quotation_header_in     = quotation_header_in
    quotation_header_inx    = quotation_header_inx
    sender                  = sender
    binary_relationshiptype = binary_relationshiptype
    int_number_assignment   = int_number_assignment
    behave_when_error       = behave_when_error
    logic_switch            = logic_switch
    testrun                 = testrun
    convert                 = convert ).

  " Execute quotation creation (Single method call - clean interface)
  lo_creator->create_quotation(
    EXPORTING
      is_request          = ls_request
      it_items_in         = quotation_items_in[]
      it_items_inx        = quotation_items_inx[]
      it_partners         = quotation_partners[]
      it_schedules_in     = quotation_schedules_in[]
      it_schedules_inx    = quotation_schedules_inx[]
      it_conditions_in    = quotation_conditions_in[]
      it_conditions_inx   = quotation_conditions_inx[]
      it_cfgs_ref         = quotation_cfgs_ref[]
      it_cfgs_inst        = quotation_cfgs_inst[]
      it_cfgs_part_of     = quotation_cfgs_part_of[]
      it_cfgs_value       = quotation_cfgs_value[]
      it_cfgs_blob        = quotation_cfgs_blob[]
      it_cfgs_vk          = quotation_cfgs_vk[]
      it_cfgs_refinst     = quotation_cfgs_refinst[]
      it_keys             = quotation_keys[]
      it_text             = quotation_text[]
      it_partneraddresses = partneraddresses[]
    IMPORTING
      es_response         = ls_response ).

  " Return results
  salesdocument = ls_response-salesdocument.
  e_return_t[]  = ls_response-return_table[].

ENDFUNCTION.
