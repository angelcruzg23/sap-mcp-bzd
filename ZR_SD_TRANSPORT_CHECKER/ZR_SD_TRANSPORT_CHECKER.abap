*&---------------------------------------------------------------------*
*& Report ZR_SD_TRANSPORT_CHECKER
*&---------------------------------------------------------------------*
*& POC: Validador de consistencia de Órdenes de Transporte
*& Verifica que todos los objetos y sus dependencias estén incluidos
*& en la OT antes de transportar a BZP/PRD.
*&
*& Autor: Amrize BP - L2C Team
*& Fecha: 2026-04-28
*&---------------------------------------------------------------------*
REPORT zr_sd_transport_checker.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
PARAMETERS: p_trkorr TYPE trkorr OBLIGATORY.

*----------------------------------------------------------------------*
* Types
*----------------------------------------------------------------------*
TYPES: BEGIN OF gty_check_result,
         icon      TYPE icon_d,
         pgmid     TYPE pgmid,
         object    TYPE trobjtype,
         obj_name  TYPE trobj_name,
         status    TYPE char1,       " G=Green, Y=Yellow, R=Red
         message   TYPE string,
         category  TYPE string,
       END OF gty_check_result,
       gty_check_result_t TYPE STANDARD TABLE OF gty_check_result
                          WITH EMPTY KEY.

TYPES: BEGIN OF gty_obj_entry,
         pgmid    TYPE pgmid,
         object   TYPE trobjtype,
         obj_name TYPE trobj_name,
       END OF gty_obj_entry,
       gty_obj_entry_t TYPE STANDARD TABLE OF gty_obj_entry
                       WITH EMPTY KEY.

*----------------------------------------------------------------------*
* Class Definition
*----------------------------------------------------------------------*
CLASS lcl_transport_checker DEFINITION.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_trkorr TYPE trkorr.
    METHODS execute.

  PRIVATE SECTION.
    DATA mv_trkorr        TYPE trkorr.
    DATA mv_ot_owner      TYPE as4user.
    DATA mv_ot_status     TYPE trstatus.
    DATA mv_ot_text       TYPE as4text.
    DATA mt_results        TYPE gty_check_result_t.
    DATA mt_all_ot_objects TYPE gty_obj_entry_t.

    METHODS validate_ot_exists
      RETURNING VALUE(rv_ok) TYPE abap_bool.
    METHODS read_ot_objects.
    METHODS check_includes_present.
    METHODS check_fugr_completeness.
    METHODS check_inactive_objects.
    METHODS check_cross_references.
    METHODS check_locked_objects.
    METHODS add_result
      IMPORTING iv_pgmid    TYPE pgmid
                iv_object   TYPE trobjtype
                iv_obj_name TYPE trobj_name
                iv_status   TYPE char1
                iv_message  TYPE string
                iv_category TYPE string.
    METHODS display_results.
    METHODS is_object_in_ot
      IMPORTING iv_pgmid    TYPE pgmid
                iv_object   TYPE trobjtype
                iv_obj_name TYPE trobj_name
      RETURNING VALUE(rv_found) TYPE abap_bool.
ENDCLASS.

