CLASS zcl_sd_data_converter DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_data_converter.

    METHODS constructor
      IMPORTING
        io_shipping_point_calculator TYPE REF TO zif_sd_shipping_point_calc OPTIONAL.

  PRIVATE SECTION.
    DATA:
      mo_shipping_point_calc TYPE REF TO zif_sd_shipping_point_calc.

    METHODS convert_alpha_input
      CHANGING
        cv_value TYPE any.

    METHODS convert_unit_input
      CHANGING
        cv_unit TYPE any.

    METHODS convert_unit_output
      CHANGING
        cv_unit TYPE any.

ENDCLASS.

CLASS zcl_sd_data_converter IMPLEMENTATION.

  METHOD constructor.
    mo_shipping_point_calc = io_shipping_point_calculator.
  ENDMETHOD.

  METHOD zif_sd_data_converter~convert_partners.
    " Single Responsibility: Convert partner numbers
    FIELD-SYMBOLS: <fs_partner> TYPE any,
                   <fv_partn_numb> TYPE any.

    LOOP AT ct_partners ASSIGNING <fs_partner>.
      ASSIGN COMPONENT 'PARTN_NUMB' OF STRUCTURE <fs_partner> TO <fv_partn_numb>.
      IF sy-subrc = 0.
        convert_alpha_input( CHANGING cv_value = <fv_partn_numb> ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_sd_data_converter~convert_items.
    " Single Responsibility: Convert item data
    FIELD-SYMBOLS: <fs_item> TYPE any.

    LOOP AT ct_items ASSIGNING <fs_item>.
      " Convert units
      ASSIGN COMPONENT 'TARGET_QU' OF STRUCTURE <fs_item> TO FIELD-SYMBOL(<fv_target_qu>).
      IF sy-subrc = 0 AND <fv_target_qu> IS NOT INITIAL.
        convert_unit_input( CHANGING cv_unit = <fv_target_qu> ).
      ENDIF.

      ASSIGN COMPONENT 'SALES_UNIT' OF STRUCTURE <fs_item> TO FIELD-SYMBOL(<fv_sales_unit>).
      IF sy-subrc = 0 AND <fv_sales_unit> IS NOT INITIAL.
        convert_unit_input( CHANGING cv_unit = <fv_sales_unit> ).
      ENDIF.

      " Calculate shipping point if calculator is provided (Open/Closed Principle)
      IF mo_shipping_point_calc IS BOUND.
        ASSIGN COMPONENT 'SHIP_POINT' OF STRUCTURE <fs_item> TO FIELD-SYMBOL(<fv_ship_point>).
        IF sy-subrc = 0.
          " Shipping point calculation logic would go here
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_sd_data_converter~convert_conditions.
    " Single Responsibility: Convert condition data
    FIELD-SYMBOLS: <fs_condition> TYPE any.

    LOOP AT ct_conditions ASSIGNING <fs_condition>.
      ASSIGN COMPONENT 'COND_UNIT' OF STRUCTURE <fs_condition> TO FIELD-SYMBOL(<fv_cond_unit>).
      IF sy-subrc = 0 AND <fv_cond_unit> IS NOT INITIAL.
        convert_unit_input( CHANGING cv_unit = <fv_cond_unit> ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_sd_data_converter~convert_schedules.
    " Single Responsibility: Convert schedule data
    " Implementation for schedule conversion if needed
  ENDMETHOD.

  METHOD convert_alpha_input.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = cv_value
      IMPORTING
        output = cv_value.
  ENDMETHOD.

  METHOD convert_unit_input.
    CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
      EXPORTING
        input          = cv_unit
      IMPORTING
        output         = cv_unit
      EXCEPTIONS
        unit_not_found = 1
        OTHERS         = 2.
  ENDMETHOD.

  METHOD convert_unit_output.
    CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
      EXPORTING
        input          = cv_unit
      IMPORTING
        output         = cv_unit
      EXCEPTIONS
        unit_not_found = 1
        OTHERS         = 2.
  ENDMETHOD.

ENDCLASS.
