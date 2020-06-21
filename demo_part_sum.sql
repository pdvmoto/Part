

-- aggregate data over latest partition, for exmaple, last day..

set linesize 150
set echo off

alter session set optimizer_mode=all_rows ;

clear screen

prompt 
prompt Do an Aggregate of some data, 
prompt 
prompt Data that would normally be in 1 or few partitions.
prompt 
prompt 
prompt First on the conventional table T, then on PT
prompt 
accept hit_enter prompt 'Hit enter to see QRY ahd plan ... '

clear screen 

set autotrace on explain
set feedb off
set echo on


select trunc ( id / 10000 ) as range
     , sum (amount)    as sumtotal
from T 
where id between 10000 and 19999
group by trunc(id / 10000)  
order by 1;

set echo off

prompt  
prompt CBO decided on FTS (I hope), but data is in limited range
prompt  
accept hit_enter prompt 'Hit enter to see the stats of the Qry... '

set feedb off

set autotrace on stat
set echo on

l
/

set echo off
set feedb off
set autotrace off

prompt 
prompt Check the effort, 5700 gets, whole table... '
prompt 
accept hit_enter prompt 'hit enter to see same SQL on the PT'


set autotrace on explain
set feedback off
set echo on


select trunc ( id / 10000 ) as range
     , sum (amount)    as sumtotal
from PT 
where id between 10000 and 19999
group by trunc(id / 10000 )  
order by 1;

set echo off
set feed off

prompt 
prompt CBO Knows it only needs (1) specific partition(s).
prompt 
accept hit_enter prompt 'hit enter to see the stats of the QRY'

set autotrace on statistics 
set feedback off
set echo on

l
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

clear screen

prompt
prompt 
prompt Voila! 
prompt
prompt Main point made.  
prompt
prompt 
prompt Partition Elimination.
prompt
prompt Reduce the amount of data to Search..
prompt 
prompt 
prompt On Large Volumes, with many partitions, This Counts
prompt
prompt
prompt Back to ppt..
prompt




