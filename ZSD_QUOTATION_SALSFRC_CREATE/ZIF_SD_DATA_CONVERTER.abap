INTERFACE zif_sd_data_converter
  PUBLIC.

  " Interface Segregation Principle: Specific interface for data conversion
  METHODS convert_partners
    CHANGING
      ct_partners TYPE STANDARD TABLE.

  METHODS convert_items
    CHANGING
      ct_items TYPE ztt_sd_bapisditm.

  METHODS convert_conditions
    CHANGING
      ct_conditions TYPE ztt_sd_bapicond.

  METHODS convert_schedules
    CHANGING
      ct_schedules TYPE ztt_sd_bapischdl.

ENDINTERFACE.
