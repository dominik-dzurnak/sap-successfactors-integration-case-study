*"* ABAP Unit tests for ZCL_SF_REPL_LOG_HANDLER (local test class include)
CLASS ltc_validation DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA ms_valid TYPE zcl_sf_repl_log_handler=>ty_employee.

    METHODS setup.
    METHODS valid_employee_passes       FOR TESTING.
    METHODS missing_pernr_fails         FOR TESTING.
    METHODS missing_last_name_fails     FOR TESTING.
    METHODS external_employee_rejected  FOR TESTING.
    METHODS unknown_cost_center_fails   FOR TESTING.
    METHODS error_after_25h_is_overdue  FOR TESTING.
    METHODS error_after_2h_not_overdue  FOR TESTING.
ENDCLASS.


CLASS ltc_validation IMPLEMENTATION.

  METHOD setup.
    ms_valid = VALUE #( pernr      = '10045821'
                        first_name = 'Jana'
                        last_name  = 'Novakova'
                        begda      = '20260301'
                        bukrs      = 'CZ01'
                        kostl      = '0000004200'
                        persg      = '2' ).
  ENDMETHOD.

  METHOD valid_employee_passes.
    DATA(lv_error) = zcl_sf_repl_log_handler=>validate_employee(
                       is_employee    = ms_valid
                       it_valid_kostl = VALUE #( ( `0000004200` ) ) ).
    cl_abap_unit_assert=>assert_initial( lv_error ).
  ENDMETHOD.

  METHOD missing_pernr_fails.
    ms_valid-pernr = '00000000'.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sf_repl_log_handler=>validate_employee( ms_valid )
      exp = `Personnel number missing` ).
  ENDMETHOD.

  METHOD missing_last_name_fails.
    CLEAR ms_valid-last_name.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sf_repl_log_handler=>validate_employee( ms_valid )
      exp = `Last name missing` ).
  ENDMETHOD.

  METHOD external_employee_rejected.
    ms_valid-persg = '9'.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sf_repl_log_handler=>validate_employee( ms_valid )
      exp = `External employees are not replicated` ).
  ENDMETHOD.

  METHOD unknown_cost_center_fails.
    DATA(lv_error) = zcl_sf_repl_log_handler=>validate_employee(
                       is_employee    = ms_valid
                       it_valid_kostl = VALUE #( ( `0000004100` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lv_error
                                        exp = `Cost center 4200 not found` ).
  ENDMETHOD.

  METHOD error_after_25h_is_overdue.
    cl_abap_unit_assert=>assert_true(
      zcl_sf_repl_log_handler=>is_overdue( iv_created_at = '20260301080000.0000000'
                                           iv_now        = '20260302090000.0000000' ) ).
  ENDMETHOD.

  METHOD error_after_2h_not_overdue.
    cl_abap_unit_assert=>assert_false(
      zcl_sf_repl_log_handler=>is_overdue( iv_created_at = '20260301080000.0000000'
                                           iv_now        = '20260301100000.0000000' ) ).
  ENDMETHOD.

ENDCLASS.
