@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'SF employee replication log'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_SF_ReplicationLog
  as select from zsf_repl_log
{
  key log_id       as LogId,
      pernr        as PersonnelNumber,
      begda        as StartDate,
      first_name   as FirstName,
      last_name    as LastName,
      bukrs        as CompanyCode,
      kostl        as CostCenter,
      persg        as EmployeeGroup,
      status       as Status,
      case status
        when 'S' then 'Success'
        when 'E' then 'Error'
        when 'R' then 'Reprocessed'
        else 'Unknown'
      end          as StatusText,
      case status
        when 'S' then 3
        when 'R' then 2
        when 'E' then 1
        else 0
      end          as StatusCriticality,
      message_text as MessageText,
      created_at   as CreatedAt,
      changed_at   as ChangedAt,
      changed_by   as ChangedBy
}
