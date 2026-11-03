*&---------------------------------------------------------------------*
*& Report ZR_SF_REPL_MONITOR
*&---------------------------------------------------------------------*
*& Monitor for employees replicated from SuccessFactors Employee Central.
*& Shows log records, highlights errors older than 24 h in red and
*& lets HR IT mark corrected records as reprocessed.
*& Alpine Beverage Group (fictional portfolio case study).
*&---------------------------------------------------------------------*
REPORT zr_sf_repl_monitor.

TABLES zsf_repl_log.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_pernr  FOR zsf_repl_log-pernr,
                  s_bukrs  FOR zsf_repl_log-bukrs,
                  s_status FOR zsf_repl_log-status DEFAULT 'E'.
  PARAMETERS p_days TYPE i DEFAULT 7.
SELECTION-SCREEN END OF BLOCK b1.

CLASS lcl_monitor DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_row,
        log_id       TYPE sysuuid_x16,
        pernr        TYPE n LENGTH 8,
        last_name    TYPE c LENGTH 40,
        first_name   TYPE c LENGTH 40,
        begda        TYPE d,
        bukrs        TYPE c LENGTH 4,
        kostl        TYPE c LENGTH 10,
        status       TYPE c LENGTH 1,
        message_text TYPE c LENGTH 220,
        created_at   TYPE timestampl,
        t_color      TYPE lvc_t_scol,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS run.

  PRIVATE SECTION.
    DATA mt_rows TYPE tt_row.
    DATA mo_alv  TYPE REF TO cl_salv_table.

    METHODS load_data.
    METHODS set_colors.
    METHODS display.
    METHODS on_user_command FOR EVENT added_function OF cl_salv_events
      IMPORTING e_salv_function.
ENDCLASS.


CLASS lcl_monitor IMPLEMENTATION.

  METHOD run.
    load_data( ).
    IF mt_rows IS INITIAL.
      MESSAGE 'No replication records found' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.
    set_colors( ).
    display( ).
  ENDMETHOD.


  METHOD load_data.
    DATA lv_from TYPE timestampl.
    DATA(lv_from_date) = CONV d( sy-datum - p_days ).
    CONVERT DATE lv_from_date TIME '000000' INTO TIME STAMP lv_from TIME ZONE 'UTC'.

    SELECT log_id, pernr, last_name, first_name, begda, bukrs, kostl,
           status, message_text, created_at
      FROM zsf_repl_log
      WHERE pernr      IN @s_pernr
        AND bukrs      IN @s_bukrs
        AND status     IN @s_status
        AND created_at >= @lv_from
      ORDER BY created_at DESCENDING
      INTO CORRESPONDING FIELDS OF TABLE @mt_rows.
  ENDMETHOD.


  METHOD set_colors.
    DATA lv_now TYPE timestampl.
    GET TIME STAMP FIELD lv_now.

    LOOP AT mt_rows ASSIGNING FIELD-SYMBOL(<ls_row>).
      DATA(lv_color) = SWITCH i( <ls_row>-status
                         WHEN zcl_sf_repl_log_handler=>gc_status-success     THEN col_positive
                         WHEN zcl_sf_repl_log_handler=>gc_status-reprocessed THEN col_total
                         WHEN zcl_sf_repl_log_handler=>gc_status-error       THEN
                           COND #( WHEN zcl_sf_repl_log_handler=>is_overdue(
                                          iv_created_at = <ls_row>-created_at
                                          iv_now        = lv_now )
                                   THEN col_negative
                                   ELSE col_group ) ).
      <ls_row>-t_color = VALUE #( ( fname = 'STATUS'       color-col = lv_color )
                                  ( fname = 'MESSAGE_TEXT' color-col = lv_color ) ).
    ENDLOOP.
  ENDMETHOD.


  METHOD display.
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = mo_alv
                                CHANGING  t_table      = mt_rows ).
      CATCH cx_salv_msg INTO DATA(lx_msg).
        MESSAGE lx_msg TYPE 'E'.
    ENDTRY.

    mo_alv->get_functions( )->set_all( abap_true ).
    mo_alv->get_columns( )->set_optimize( abap_true ).
    mo_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>row_column ).

    TRY.
        mo_alv->get_columns( )->set_color_column( 'T_COLOR' ).
        mo_alv->get_columns( )->get_column( 'LOG_ID' )->set_technical( abap_true ).
        mo_alv->get_functions( )->add_function(
          name     = 'REPROC'
          icon     = CONV #( icon_execute_object )
          text     = 'Mark reprocessed'
          tooltip  = 'Mark selected error records as reprocessed'
          position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_not_found cx_salv_data_error cx_salv_existing cx_salv_wrong_call.
        " Column or function setup is optional for display
    ENDTRY.

    SET HANDLER on_user_command FOR mo_alv->get_event( ).
    mo_alv->get_display_settings( )->set_list_header( 'SuccessFactors replication monitor' ).
    mo_alv->display( ).
  ENDMETHOD.


  METHOD on_user_command.
    CHECK e_salv_function = 'REPROC'.

    DATA(lt_selected) = mo_alv->get_selections( )->get_selected_rows( ).
    IF lt_selected IS INITIAL.
      MESSAGE 'Select at least one row' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    DATA(lo_handler) = NEW zcl_sf_repl_log_handler( ).
    DATA(lv_count) = 0.

    LOOP AT lt_selected INTO DATA(lv_index).
      ASSIGN mt_rows[ lv_index ] TO FIELD-SYMBOL(<ls_row>).
      IF sy-subrc = 0 AND lo_handler->mark_reprocessed( <ls_row>-log_id ) = abap_true.
        <ls_row>-status       = zcl_sf_repl_log_handler=>gc_status-reprocessed.
        <ls_row>-message_text = 'Reprocessed after correction'.
        lv_count += 1.
      ENDIF.
    ENDLOOP.

    COMMIT WORK.
    set_colors( ).
    mo_alv->refresh( ).
    MESSAGE |{ lv_count } record(s) marked as reprocessed| TYPE 'S'.
  ENDMETHOD.

ENDCLASS.


START-OF-SELECTION.
  NEW lcl_monitor( )->run( ).
