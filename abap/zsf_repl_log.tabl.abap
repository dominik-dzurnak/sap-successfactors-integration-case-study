@EndUserText.label : 'SuccessFactors employee replication log'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zsf_repl_log {
  key client     : abap.clnt not null;
  key log_id     : sysuuid_x16 not null;
  pernr          : abap.numc(8);
  begda          : abap.dats;
  first_name     : abap.char(40);
  last_name      : abap.char(40);
  bukrs          : abap.char(4);
  kostl          : abap.char(10);
  persg          : abap.char(1);
  status         : abap.char(1);   // S = success, E = error, R = reprocessed
  message_text   : abap.char(220);
  created_at     : timestampl;
  changed_at     : timestampl;
  changed_by     : abap.char(12);
}
