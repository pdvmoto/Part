

-- aggregate data over latest partition, for exmaple, last day..

set linesize 150
set echo off

prompt 
prompt Do an Aggregate of some data, 
prompt data that would normally be in 1 or few partitions.
prompt 
prompt 
prompt First on the conventional table T, then on PT
prompt 

set autotrace on explain
set feedb off
set echo on


select trunc ( id / 1000 ) as range
     , sum (amount)    as sumtotal
from t 
where id < 10000
group by trunc(id / 1000)  
order by 1;

set echo off
set feedb off

prompt  
prompt Total of the last range, CBO decided on FTS (I hope...)
prompt (in PT we know they will be in the last partition)
prompt  

accept hit_enter prompt 'Hit enter to see the stats of the Qry... '

set feedb off

set autotrace on stat
set echo on

/

set echo off
set feedb off
set autotrace off

prompt 
prompt Check the effort of the Qry, 6000 gets, whole table... '
prompt 
accept hit_enter prompt 'hit enter to see same SQL on the PT'


set autotrace on explain
set feedback off
set echo on


select trunc ( id / 1000 ) as range
     , sum (amount)    as sumtotal
from pt 
where id < 10000
group by trunc(id / 1000 )  
order by 1;

set echo off
set feed off

prompt 
prompt Check what happened on a Partitioned table. 
prompt CBO Knows it only needs (1) specific partition(s).
prompt 
accept hit_enter prompt 'hit enter to see the stats of the QRY'

set autotrace on statistics 
set feedback off
set echo on

/

set echo off
set autotrace off

prompt 
prompt The nr of db-blocks scanned, is comparably less.
prompt The required partition(s) can be a fraction of the table.
prompt
prompt Notice: No Index was touched in the making of these aggregates...
prompt 
accept hit_enter prompt 'hit enter to continue '

prompt
prompt Partitrion - Elimination : can help reduce the amount of data to Search..
prompt 
prompt Back to ppt..
prompt




