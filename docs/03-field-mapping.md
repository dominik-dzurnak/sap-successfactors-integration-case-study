# 03 Field Mapping

## INT-01 Cost centers: S/4HANA → EC (`FOCostCenter`)

| S/4HANA (CSKS / CSKT) | EC `FOCostCenter` | Rule |
|-----------------------|-------------------|------|
| KOSTL | externalCode | Remove leading zeros |
| KTEXT | name | Language from SPRAS, default EN |
| DATAB | startDate | Format `/Date(ms)/` |
| BUKRS | cust_CompanyCode | 1:1 |
| VERAK_USER | costCenterManager | Map user ID to EC user ID |
| (derived) | status | `A` if DATBI ≥ today, else `I` |

## INT-02 New hire: EC → S/4HANA

| EC entity.field | S/4HANA target (ZSF_REPL_LOG / HR) | Rule |
|-----------------|------------------------------------|------|
| PerPerson.personIdExternal | PERNR | Must be numeric, 8 digits, left pad with 0 |
| PerPersonal.firstName | VORNA | 1:1 |
| PerPersonal.lastName | NACHN | 1:1 |
| EmpJob.startDate | BEGDA | Convert to YYYYMMDD |
| EmpJob.company | BUKRS | Value mapping table VM_COMPANY |
| EmpJob.costCenter | KOSTL | Pad to 10 chars with leading zeros |
| EmpJob.jobCode | STELL | Value mapping table VM_JOB |
| EmpJob.employeeClass | PERSG | Value mapping table VM_EMPCLASS |
| EmpJob.lastModifiedDateTime | (delta pointer) | Stored in CPI global variable |

## Value mapping example (VM_EMPCLASS)

| EC employeeClass | S/4HANA PERSG | Meaning |
|------------------|---------------|---------|
| 1 | 1 | Permanent |
| 2 | 2 | Temporary / seasonal |
| 3 | 3 | Intern |
| 4 | 9 | External (not replicated) |
