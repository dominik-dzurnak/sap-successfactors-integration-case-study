# SuccessFactors OData v2 Samples

Base URL (example data center): `https://api{dc}.successfactors.eu/odata/v2/`

## 1. Open job requisitions for a hiring manager (INT-03)

```http
GET /odata/v2/JobRequisition?$filter=hiringManager/userId eq 'HM1001' and status/id eq '1'
    &$select=jobReqId,jobTitle,costCenterId,numberOpenings,status
    &$expand=status
    &$format=json
```

## 2. New hire delta (INT-02)

```http
GET /odata/v2/EmpJob?$filter=lastModifiedDateTime gt datetimeoffset'2026-03-01T00:00:00Z'
    &$select=userId,startDate,company,costCenter,jobCode,employeeClass,lastModifiedDateTime
    &$expand=employmentNav/personNav/personalInfoNav
    &$format=json
```

## 3. Upsert cost center (INT-01)

```http
POST /odata/v2/upsert
Content-Type: application/json
```

See [upsert_focostcenter.json](upsert_focostcenter.json).

## 4. Sample response

See [empjob_response_sample.json](empjob_response_sample.json). All names and IDs are fictional.
