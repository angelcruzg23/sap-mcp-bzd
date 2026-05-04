*&---------------------------------------------------------------------*
*& Report ZR_SD_TRANSPORT_CHECKER
*&---------------------------------------------------------------------*
*& V5: +verificación cross-system BZP via RFC_READ_TABLE
*&      +fix DDIC_DEP (no filtrar por is_real_ot)
*&      +modo test con checkbox
*& V6: +fix falsos positivos TARGET — clases/interfaces no son tipos DDIC
*&
*& Autor: Amrize BP - L2C Team
*& Fecha: 2026-04-29
*&---------------------------------------------------------------------*
REPORT zr_sd_transport_checker.

PARAMETERS: p_trkorr TYPE trkorr OBLIGATORY.
PARAMETERS: p_rfcdst TYPE rfcdest DEFAULT 'BZPCLNT100'.
PARAMETERS: p_test   TYPE abap_bool AS CHECKBOX DEFAULT abap_false.

TYPES: BEGIN OF gty_check_result,
         icon      TYPE icon_d,
         pgmid     TYPE pgmid,
         object    TYPE trobjtype,
         obj_name  TYPE trobj_name,
         status    TYPE char1,
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

CLASS lcl_transport_checker DEFINITION.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_trkorr TYPE trkorr
                iv_rfcdst TYPE rfcdest
                iv_test   TYPE abap_bool.
    METHODS execute.
  PRIVATE SECTION.
    CONSTANTS gc_ot_prefix  TYPE char4 VALUE 'BZDK'.
    CONSTANTS gc_ot_prefix2 TYPE char4 VALUE 'BZDL'.
    DATA mv_trkorr        TYPE trkorr.
    DATA mv_rfcdst        TYPE rfcdest.
    DATA mv_test_mode     TYPE abap_bool.
    DATA mv_ot_owner      TYPE as4user.
    DATA mv_ot_status     TYPE trstatus.
    DATA mv_ot_text       TYPE as4text.
    DATA mt_results        TYPE gty_check_result_t.
    DATA mt_all_ot_objects TYPE gty_obj_entry_t.
    DATA mt_ddic_to_check  TYPE STANDARD TABLE OF trobj_name.

    METHODS validate_ot_exists RETURNING VALUE(rv_ok) TYPE abap_bool.
    METHODS read_ot_objects.
    METHODS check_includes_present.
    METHODS check_fugr_completeness.
    METHODS check_inactive_objects.
    METHODS check_cross_references.
    METHODS check_locked_objects.
    METHODS check_ddic_dependencies.
    METHODS check_objects_in_target.
    METHODS inject_test_data.
    METHODS is_real_ot IMPORTING iv_trkorr TYPE trkorr
      RETURNING VALUE(rv_real) TYPE abap_bool.
    METHODS exists_in_target
      IMPORTING iv_table TYPE tabname iv_where TYPE string
      RETURNING VALUE(rv_exists) TYPE abap_bool.
    METHODS add_result
      IMPORTING iv_pgmid TYPE pgmid iv_object TYPE trobjtype
                iv_obj_name TYPE trobj_name iv_status TYPE char1
                iv_message TYPE string iv_category TYPE string.
    METHODS display_results.
    METHODS is_object_in_ot
      IMPORTING iv_pgmid TYPE pgmid iv_object TYPE trobjtype
                iv_obj_name TYPE trobj_name
      RETURNING VALUE(rv_found) TYPE abap_bool.
ENDCLASS.

