"! <p>HTTP handler for /sap/zsf/employee (SICF service).</p>
"! Receives employee JSON from SAP Integration Suite (INT-02),
"! validates and logs every record via ZCL_SF_REPL_LOG_HANDLER.
"! Alpine Beverage Group (fictional portfolio case study).
CLASS zcl_sf_employee_http_handler DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_request,
        employees TYPE zcl_sf_repl_log_handler=>tt_employee,
      END OF ty_request,
      BEGIN OF ty_result,
        pernr   TYPE string,
        status  TYPE string,
        message TYPE string,
      END OF ty_result,
      BEGIN OF ty_response,
        processed TYPE i,
        errors    TYPE i,
        results   TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY,
      END OF ty_response.

    METHODS send_json
      IMPORTING io_server TYPE REF TO if_http_server
                iv_status TYPE i
                iv_json   TYPE string.
ENDCLASS.


CLASS zcl_sf_employee_http_handler IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    IF server->request->get_method( ) <> 'POST'.
      send_json( io_server = server
                 iv_status = 405
                 iv_json   = `{"error":"Only POST is allowed"}` ).
      RETURN.
    ENDIF.

    DATA ls_request TYPE ty_request.
    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json        = server->request->get_cdata( )
                    pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING  data        = ls_request ).
      CATCH cx_root INTO DATA(lx_json).
        send_json( io_server = server
                   iv_status = 400
                   iv_json   = |\{"error":"Invalid JSON: { escape( val = lx_json->get_text( ) format = cl_abap_format=>e_json_string ) }"\}| ).
        RETURN.
    ENDTRY.

    DATA(lt_log) = NEW zcl_sf_repl_log_handler( )->process( ls_request-employees ).
    COMMIT WORK.

    DATA(ls_response) = VALUE ty_response(
      processed = lines( lt_log )
      errors    = REDUCE i( INIT n = 0
                            FOR ls IN lt_log
                            WHERE ( status = zcl_sf_repl_log_handler=>gc_status-error )
                            NEXT n = n + 1 )
      results   = VALUE #( FOR ls IN lt_log
                           ( pernr   = ls-pernr
                             status  = ls-status
                             message = ls-message_text ) ) ).

    " 200 even with record errors: CPI reads per-record status from the body
    send_json( io_server = server
               iv_status = 200
               iv_json   = /ui2/cl_json=>serialize(
                             data        = ls_response
                             pretty_name = /ui2/cl_json=>pretty_mode-camel_case ) ).
  ENDMETHOD.


  METHOD send_json.
    io_server->response->set_status( code = iv_status reason = `` ).
    io_server->response->set_content_type( 'application/json' ).
    io_server->response->set_cdata( iv_json ).
  ENDMETHOD.

ENDCLASS.
