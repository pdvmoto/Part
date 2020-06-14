
-- purpose: helper-script to show_redolsql.
-- this part does re-set the redo-stats collection in lo_stats
-- it will clean out and re-start the measurement-process 
-- (and it does commits!)
--
-- more info: show_redo.sql
-- 

DEFINE THE_STATNAME = "'redo size'"


-- make sure it is empty again
set feedback off

delete from log_stats ;

-- to re-start collection

insert into log_stats
select s.audsid, st.statistic# as stat
, st.value as val_start, null, null
from v$sesstat st 
  ,  v$session s
  ,  v$statname n
where st.sid = s.sid
and n.statistic# = st.statistic#
and n.name = &THE_STATNAME
and s.audsid = 
( select max ( a.audsid )
  from v$session a
     , v$mystat my
  where a.sid = ( select distinct sid from v$mystat)
);

commit ;

-- accept hit_enter prompt 'Ready for next measurement, Hit Enter to Continue...'

