# CPI iFlow Design

## INT-01 Replicate cost centers S/4HANA → EC

```
Timer (daily 02:00)
  → Request Reply: S/4HANA OData API_COSTCENTER_SRV (delta by LastChangeDateTime)
  → Groovy: map_costcenter_to_focostcenter.groovy
  → Splitter (500 records)
  → Request Reply: SuccessFactors OData v2 upsert (FOCostCenter)
  → Groovy: check_upsert_response.groovy
  → Exception Subprocess: log + alert mail
```

**Adapters**
- Receiver S/4HANA: OData V2, Cloud Connector, client certificate
- Receiver SuccessFactors: SuccessFactors adapter, OData V2, operation `Upsert`, OAuth2 SAML bearer

## INT-02 Replicate new hires EC → S/4HANA

```
Timer (every 15 min)
  → Content Modifier: read global variable LAST_RUN
  → Request Reply: SuccessFactors OData v2 query EmpJob
        $filter=lastModifiedDateTime gt datetimeoffset'${LAST_RUN}'
        $expand=employmentNav/personNav/personalInfoNav
  → Filter: drop employeeClass = 4 (external)
  → Groovy: build_s4_employee_payload.groovy
  → Iterating Splitter (1 employee per message)
  → Request Reply: S/4HANA REST endpoint /sap/zsf/employee (ABAP)
  → Write Variable: LAST_RUN = run start time
  → Exception Subprocess: log + alert mail, LAST_RUN not updated
```

**Why LAST_RUN is only updated at the end:** if the run fails, the next run re-reads the same delta, so no employee is lost. The ABAP side is idempotent (same PERNR + BEGDA = update, not duplicate).