CLASS lcl_transport_checker IMPLEMENTATION.

  METHOD constructor.
    mv_trkorr = iv_trkorr.
    mv_rfcdst = iv_rfcdst.
    mv_test_mode = iv_test.
  ENDMETHOD.

  METHOD execute.
    IF validate_ot_exists( ) = abap_false.
      display_results( ). RETURN.
    ENDIF.
    read_ot_objects( ).
    IF mv_test_mode = abap_true.
      inject_test_data( ).
    ENDIF.
    IF mt_all_ot_objects IS INITIAL.
      add_result( iv_pgmid = 'R3TR' iv_object = 'PROG'
        iv_obj_name = CONV #( mv_trkorr ) iv_status = 'R'
        iv_message = 'La OT no contiene objetos' iv_category = 'GENERAL' ).
      display_results( ). RETURN.
    ENDIF.
    check_includes_present( ).
    check_fugr_completeness( ).
    check_inactive_objects( ).
    check_ddic_dependencies( ).
    check_objects_in_target( ).
    check_cross_references( ).
    check_locked_objects( ).
    " Add green status for objects without issues
    LOOP AT mt_all_ot_objects INTO DATA(ls_obj).
      DATA(lv_has_issue) = abap_false.
      LOOP AT mt_results TRANSPORTING NO FIELDS
        WHERE pgmid = ls_obj-pgmid AND object = ls_obj-object
          AND obj_name = ls_obj-obj_name AND status <> 'G'.
        lv_has_issue = abap_true. EXIT.
      ENDLOOP.
      IF lv_has_issue = abap_false.
        READ TABLE mt_results TRANSPORTING NO FIELDS
          WITH KEY pgmid = ls_obj-pgmid object = ls_obj-object
                   obj_name = ls_obj-obj_name.
        IF sy-subrc <> 0.
          add_result( iv_pgmid = ls_obj-pgmid iv_object = ls_obj-object
            iv_obj_name = ls_obj-obj_name iv_status = 'G'
            iv_message = 'OK — sin problemas detectados' iv_category = 'GENERAL' ).
        ENDIF.
      ENDIF.
    ENDLOOP.
    display_results( ).
  ENDMETHOD.

  METHOD inject_test_data.
    " Test mode: inject fake dependencies to verify error detection
    add_result( iv_pgmid = 'R3TR' iv_object = 'PROG'
      iv_obj_name = 'ZTEST_MODE_ACTIVE'
      iv_status = 'Y'
      iv_message = |MODO TEST ACTIVO — resultados incluyen datos ficticios|
      iv_category = 'TEST' ).
    " Fake missing include
    add_result( iv_pgmid = 'R3TR' iv_object = 'PROG'
      iv_obj_name = CONV #( mv_trkorr )
      iv_status = 'R'
      iv_message = |[TEST] Include ZTEST_INCLUDE_NO_EXISTE NO existe — FALTANTE|
      iv_category = 'INCLUDE' ).
    " Fake missing DDIC type
    add_result( iv_pgmid = 'R3TR' iv_object = 'PROG'
      iv_obj_name = CONV #( mv_trkorr )
      iv_status = 'R'
      iv_message = |[TEST] Tipo DDIC ZTEST_TIPO_NO_EXISTE NO existe — FALTANTE|
      iv_category = 'DDIC_DEP' ).
    " Fake missing object in target
    add_result( iv_pgmid = 'R3TR' iv_object = 'PROG'
      iv_obj_name = CONV #( mv_trkorr )
      iv_status = 'R'
      iv_message = |[TEST] ZTEST_TIPO_NO_EXISTE NO existe en { mv_rfcdst } — fallará al activar|
      iv_category = 'TARGET' ).
  ENDMETHOD.

  METHOD is_real_ot.
    rv_real = xsdbool( iv_trkorr(4) = gc_ot_prefix
                    OR iv_trkorr(4) = gc_ot_prefix2 ).
  ENDMETHOD.

  METHOD validate_ot_exists.
    SELECT SINGLE as4user trstatus FROM e070
      INTO (mv_ot_owner, mv_ot_status) WHERE trkorr = mv_trkorr.
    IF sy-subrc <> 0.
      add_result( iv_pgmid = 'R3TR' iv_object = 'PROG'
        iv_obj_name = CONV #( mv_trkorr ) iv_status = 'R'
        iv_message = |OT { mv_trkorr } no existe en el sistema|
        iv_category = 'GENERAL' ).
      rv_ok = abap_false. RETURN.
    ENDIF.
    SELECT SINGLE as4text FROM e07t INTO mv_ot_text
      WHERE trkorr = mv_trkorr AND langu = sy-langu.
    IF sy-subrc <> 0.
      SELECT SINGLE as4text FROM e07t INTO mv_ot_text
        WHERE trkorr = mv_trkorr AND langu = 'E'.
    ENDIF.
    rv_ok = abap_true.
  ENDMETHOD.

  METHOD read_ot_objects.
    DATA lt_tasks TYPE STANDARD TABLE OF trkorr.
    SELECT trkorr FROM e070 INTO TABLE lt_tasks WHERE strkorr = mv_trkorr.
    APPEND mv_trkorr TO lt_tasks.
    IF lt_tasks IS NOT INITIAL.
      SELECT pgmid object obj_name FROM e071 INTO TABLE mt_all_ot_objects
        FOR ALL ENTRIES IN lt_tasks WHERE trkorr = lt_tasks-table_line.
      SORT mt_all_ot_objects BY pgmid object obj_name.
      DELETE ADJACENT DUPLICATES FROM mt_all_ot_objects
        COMPARING pgmid object obj_name.
    ENDIF.
  ENDMETHOD.

  METHOD check_includes_present.
    DATA lt_includes TYPE STANDARD TABLE OF tadir-obj_name.
    DATA lv_progname TYPE progname.
    LOOP AT mt_all_ot_objects INTO DATA(ls_obj)
      WHERE ( object = 'PROG' OR object = 'REPS' ).
      lv_progname = ls_obj-obj_name. CLEAR lt_includes.
      CALL FUNCTION 'RS_GET_ALL_INCLUDES'
        EXPORTING program = lv_progname
        TABLES includetab = lt_includes
        EXCEPTIONS OTHERS = 1.
      IF sy-subrc <> 0. CONTINUE. ENDIF.
      LOOP AT lt_includes INTO DATA(lv_include).
        IF lv_include(1) <> 'Z' AND lv_include(1) <> 'Y'. CONTINUE. ENDIF.
        IF is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'REPS'
              iv_obj_name = CONV #( lv_include ) ) = abap_false
          AND is_object_in_ot( iv_pgmid = 'LIMU' iv_object = 'REPS'
                iv_obj_name = CONV #( lv_include ) ) = abap_false
          AND is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'PROG'
                iv_obj_name = CONV #( lv_include ) ) = abap_false.
          SELECT SINGLE name FROM trdir INTO @DATA(lv_exists)
            WHERE name = @lv_include.
          IF sy-subrc = 0.
            add_result( iv_pgmid = ls_obj-pgmid iv_object = ls_obj-object
              iv_obj_name = ls_obj-obj_name iv_status = 'Y'
              iv_message = |Include { lv_include } no está en la OT (existe en BZD)|
              iv_category = 'INCLUDE' ).
          ELSE.
            add_result( iv_pgmid = ls_obj-pgmid iv_object = ls_obj-object
              iv_obj_name = ls_obj-obj_name iv_status = 'R'
              iv_message = |Include { lv_include } NO existe y NO está en la OT — FALTANTE|
              iv_category = 'INCLUDE' ).
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD check_fugr_completeness.
    DATA lt_func_names TYPE STANDARD TABLE OF rs38l_fnam.
    DATA lv_pname TYPE pname.
    LOOP AT mt_all_ot_objects INTO DATA(ls_obj) WHERE object = 'FUGR'.
      DATA(lv_fugr_name) = ls_obj-obj_name.
      CONCATENATE 'SAPL' lv_fugr_name INTO lv_pname.
      CLEAR lt_func_names.
      SELECT funcname FROM tfdir INTO TABLE lt_func_names WHERE pname = lv_pname.
      LOOP AT lt_func_names INTO DATA(lv_func).
        IF is_object_in_ot( iv_pgmid = 'LIMU' iv_object = 'FUNC'
              iv_obj_name = CONV #( lv_func ) ) = abap_false
          AND is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'FUNC'
                iv_obj_name = CONV #( lv_func ) ) = abap_false.
          add_result( iv_pgmid = ls_obj-pgmid iv_object = ls_obj-object
            iv_obj_name = ls_obj-obj_name iv_status = 'Y'
            iv_message = |FM { lv_func } del grupo { lv_fugr_name } no está en la OT|
            iv_category = 'FUGR' ).
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD check_inactive_objects.
    DATA lv_obj_name TYPE trobj_name.
    LOOP AT mt_all_ot_objects INTO DATA(ls_obj).
      lv_obj_name = ls_obj-obj_name.
      SELECT SINGLE obj_name FROM dwinactiv INTO @DATA(lv_dummy)
        WHERE object = @ls_obj-object AND obj_name = @lv_obj_name.
      IF sy-subrc = 0.
        add_result( iv_pgmid = ls_obj-pgmid iv_object = ls_obj-object
          iv_obj_name = ls_obj-obj_name iv_status = 'R'
          iv_message = |Objeto INACTIVO — debe activarse antes de transportar|
          iv_category = 'ACTIVATION' ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD check_ddic_dependencies.
    " V5: DDIC check does NOT filter by is_real_ot — reports all missing types
    TYPES: BEGIN OF lty_ddic_ref, name TYPE trobj_name, END OF lty_ddic_ref.
    DATA lt_ddic_refs TYPE STANDARD TABLE OF lty_ddic_ref.
    DATA lt_checked TYPE SORTED TABLE OF trobj_name WITH UNIQUE KEY table_line.
    DATA lt_source_objects TYPE STANDARD TABLE OF trobj_name.
    LOOP AT mt_all_ot_objects INTO DATA(ls_obj).
      CASE ls_obj-object.
        WHEN 'PROG' OR 'REPS'.
          APPEND ls_obj-obj_name TO lt_source_objects.
        WHEN 'CLAS' OR 'CLSD' OR 'CPUB' OR 'CPRO' OR 'METH'.
          DATA(lv_cls_name) = ls_obj-obj_name.
          DATA lt_cls_includes TYPE STANDARD TABLE OF progname.
          DATA lv_cls_pattern TYPE progname.
          CONCATENATE lv_cls_name '%' INTO lv_cls_pattern.
          SELECT name FROM trdir INTO TABLE lt_cls_includes
            WHERE name LIKE lv_cls_pattern AND subc = 'I'.
          LOOP AT lt_cls_includes INTO DATA(lv_cls_inc).
            APPEND CONV trobj_name( lv_cls_inc ) TO lt_source_objects.
          ENDLOOP.
          DATA lv_cls_prog TYPE trobj_name.
          CONCATENATE lv_cls_name '========CP' INTO lv_cls_prog.
          APPEND lv_cls_prog TO lt_source_objects.
        WHEN 'INTF'.
          DATA lv_intf_prog TYPE trobj_name.
          CONCATENATE ls_obj-obj_name '========IP' INTO lv_intf_prog.
          APPEND lv_intf_prog TO lt_source_objects.
      ENDCASE.
    ENDLOOP.
    SORT lt_source_objects.
    DELETE ADJACENT DUPLICATES FROM lt_source_objects.

    LOOP AT lt_source_objects INTO DATA(lv_source).
      CLEAR lt_ddic_refs.
      SELECT DISTINCT name FROM wbcrossgt INTO TABLE lt_ddic_refs
        WHERE include = lv_source AND otype = 'TY'.
      LOOP AT lt_ddic_refs INTO DATA(ls_ref).
        IF ls_ref-name IS INITIAL. CONTINUE. ENDIF.
        IF ls_ref-name CS '\TY:'. CONTINUE. ENDIF.
        IF ls_ref-name(1) <> 'Z' AND ls_ref-name(1) <> 'Y'. CONTINUE. ENDIF.
        READ TABLE lt_checked TRANSPORTING NO FIELDS
          WITH KEY table_line = ls_ref-name.
        IF sy-subrc = 0. CONTINUE. ENDIF.
        INSERT ls_ref-name INTO TABLE lt_checked.

        " Check if type is in the OT
        IF is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'TABL'
              iv_obj_name = ls_ref-name ) = abap_true
          OR is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'TTYP'
              iv_obj_name = ls_ref-name ) = abap_true
          OR is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'DTEL'
              iv_obj_name = ls_ref-name ) = abap_true
          OR is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'VIEW'
              iv_obj_name = ls_ref-name ) = abap_true
          OR is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'CLAS'
              iv_obj_name = ls_ref-name ) = abap_true
          OR is_object_in_ot( iv_pgmid = 'R3TR' iv_object = 'INTF'
              iv_obj_name = ls_ref-name ) = abap_true
          OR is_object_in_ot( iv_pgmid = 'LIMU' iv_object = 'TABD'
              iv_obj_name = ls_ref-name ) = abap_true
          OR is_object_in_ot( iv_pgmid = 'LIMU' iv_object = 'TTYD'
              iv_obj_name = ls_ref-name ) = abap_true
          OR is_object_in_ot( iv_pgmid = 'LIMU' iv_object = 'CLSD'
              iv_obj_name = ls_ref-name ) = abap_true.
          CONTINUE.
        ENDIF.

        " Check TADIR in BZD
        DATA lv_devclass TYPE devclass.
        CLEAR lv_devclass.
        SELECT SINGLE devclass FROM tadir INTO lv_devclass
          WHERE pgmid = 'R3TR' AND obj_name = ls_ref-name
            AND ( object = 'TABL' OR object = 'TTYP' OR object = 'DTEL'
                  OR object = 'VIEW' OR object = 'CLAS' OR object = 'INTF' ).
        IF sy-subrc = 0.
          IF lv_devclass = '$TMP'.
            add_result( iv_pgmid = 'R3TR' iv_object = 'PROG'
              iv_obj_name = lv_source iv_status = 'R'
              iv_message = |Tipo { ls_ref-name } en $TMP — nunca transportado|
              iv_category = 'DDIC_DEP' ).
          ELSE.
            " V6 FIX: If the type is actually a class/interface in TADIR,
            " skip it — WBCROSSGT reports classes as otype='TY' when used
            " as TYPE REF TO. These are not DDIC types that need checking.
            DATA lv_obj_type_check TYPE trobjtype.
            CLEAR lv_obj_type_check.
            SELECT SINGLE object FROM tadir INTO lv_obj_type_check
              WHERE pgmid = 'R3TR' AND obj_name = ls_ref-name
                AND ( object = 'CLAS' OR object = 'INTF' ).
            IF sy-subrc = 0.
              " It's a class/interface, not a DDIC type — skip target check
              CONTINUE.
            ENDIF.
            " Real DDIC type in a transportable package — check in target
            APPEND ls_ref-name TO mt_ddic_to_check.
          ENDIF.
        ELSE.
          " Check TRDIR for class programs
          DATA lv_cls_check TYPE progname.
          CONCATENATE ls_ref-name '========CP' INTO lv_cls_check.
          SELECT SINGLE name FROM trdir INTO @DATA(lv_trdir_check)
            WHERE name = @lv_cls_check.
          IF sy-subrc = 0. CONTINUE. ENDIF.
          " Truly missing from BZD
          add_result( iv_pgmid = 'R3TR' iv_object = 'PROG'
            iv_obj_name = lv_source iv_status = 'R'
            iv_message = |Tipo DDIC { ls_ref-name } NO existe y NO está en la OT — FALTANTE|
            iv_category = 'DDIC_DEP' ).
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD exists_in_target.
    " Uses RFC_READ_TABLE to check if a record exists in the target system
    DATA lt_options TYPE STANDARD TABLE OF rfc_db_opt.
    DATA lt_fields  TYPE STANDARD TABLE OF rfc_db_fld.
    DATA lt_data    TYPE STANDARD TABLE OF tab512.

    APPEND VALUE rfc_db_opt( text = iv_where ) TO lt_options.

    CALL FUNCTION 'RFC_READ_TABLE'
      DESTINATION mv_rfcdst
      EXPORTING
        query_table = iv_table
        rowcount    = 1
      TABLES
        options     = lt_options
        fields      = lt_fields
        data        = lt_data
      EXCEPTIONS
        table_not_available        = 1
        table_without_data         = 2
        option_not_valid           = 3
        field_not_valid            = 4
        not_authorized             = 5
        data_buffer_exceeded       = 6
        system_failure             = 7
        communication_failure      = 8
        OTHERS                     = 9.

    rv_exists = xsdbool( sy-subrc = 0 AND lt_data IS NOT INITIAL ).
  ENDMETHOD.

  METHOD check_objects_in_target.
    " V5: Verify that DDIC types referenced by OT objects exist in BZP
    " Uses RFC_READ_TABLE via RFC destination to target system
    IF mv_rfcdst IS INITIAL.
      RETURN. "No RFC destination configured — skip target check
    ENDIF.

    " First test connectivity
    DATA lt_test_data TYPE STANDARD TABLE OF tab512.
    DATA lt_test_opt  TYPE STANDARD TABLE OF rfc_db_opt.
    DATA lt_test_fld  TYPE STANDARD TABLE OF rfc_db_fld.
    APPEND VALUE rfc_db_opt( text = |NAME = 'SAPMV45A'| ) TO lt_test_opt.

    CALL FUNCTION 'RFC_READ_TABLE'
      DESTINATION mv_rfcdst
      EXPORTING
        query_table = 'TRDIR'
        rowcount    = 1
      TABLES
        options     = lt_test_opt
        fields      = lt_test_fld
        data        = lt_test_data
      EXCEPTIONS
        OTHERS      = 1.

    IF sy-subrc <> 0.
      add_result( iv_pgmid = 'R3TR' iv_object = 'PROG'
        iv_obj_name = CONV #( mv_rfcdst )
        iv_status = 'Y'
        iv_message = |No se pudo conectar a { mv_rfcdst } — verificación de destino omitida|
        iv_category = 'TARGET' ).
      RETURN.
    ENDIF.

    add_result( iv_pgmid = 'R3TR' iv_object = 'PROG'
      iv_obj_name = CONV #( mv_rfcdst )
      iv_status = 'G'
      iv_message = |Conexión a { mv_rfcdst } OK — verificando objetos en destino|
      iv_category = 'TARGET' ).

    " Remove duplicates from DDIC types to check
    SORT mt_ddic_to_check.
    DELETE ADJACENT DUPLICATES FROM mt_ddic_to_check.

    " Check each DDIC type in the target system
    LOOP AT mt_ddic_to_check INTO DATA(lv_type).
      DATA(lv_found) = abap_false.
      DATA lv_where TYPE string.

      " Check DD02L (tables/structures)
      lv_where = |TABNAME = '{ lv_type }' AND AS4LOCAL = 'A'|.
      IF exists_in_target( iv_table = 'DD02L' iv_where = lv_where ) = abap_true.
        lv_found = abap_true.
      ENDIF.

      " Check DD04L (data elements)
      IF lv_found = abap_false.
        lv_where = |ROLLNAME = '{ lv_type }' AND AS4LOCAL = 'A'|.
        IF exists_in_target( iv_table = 'DD04L' iv_where = lv_where ) = abap_true.
          lv_found = abap_true.
        ENDIF.
      ENDIF.

      " Check DD40L (table types)
      IF lv_found = abap_false.
        lv_where = |TYPENAME = '{ lv_type }' AND AS4LOCAL = 'A'|.
        IF exists_in_target( iv_table = 'DD40L' iv_where = lv_where ) = abap_true.
          lv_found = abap_true.
        ENDIF.
      ENDIF.

      " Check TADIR for classes/interfaces
      IF lv_found = abap_false.
        lv_where = |OBJ_NAME = '{ lv_type }' AND PGMID = 'R3TR' AND OBJECT = 'CLAS'|.
        IF exists_in_target( iv_table = 'TADIR' iv_where = lv_where ) = abap_true.
          lv_found = abap_true.
        ENDIF.
      ENDIF.
      IF lv_found = abap_false.
        lv_where = |OBJ_NAME = '{ lv_type }' AND PGMID = 'R3TR' AND OBJECT = 'INTF'|.
        IF exists_in_target( iv_table = 'TADIR' iv_where = lv_where ) = abap_true.
          lv_found = abap_true.
        ENDIF.
      ENDIF.

      IF lv_found = abap_true.
        " Exists in target — OK, no action needed
        CONTINUE.
      ELSE.
        " CRITICAL: Type does NOT exist in target system
        add_result( iv_pgmid = 'R3TR' iv_object = 'TTYP'
          iv_obj_name = CONV #( lv_type )
          iv_status = 'R'
          iv_message = |{ lv_type } NO existe en { mv_rfcdst } y NO está en la OT — FALLARÁ al activar|
          iv_category = 'TARGET' ).
      ENDIF.
    ENDLOOP.

    " Also check that all PROG/CLAS includes referenced exist in target
    LOOP AT mt_all_ot_objects INTO DATA(ls_obj)
      WHERE ( object = 'CLAS' OR object = 'CLSD' OR object = 'CPUB'
              OR object = 'CPRO' OR object = 'INTF' ).
      " For classes, check if the class exists in target TADIR
      DATA lv_cls_name TYPE trobj_name.
      lv_cls_name = ls_obj-obj_name.
      " Only check R3TR level objects (not LIMU parts)
      IF ls_obj-pgmid = 'R3TR'.
        lv_where = |OBJ_NAME = '{ lv_cls_name }' AND PGMID = 'R3TR'|.
        " New class being transported — it's OK if it doesn't exist yet
        " The transport will create it. Skip this check.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD check_cross_references.
    DATA lt_where_used TYPE STANDARD TABLE OF wbcrossgt.
    LOOP AT mt_all_ot_objects INTO DATA(ls_obj)
      WHERE pgmid = 'R3TR' AND ( object = 'PROG' OR object = 'CLAS'
            OR object = 'FUGR' OR object = 'REPS' ).
      CLEAR lt_where_used.
      SELECT otype name include FROM wbcrossgt INTO TABLE lt_where_used
        WHERE include = ls_obj-obj_name.
      LOOP AT lt_where_used INTO DATA(ls_ref).
        IF ls_ref-name IS INITIAL
          OR ( ls_ref-name(1) <> 'Z' AND ls_ref-name(1) <> 'Y' ). CONTINUE. ENDIF.
        IF ls_ref-name = ls_obj-obj_name. CONTINUE. ENDIF.
        DATA lv_other_ot TYPE trkorr. DATA lv_other_status TYPE trstatus.
        CLEAR: lv_other_ot, lv_other_status.
        SELECT SINGLE a~trkorr b~trstatus FROM e071 AS a
          INNER JOIN e070 AS b ON a~trkorr = b~trkorr
          INTO (lv_other_ot, lv_other_status)
          WHERE a~obj_name = ls_ref-name AND a~trkorr <> mv_trkorr
            AND ( b~trstatus = 'D' OR b~trstatus = 'L' ).
        IF sy-subrc = 0 AND is_real_ot( lv_other_ot ) = abap_true.
          add_result( iv_pgmid = ls_obj-pgmid iv_object = ls_obj-object
            iv_obj_name = ls_obj-obj_name iv_status = 'Y'
            iv_message = |Ref { ls_ref-name } en OT { lv_other_ot } — verificar secuencia|
            iv_category = 'XREF' ).
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD check_locked_objects.
    LOOP AT mt_all_ot_objects INTO DATA(ls_obj).
      DATA lv_lock_ot TYPE trkorr. DATA lv_lock_user TYPE as4user.
      DATA lv_lock_status TYPE trstatus.
      CLEAR: lv_lock_ot, lv_lock_user, lv_lock_status.
      SELECT SINGLE a~trkorr b~as4user b~trstatus FROM e071 AS a
        INNER JOIN e070 AS b ON a~trkorr = b~trkorr
        INTO (lv_lock_ot, lv_lock_user, lv_lock_status)
        WHERE a~pgmid = ls_obj-pgmid AND a~object = ls_obj-object
          AND a~obj_name = ls_obj-obj_name AND a~trkorr <> mv_trkorr
          AND b~trstatus <> 'R' AND b~as4user <> sy-uname.
      IF sy-subrc = 0 AND is_real_ot( lv_lock_ot ) = abap_true.
        add_result( iv_pgmid = ls_obj-pgmid iv_object = ls_obj-object
          iv_obj_name = ls_obj-obj_name iv_status = 'Y'
          iv_message = |Objeto en OT { lv_lock_ot } de { lv_lock_user } (status { lv_lock_status })|
          iv_category = 'LOCK' ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD is_object_in_ot.
    READ TABLE mt_all_ot_objects TRANSPORTING NO FIELDS
      WITH KEY pgmid = iv_pgmid object = iv_object obj_name = iv_obj_name.
    rv_found = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD add_result.
    DATA(lv_icon) = SWITCH icon_d( iv_status
      WHEN 'G' THEN icon_green_light
      WHEN 'Y' THEN icon_yellow_light
      WHEN 'R' THEN icon_led_red ).
    APPEND VALUE gty_check_result(
      icon = lv_icon pgmid = iv_pgmid object = iv_object
      obj_name = iv_obj_name status = iv_status
      message = iv_message category = iv_category ) TO mt_results.
  ENDMETHOD.

  METHOD display_results.
    SORT mt_results BY status DESCENDING category pgmid object obj_name.
    DATA lo_alv TYPE REF TO cl_salv_table.
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
          CHANGING t_table = mt_results ).
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
        DATA(lv_red) = REDUCE i( INIT x = 0
          FOR ls IN mt_results WHERE ( status = 'R' ) NEXT x = x + 1 ).
        DATA(lv_yellow) = REDUCE i( INIT x = 0
          FOR ls IN mt_results WHERE ( status = 'Y' ) NEXT x = x + 1 ).
        DATA(lv_green) = REDUCE i( INIT x = 0
          FOR ls IN mt_results WHERE ( status = 'G' ) NEXT x = x + 1 ).
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
        IF mv_rfcdst IS NOT INITIAL.
          lo_header->create_label( row = 2 column = 3
            text = |Target: { mv_rfcdst }| ).
        ENDIF.
        lo_alv->set_top_of_list( lo_header ).
        lo_alv->display( ).
      CATCH cx_salv_msg cx_salv_not_found INTO DATA(lx_err).
        WRITE: / |Error ALV: { lx_err->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  NEW lcl_transport_checker(
    iv_trkorr = p_trkorr
    iv_rfcdst = p_rfcdst
    iv_test   = p_test )->execute( ).
