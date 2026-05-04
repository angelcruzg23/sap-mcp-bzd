INTERFACE zif_sd_quotation_validator
  PUBLIC.

  " Interface Segregation Principle: Specific interface for validation
  METHODS validate_salesforce_id
    IMPORTING
      iv_salesforce_id TYPE zzsalesforce_id
    RETURNING
      VALUE(rv_valid)  TYPE abap_bool.

  METHODS get_validation_messages
    RETURNING
      VALUE(rt_messages) TYPE bapiret2_t.

ENDINTERFACE.
