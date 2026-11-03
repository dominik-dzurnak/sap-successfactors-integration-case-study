# 04 Test Plan

## Test phases

| Phase | Scope | Owner |
|-------|-------|-------|
| Unit test | Groovy scripts, ABAP Unit | Developer |
| Integration test (SIT) | INT-01 to INT-04 end to end in QA tenants | Integration team |
| User acceptance test (UAT) | Hiring scenarios with recruiters and HR | Business users |
| Cutover rehearsal | Initial cost center load, delta pointer setup | Project team |

## Test cases

| ID | Flow | Scenario | Expected result |
|----|------|----------|-----------------|
| TC-01 | INT-01 | New cost center created in S/4HANA | Appears in EC FOCostCenter after next run |
| TC-02 | INT-01 | Cost center blocked (DATBI in past) | EC status = `I` |
| TC-03 | INT-02 | Candidate hired, onboarding completed | Employee in S/4HANA, log status `S` |
| TC-04 | INT-02 | Cost center missing in S/4HANA | Log status `E`, error text "Cost center not found" |
| TC-05 | INT-02 | Same employee sent twice | No duplicate, second record logged as update |
| TC-06 | INT-02 | Employee class 4 (external) | Filtered out in CPI, not sent |
| TC-07 | INT-02 | personIdExternal not numeric | CPI error, alert mail sent |
| TC-08 | INT-04 | Reprocess failed record after fix | Status changes `E` → `R` |
| TC-09 | INT-04 | Error older than 24 h | Highlighted red in monitor |
| TC-10 | Joule | Draft job description from 3 line brief | Draft created, recruiter edits and approves |

## Go / No-Go criteria

| Criterion | Threshold | Status |
|-----------|-----------|--------|
| All Must test cases passed | 100% | ☐ |
| Open defects priority 1 / 2 | 0 / ≤ 2 with workaround | ☐ |
| Initial cost center load reconciled | 100% match | ☐ |
| UAT sign-off from HR and Finance | Signed | ☐ |
| Monitoring and alerting tested | Yes | ☐ |
| Hypercare team and runbook ready | Yes | ☐ |