*----------------------------------------------------------------------*
* Class Implementation
*----------------------------------------------------------------------*
CLASS lcl_transport_checker IMPLEMENTATION.

  METHOD constructor.
    mv_trkorr = iv_trkorr.
  ENDMETHOD.

  METHOD execute.
    " Step 1: Validate OT exists
    IF validate_ot_exists( ) = abap_false.
      display_results( ).
      RETURN.
    ENDIF.

    " Step 2: Read all objects from OT (including tasks)
    read_ot_objects( ).

    IF mt_all_ot_objects IS INITIAL.
      add_result(
        iv_pgmid    = 'R3TR'
        iv_object   = 'PROG'
        iv_obj_name = CONV #( mv_trkorr )
        iv_status   = 'R'
        iv_message  = 'La OT no contiene objetos'
        iv_category = 'GENERAL' ).
      display_results( ).
      RETURN.
    ENDIF.

    " Step 3: Run all checks
    check_includes_present( ).
    check_fugr_completeness( ).
    check_inactive_objects( ).
    check_cross_references( ).
    check_locked_objects( ).

    " Step 4: Add green status for objects without issues
    LOOP AT mt_all_ot_objects INTO DATA(ls_obj).
      DATA(lv_has_issue) = abap_false.
      LOOP AT mt_results TRANSPORTING NO FIELDS
        WHERE pgmid    = ls_obj-pgmid
          AND object   = ls_obj-object
          AND obj_name = ls_obj-obj_name
          AND status  <> 'G'.
        lv_has_issue = abap_true.
        EXIT.
      ENDLOOP.
      IF lv_has_issue = abap_false.
        READ TABLE mt_results TRANSPORTING NO FIELDS
          WITH KEY pgmid    = ls_obj-pgmid
                   object   = ls_obj-object
                   obj_name = ls_obj-obj_name.
        IF sy-subrc <> 0.
          add_result(
            iv_pgmid    = ls_obj-pgmid
            iv_object   = ls_obj-object
            iv_obj_name = ls_obj-obj_name
            iv_status   = 'G'
            iv_message  = 'OK — sin problemas detectados'
            iv_category = 'GENERAL' ).
        ENDIF.
      ENDIF.
    ENDLOOP.

    " Step 5: Display
    display_results( ).
  ENDMETHOD.

  METHOD validate_ot_exists.
    SELECT SINGLE as4user, trstatus, as4text
      FROM e070
      INTO (@mv_ot_owner, @mv_ot_status, @mv_ot_text)
      WHERE trkorr = @mv_trkorr.
    IF sy-subrc <> 0.
      add_result(
        iv_pgmid    = 'R3TR'
        iv_object   = 'PROG'
        iv_obj_name = CONV #( mv_trkorr )
        iv_status   = 'R'
        iv_message  = |OT { mv_trkorr } no existe en el sistema|
        iv_category = 'GENERAL' ).
      rv_ok = abap_false.
    ELSE.
      rv_ok = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD read_ot_objects.
    DATA lt_tasks TYPE STANDARD TABLE OF trkorr.

    " Read tasks under this request
    SELECT trkorr FROM e070
      INTO TABLE @lt_tasks
      WHERE strkorr = @mv_trkorr.

    " Add the request itself
    APPEND mv_trkorr TO lt_tasks.

    " Read all objects from request + tasks
    IF lt_tasks IS NOT INITIAL.
      SELECT pgmid, object, obj_name
        FROM e071
        INTO TABLE @mt_all_ot_objects
        FOR ALL ENTRIES IN @lt_tasks
        WHERE trkorr = @lt_tasks-table_line.

      SORT mt_all_ot_objects BY pgmid object obj_name.
      DELETE ADJACENT DUPLICATES FROM mt_all_ot_objects
        COMPARING pgmid object obj_name.
    ENDIF.
  ENDMETHOD.

  METHOD check_includes_present.
    DATA lt_includes TYPE STANDARD TABLE OF progname.

    LOOP AT mt_all_ot_objects INTO DATA(ls_obj)
      WHERE ( object = 'PROG' OR object = 'REPS' ).

      CLEAR lt_includes.
      SELECT master FROM d010sinf
        INTO TABLE @lt_includes
        WHERE prog = @ls_obj-obj_name.

      LOOP AT lt_includes INTO DATA(lv_include).
        " Skip SAP standard includes
        IF lv_include(1) <> 'Z' AND lv_include(1) <> 'Y'.
          CONTINUE.
        ENDIF.

        " Check if include is in the OT (as R3TR REPS or LIMU REPS)
        IF is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'REPS'
                            iv_obj_name = CONV #( lv_include ) ) = abap_false
          AND is_object_in_ot( iv_pgmid = 'LIMU' iv_object = 'REPS'
                               iv_obj_name = CONV #( lv_include ) ) = abap_false
          AND is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'PROG'
                               iv_obj_name = CONV #( lv_include ) ) = abap_false.

          " Check if include exists in the system already
          SELECT SINGLE name FROM trdir
            INTO @DATA(lv_exists)
            WHERE name = @lv_include.
          IF sy-subrc = 0.
            add_result(
              iv_pgmid    = ls_obj-pgmid
              iv_object   = ls_obj-object
              iv_obj_name = ls_obj-obj_name
              iv_status   = 'Y'
              iv_message  = |Include { lv_include } no está en la OT (existe en BZD, verificar si ya está en destino)|
              iv_category = 'INCLUDE' ).
          ELSE.
            add_result(
              iv_pgmid    = ls_obj-pgmid
              iv_object   = ls_obj-object
              iv_obj_name = ls_obj-obj_name
              iv_status   = 'R'
              iv_message  = |Include { lv_include } NO existe en BZD y NO está en la OT — FALTANTE|
              iv_category = 'INCLUDE' ).
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD check_fugr_completeness.
    " For FUNC objects in the OT, check if other FMs in the same group
    " were recently modified but are not included
    DATA lt_func_names TYPE STANDARD TABLE OF rs38l_fnam.

    LOOP AT mt_all_ot_objects INTO DATA(ls_obj)
      WHERE object = 'FUGR'.

      DATA(lv_fugr_name) = ls_obj-obj_name.

      " Get all function modules in this group
      CLEAR lt_func_names.
      SELECT funcname FROM tfdir
        INTO TABLE @lt_func_names
        WHERE pname = @( |SAPL{ lv_fugr_name }| ).

      LOOP AT lt_func_names INTO DATA(lv_func).
        IF is_object_in_ot( iv_pgmid = 'LIMU' iv_object = 'FUNC'
                            iv_obj_name = CONV #( lv_func ) ) = abap_false
          AND is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'FUNC'
                               iv_obj_name = CONV #( lv_func ) ) = abap_false.
          add_result(
            iv_pgmid    = ls_obj-pgmid
            iv_object   = ls_obj-object
            iv_obj_name = ls_obj-obj_name
            iv_status   = 'Y'
            iv_message  = |FM { lv_func } del grupo { lv_fugr_name } no está en la OT (verificar si fue modificado)|
            iv_category = 'FUGR' ).
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD check_inactive_objects.
    LOOP AT mt_all_ot_objects INTO DATA(ls_obj).
      SELECT SINGLE obj_name FROM dwinactiv
        INTO @DATA(lv_dummy)
        WHERE obj_name = @ls_obj-obj_name
          AND obj_type = @ls_obj-object.
      IF sy-subrc = 0.
        add_result(
          iv_pgmid    = ls_obj-pgmid
          iv_object   = ls_obj-object
          iv_obj_name = ls_obj-obj_name
          iv_status   = 'R'
          iv_message  = |Objeto INACTIVO — debe activarse antes de transportar|
          iv_category = 'ACTIVATION' ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD check_cross_references.
    DATA lt_where_used TYPE STANDARD TABLE OF wbcrossgt.

    LOOP AT mt_all_ot_objects INTO DATA(ls_obj)
      WHERE pgmid = 'R3TR'
        AND ( object = 'PROG' OR object = 'CLAS'
              OR object = 'FUGR' OR object = 'REPS' ).

      CLEAR lt_where_used.
      SELECT otype, name, include
        FROM wbcrossgt
        INTO TABLE @lt_where_used
        WHERE include = @ls_obj-obj_name.

      LOOP AT lt_where_used INTO DATA(ls_ref).
        " Only check Z/Y custom objects
        IF ls_ref-name IS INITIAL
          OR ( ls_ref-name(1) <> 'Z' AND ls_ref-name(1) <> 'Y' ).
          CONTINUE.
        ENDIF.
        IF ls_ref-name = ls_obj-obj_name.
          CONTINUE.
        ENDIF.

        " Check if referenced object is in another open OT
        DATA lv_other_ot TYPE trkorr.
        DATA lv_other_status TYPE trstatus.
        CLEAR: lv_other_ot, lv_other_status.

        SELECT SINGLE a~trkorr, b~trstatus
          FROM e071 AS a
          INNER JOIN e070 AS b ON a~trkorr = b~trkorr
          INTO (@lv_other_ot, @lv_other_status)
          WHERE a~obj_name = @ls_ref-name
            AND a~trkorr <> @mv_trkorr
            AND b~trstatus IN ('D', 'L').
        IF sy-subrc = 0.
          add_result(
            iv_pgmid    = ls_obj-pgmid
            iv_object   = ls_obj-object
            iv_obj_name = ls_obj-obj_name
            iv_status   = 'Y'
            iv_message  = |Referencia { ls_ref-name } está en OT abierta { lv_other_ot } — verificar secuencia|
            iv_category = 'XREF' ).
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD check_locked_objects.
    LOOP AT mt_all_ot_objects INTO DATA(ls_obj).
      DATA lv_lock_ot TYPE trkorr.
      DATA lv_lock_user TYPE as4user.
      DATA lv_lock_status TYPE trstatus.
      CLEAR: lv_lock_ot, lv_lock_user, lv_lock_status.

      SELECT SINGLE a~trkorr, b~as4user, b~trstatus
        FROM e071 AS a
        INNER JOIN e070 AS b ON a~trkorr = b~trkorr
        INTO (@lv_lock_ot, @lv_lock_user, @lv_lock_status)
        WHERE a~pgmid    = @ls_obj-pgmid
          AND a~object   = @ls_obj-object
          AND a~obj_name = @ls_obj-obj_name
          AND a~trkorr  <> @mv_trkorr
          AND b~trstatus <> 'R'
          AND b~as4user <> @sy-uname.
      IF sy-subrc = 0.
        add_result(
          iv_pgmid    = ls_obj-pgmid
          iv_object   = ls_obj-object
          iv_obj_name = ls_obj-obj_name
          iv_status   = 'Y'
          iv_message  = |Objeto también en OT { lv_lock_ot } de { lv_lock_user } (status { lv_lock_status })|
          iv_category = 'LOCK' ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD is_object_in_ot.
    READ TABLE mt_all_ot_objects TRANSPORTING NO FIELDS
      WITH KEY pgmid    = iv_pgmid
               object   = iv_object
               obj_name = iv_obj_name.
    rv_found = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD add_result.
    DATA(lv_icon) = SWITCH icon_d(
      iv_status
      WHEN 'G' THEN icon_green_light
      WHEN 'Y' THEN icon_yellow_light
      WHEN 'R' THEN icon_led_red ).

    APPEND VALUE gty_check_result(
      icon      = lv_icon
      pgmid     = iv_pgmid
      object    = iv_object
      obj_name  = iv_obj_name
      status    = iv_status
      message   = iv_message
      category  = iv_category
    ) TO mt_results.
  ENDMETHOD.

  METHOD display_results.
    SORT mt_results BY status DESCENDING pgmid object obj_name.

    DATA lo_alv TYPE REF TO cl_salv_table.

    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = lo_alv
          CHANGING  t_table      = mt_results ).

        DATA(lo_columns) = lo_alv->get_columns( ).
        lo_columns->set_optimize( abap_true ).

        DATA lo_column TYPE REF TO cl_salv_column_table.

        lo_column ?= lo_columns->get_column( 'ICON' ).
        lo_column->set_short_text( 'Status' ).
        lo_column->set_medium_text( 'Status' ).
        lo_column->set_long_text( 'Status' ).

        lo_column ?= lo_columns->get_column( 'PGMID' ).
        lo_column->set_short_text( 'PGMID' ).

        lo_column ?= lo_columns->get_column( 'OBJECT' ).
        lo_column->set_short_text( 'Tipo Obj' ).
        lo_column->set_medium_text( 'Tipo Objeto' ).

        lo_column ?= lo_columns->get_column( 'OBJ_NAME' ).
        lo_column->set_short_text( 'Objeto' ).
        lo_column->set_medium_text( 'Nombre Objeto' ).
        lo_column->set_long_text( 'Nombre del Objeto' ).

        lo_column ?= lo_columns->get_column( 'STATUS' ).
        lo_column->set_visible( abap_false ).

        lo_column ?= lo_columns->get_column( 'MESSAGE' ).
        lo_column->set_short_text( 'Mensaje' ).
        lo_column->set_medium_text( 'Mensaje' ).
        lo_column->set_long_text( 'Mensaje de Validación' ).

        lo_column ?= lo_columns->get_column( 'CATEGORY' ).
        lo_column->set_short_text( 'Categoría' ).
        lo_column->set_medium_text( 'Categoría Check' ).

        DATA(lo_display) = lo_alv->get_display_settings( ).
        lo_display->set_list_header(
          |Consistencia OT: { mv_trkorr } — { mv_ot_text }| ).
        lo_display->set_striped_pattern( abap_true ).

        DATA(lo_functions) = lo_alv->get_functions( ).
        lo_functions->set_all( abap_true ).

        DATA(lv_red)    = REDUCE i( INIT x = 0
                            FOR ls IN mt_results WHERE ( status = 'R' )
                            NEXT x = x + 1 ).
        DATA(lv_yellow) = REDUCE i( INIT x = 0
                            FOR ls IN mt_results WHERE ( status = 'Y' )
                            NEXT x = x + 1 ).
        DATA(lv_green)  = REDUCE i( INIT x = 0
                            FOR ls IN mt_results WHERE ( status = 'G' )
                            NEXT x = x + 1 ).

        DATA lo_header TYPE REF TO cl_salv_form_layout_grid.
        CREATE OBJECT lo_header.
        lo_header->create_label( row = 1 column = 1
          text = |OT: { mv_trkorr }| ).
        lo_header->create_label( row = 1 column = 2
          text = |Owner: { mv_ot_owner }| ).
        lo_header->create_label( row = 1 column = 3
          text = |Status OT: { mv_ot_status }| ).
        lo_header->create_label( row = 2 column = 1
          text = |Objetos: { lines( mt_all_ot_objects ) }| ).
        lo_header->create_label( row = 2 column = 2
          text = |Errores: { lv_red } / Warnings: { lv_yellow } / OK: { lv_green }| ).

        lo_alv->set_top_of_list( lo_header ).
        lo_alv->display( ).

      CATCH cx_salv_msg cx_salv_not_found INTO DATA(lx_err).
        WRITE: / |Error ALV: { lx_err->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Main Program
*----------------------------------------------------------------------*
START-OF-SELECTION.
  NEW lcl_transport_checker( p_trkorr )->execute( ).
