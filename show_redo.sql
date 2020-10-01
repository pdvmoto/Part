
-- purpose: use this to show redo since last measure, 
-- it will clean out and re-start the measurement-process 
-- (and it does commits!)

DEFINE THE_STATNAME = "'redo size'"


/**** 

-- Initiate.. 

-- nb: being lazy here, but username and sysdate could 
-- and should be picked up from sys.aud$ 

create table log_stats as
select s.audsid, st.statistic# as stat
, st.value as val_start, st.value as val_end, st.value as diff
from v$sesstat st 
,  v$session s
where st.sid = s.sid
and 1=0 ;

-- optional so others can use it
grant insert, update, select, delete on log_stats to public ;
create public synonym log_stats for log_stats;

-- make sure it is empty
delete from log_stats ;

-- to start (next) collection
insert into log_stats
select s.audsid, st.statistic# as stat
, st.value as val_start, null, null
from v$sesstat st 
,  v$session s
,  v$statname n
where st.sid = s.sid
and  n.statistic# = st.statistic#
and  n.name = &THE_STATNAME
and s.audsid = 
( select max ( a.audsid ) -- lazyyee
  from v$session a
     , v$mystat my
  where a.sid = ( select distinct sid from v$mystat)
);

commit ;

***/ 

-- -
-- prompt Did some heavy stuff, now collect+show stats since... 
-- -

set feedback off

-- to stop collection and calculate diff (room for improvement!):
update log_stats ls 
set    ( val_end   , diff                    ) =
( select st.value  , st.value - ls.val_start 
  from v$sesstat st 
     , v$session s
  where st.sid = s.sid
  and   ls.audsid = s.audsid
  and   ls.stat   = st.statistic#
  and   s.audsid = 
  ( select max ( a.audsid )
    from v$session a
       , v$mystat my
    where a.sid = ( select distinct sid from v$mystat)
  )
)
where ls.audsid = 
  ( select max ( a.audsid ) -- lazyyee, can do better.
    from v$session a
       , v$mystat my
    where a.sid = ( select distinct sid from v$mystat)
  )
and ls.stat = ( select statistic# from v$statname where name = &THE_STATNAME )
;

-- to report (on whole table!)
select n.name, ls.stat as statnr, ls.diff
from log_stats ls, 
v$statname n
where n.statistic# = ls.stat
and 1=0
and diff <> 0
order by audsid, stat;

set feedback on

-- report on my redo size only
column name format A20 
column diff format 999,999,999,999 
column redo_kb format 999,999.9 
column statnr format 9999 

select n.name /* , ls.stat as statnr, ls.diff */  
     , ls.diff /( 1024) as redo_kb
from log_stats ls, 
v$statname n
where n.statistic# = ls.stat
and ls.diff <> 0
and n.name in ( &THE_STATNAME )
order by audsid, stat;

accept hit_enter prompt 'Note the redo, Hit Enter to Continue...'

-- note: 
-- most data is "counters" there is no "timing" information,
-- so... we still do not know where the waiting-time is spent!
-- => nothing beats a 10046 trace.

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

