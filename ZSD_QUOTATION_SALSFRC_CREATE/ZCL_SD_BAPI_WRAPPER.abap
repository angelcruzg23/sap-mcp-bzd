CLASS zcl_sd_bapi_wrapper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_bapi_wrapper.

  PRIVATE SECTION.
    METHODS build_extension_structures
      IMPORTING
        is_header           TYPE zsd_bapisdhd1
        it_items            TYPE ztt_sd_bapisditm
        iv_salesdocument    TYPE bapivbeln-vbeln
      RETURNING
        VALUE(rt_extension) TYPE TABLE OF bapiparex.

ENDCLASS.

CLASS zcl_sd_bapi_wrapper IMPLEMENTATION.

  METHOD zif_sd_bapi_wrapper~create_quotation.
    " Single Responsibility: Wrap BAPI call
    DATA: lt_extensionin           TYPE TABLE OF bapiparex,
          lt_quotation_items_in    TYPE STANDARD TABLE OF bapisditm,
          lt_quotation_schedules   TYPE STANDARD TABLE OF bapischdl,
          lt_quotation_conditions  TYPE STANDARD TABLE OF bapicond.

    " Build extension structures for custom fields
    lt_extensionin = build_extension_structures(
      is_header        = is_request-quotation_header_in
      it_items         = it_items_in
      iv_salesdocument = ev_salesdocument ).

    " Convert to standard BAPI structures
    lt_quotation_items_in    = CORRESPONDING #( it_items_in ).
    lt_quotation_schedules   = CORRESPONDING #( it_schedules_in ).
    lt_quotation_conditions  = CORRESPONDING #( it_conditions_in ).

    " Set parameters for BAPI behavior
    SET PARAMETER ID 'ZSD_SHIPPING_TYPE' FIELD is_request-quotation_header_in-ship_type.
    SET PARAMETER ID 'ZSD_ENVIAR_IDOC' FIELD abap_true.

    " Call standard BAPI
    CALL FUNCTION 'BAPI_QUOTATION_CREATEFROMDATA2'
      EXPORTING
        salesdocumentin         = is_request-salesdocumentin
        quotation_header_in     = is_request-quotation_header_in
        quotation_header_inx    = is_request-quotation_header_inx
        sender                  = is_request-sender
        binary_relationshiptype = is_request-binary_relationshiptype
        int_number_assignment   = is_request-int_number_assignment
        behave_when_error       = is_request-behave_when_error
        logic_switch            = is_request-logic_switch
        testrun                 = is_request-testrun
        convert                 = is_request-convert
      IMPORTING
        salesdocument           = ev_salesdocument
      TABLES
        return                  = et_return
        quotation_items_in      = lt_quotation_items_in
        quotation_partners      = it_partners
        quotation_schedules_in  = lt_quotation_schedules
        quotation_conditions_in = lt_quotation_conditions
        extensionin             = lt_extensionin.

    " Reset parameters
    SET PARAMETER ID 'ZSD_ENVIAR_IDOC' FIELD abap_false.
    SET PARAMETER ID 'ZSD_SHIPPING_TYPE' FIELD space.

  ENDMETHOD.

  METHOD zif_sd_bapi_wrapper~commit_transaction.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

  METHOD zif_sd_bapi_wrapper~rollback_transaction.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ENDMETHOD.

  METHOD build_extension_structures.
    " Single Responsibility: Build BAPI extension structures
    DATA: ls_extensionin TYPE bapiparex,
          ls_bape_vbak   TYPE bape_vbak,
          ls_bape_vbakx  TYPE bape_vbakx,
          ls_bape_vbap   TYPE bape_vbap,
          ls_bape_vbapx  TYPE bape_vbapx.

    " Header extension
    ls_bape_vbak-zzsalesforce_id  = is_header-zzsalesforce_id.
    ls_bape_vbakx-zzsalesforce_id = abap_true.
    ls_extensionin-structure      = 'BAPE_VBAK'.
    ls_extensionin+30             = ls_bape_vbak.
    APPEND ls_extensionin TO rt_extension.

    CLEAR ls_extensionin.
    ls_extensionin-structure  = 'BAPE_VBAKX'.
    ls_extensionin-valuepart1 = ls_bape_vbakx.
    APPEND ls_extensionin TO rt_extension.

    " Item extensions
    LOOP AT it_items INTO DATA(ls_item) WHERE zzsalesforce_id IS NOT INITIAL.
      CLEAR: ls_bape_vbap, ls_bape_vbapx, ls_extensionin.
      ls_bape_vbap-vbeln            = iv_salesdocument.
      ls_bape_vbapx-vbeln           = iv_salesdocument.
      ls_bape_vbap-posnr            = ls_item-itm_number.
      ls_bape_vbapx-posnr           = ls_item-itm_number.
      ls_bape_vbap-zzsalesforce_id  = ls_item-zzsalesforce_id.
      ls_bape_vbapx-zzsalesforce_id = abap_true.

      ls_extensionin-structure = 'BAPE_VBAP'.
      ls_extensionin+30        = ls_bape_vbap.
      APPEND ls_extensionin TO rt_extension.

      CLEAR ls_extensionin.
      ls_extensionin-structure = 'BAPE_VBAPX'.
      ls_extensionin+30        = ls_bape_vbapx.
      APPEND ls_extensionin TO rt_extension.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
