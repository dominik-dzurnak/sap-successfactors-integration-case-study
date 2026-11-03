"! <p>Validation and logging for employees replicated from SuccessFactors EC.</p>
"! Alpine Beverage Group (fictional portfolio case study).
CLASS zcl_sf_repl_log_handler DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_employee,
        pernr      TYPE n LENGTH 8,
        first_name TYPE c LENGTH 40,
        last_name  TYPE c LENGTH 40,
        begda      TYPE d,
        bukrs      TYPE c LENGTH 4,
        kostl      TYPE c LENGTH 10,
        persg      TYPE c LENGTH 1,
      END OF ty_employee,
      tt_employee TYPE STANDARD TABLE OF ty_employee WITH EMPTY KEY,
      tt_log      TYPE STANDARD TABLE OF zsf_repl_log WITH EMPTY KEY.

    CONSTANTS:
      BEGIN OF gc_status,
        success     TYPE c LENGTH 1 VALUE 'S',
        error       TYPE c LENGTH 1 VALUE 'E',
        reprocessed TYPE c LENGTH 1 VALUE 'R',
      END OF gc_status,
      gc_overdue_hours TYPE i VALUE 24.

    "! Checks one employee record. Returns an empty string if valid.
    "! Static and without DB access, so it can be unit tested.
    CLASS-METHODS validate_employee
      IMPORTING is_employee      TYPE ty_employee
                it_valid_kostl   TYPE string_table OPTIONAL
      RETURNING VALUE(rv_error)  TYPE string.

    "! True if an error record is older than gc_overdue_hours.
    CLASS-METHODS is_overdue
      IMPORTING iv_created_at     TYPE timestampl
                iv_now            TYPE timestampl
      RETURNING VALUE(rv_overdue) TYPE abap_bool.

    "! Validates all employees and writes one log record per employee.
    METHODS process
      IMPORTING it_employees  TYPE tt_employee
      RETURNING VALUE(rt_log) TYPE tt_log.

    "! Sets status of a fixed error record to R (reprocessed).
    METHODS mark_reprocessed
      IMPORTING iv_log_id         TYPE sysuuid_x16
      RETURNING VALUE(rv_success) TYPE abap_bool.

  PRIVATE SECTION.
    METHODS get_valid_cost_centers
      IMPORTING it_employees     TYPE tt_employee
      RETURNING VALUE(rt_kostl)  TYPE string_table.
ENDCLASS.


CLASS zcl_sf_repl_log_handler IMPLEMENTATION.

  METHOD validate_employee.
    IF is_employee-pernr IS INITIAL OR is_employee-pernr CO '0'.
      rv_error = 'Personnel number missing'.
    ELSEIF is_employee-last_name IS INITIAL.
      rv_error = 'Last name missing'.
    ELSEIF is_employee-begda IS INITIAL.
      rv_error = 'Start date missing'.
    ELSEIF is_employee-persg = '9'.
      rv_error = 'External employees are not replicated'.
    ELSEIF it_valid_kostl IS SUPPLIED
       AND NOT line_exists( it_valid_kostl[ table_line = CONV string( is_employee-kostl ) ] ).
      rv_error = |Cost center { is_employee-kostl ALPHA = OUT } not found|.
    ENDIF.
  ENDMETHOD.


  METHOD is_overdue.
    DATA(lv_seconds) = cl_abap_tstmp=>subtract( tstmp1 = iv_now
                                                tstmp2 = iv_created_at ).
    rv_overdue = xsdbool( lv_seconds > gc_overdue_hours * 3600 ).
  ENDMETHOD.


  METHOD process.
    DATA lv_now TYPE timestampl.
    GET TIME STAMP FIELD lv_now.

    DATA(lt_valid_kostl) = get_valid_cost_centers( it_employees ).

    LOOP AT it_employees INTO DATA(ls_employee).
      DATA(lv_error) = validate_employee( is_employee    = ls_employee
                                          it_valid_kostl = lt_valid_kostl ).

      APPEND VALUE #(
        log_id       = cl_system_uuid=>create_uuid_x16_static( )
        pernr        = ls_employee-pernr
        begda        = ls_employee-begda
        first_name   = ls_employee-first_name
        last_name    = ls_employee-last_name
        bukrs        = ls_employee-bukrs
        kostl        = ls_employee-kostl
        persg        = ls_employee-persg
        status       = COND #( WHEN lv_error IS INITIAL THEN gc_status-success
                               ELSE gc_status-error )
        message_text = COND #( WHEN lv_error IS INITIAL THEN 'Replicated successfully'
                               ELSE lv_error )
        created_at   = lv_now
        changed_at   = lv_now
        changed_by   = sy-uname ) TO rt_log.
    ENDLOOP.

    IF rt_log IS NOT INITIAL.
      INSERT zsf_repl_log FROM TABLE @rt_log.
    ENDIF.
  ENDMETHOD.


  METHOD mark_reprocessed.
    DATA lv_now TYPE timestampl.
    GET TIME STAMP FIELD lv_now.

    UPDATE zsf_repl_log
       SET status       = @gc_status-reprocessed,
           message_text = 'Reprocessed after correction',
           changed_at   = @lv_now,
           changed_by   = @sy-uname
     WHERE log_id = @iv_log_id
       AND status = @gc_status-error.

    rv_success = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.


  METHOD get_valid_cost_centers.
    CHECK it_employees IS NOT INITIAL.

    SELECT DISTINCT costcenter
      FROM i_costcenter
      FOR ALL ENTRIES IN @it_employees
      WHERE costcenter       = @it_employees-kostl
        AND validitystartdate <= @sy-datum
        AND validityenddate   >= @sy-datum
      INTO TABLE @DATA(lt_kostl).

    rt_kostl = VALUE #( FOR ls IN lt_kostl ( CONV string( ls-costcenter ) ) ).
  ENDMETHOD.

ENDCLASS.
