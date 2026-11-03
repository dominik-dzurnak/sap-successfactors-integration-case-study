# 01 Business Case and Requirements

> Fictional scenario for portfolio purposes.

## Company profile

| Item | Value |
|------|-------|
| Company | Alpine Beverage Group (fictional) |
| Industry | Beverage bottling and distribution |
| Employees | ~25,000 in 20 countries |
| Annual hires | ~6,000 (incl. ~2,000 seasonal) |
| Current HR | SAP ERP HCM on-premise + legacy ATS |
| Target HR | SAP SuccessFactors Recruiting, Onboarding, Employee Central |
| Finance | SAP S/4HANA (stays system of record for cost centers) |

## Pain points

1. New hire data is typed manually 2 to 3 times (ATS, HR, payroll).
2. ~8% of new hires have a wrong cost center in the first payroll run.
3. Recruiters cannot see the current org structure and cost centers.
4. Hiring managers have no live view of requisition status.
5. Seasonal hiring peaks (spring) overload the recruiting team.

## Business goals (KPIs)

| KPI | Today | Target |
|-----|-------|--------|
| Time from offer accepted to employee in S/4HANA | 5 days | < 1 day |
| New hires with wrong cost center | 8% | < 1% |
| Manual data entry steps per hire | 3 | 0 |
| Recruiter time per seasonal hire | 4 h | 2 h |

## Functional requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | Cost centers from S/4HANA must be available in EC within 24 h | Must |
| FR-02 | Hired candidates flow automatically from Recruiting to Onboarding to EC | Must |
| FR-03 | New employees in EC are replicated to S/4HANA within 15 min | Must |
| FR-04 | Every replication attempt is logged with status and error text | Must |
| FR-05 | HR IT can monitor and reprocess failed records | Must |
| FR-06 | Hiring managers get requisition status updates in MS Teams | Should |
| FR-07 | Recruiters can use Joule to draft job descriptions and summarize candidates | Should |
| FR-08 | AI agent pre-screens seasonal applications against must-have criteria | Could |

## Non-functional requirements

- **Security:** OAuth 2.0 SAML bearer between CPI and SuccessFactors, no basic auth in production
- **Data privacy:** GDPR compliant, no sensitive personal data in logs, log retention 90 days
- **Performance:** delta loads only, max 1,000 records per OData page
- **Monitoring:** failed messages visible in CPI and in the S/4HANA monitor

## User stories

- **US-01** As a recruiter, I want to see valid cost centers when creating a requisition, so that new hires are booked correctly.
- **US-02** As an HR administrator, I want hired candidates to appear in Employee Central automatically, so that I do not retype data.
- **US-03** As a payroll specialist, I want new employees in S/4HANA before their first day, so that payroll and access are ready.
- **US-04** As an HR IT analyst, I want a monitor of failed replications with error texts, so that I can fix them quickly.
- **US-05** As a hiring manager, I want status updates in Teams, so that I do not have to chase recruiters.
- **US-06** As a recruiter, I want Joule to draft a job description from a short brief, so that I publish jobs faster.
