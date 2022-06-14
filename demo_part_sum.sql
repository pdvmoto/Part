

-- aggregate data over latest partition, for exmaple, last day..

set linesize 150
set echo off

alter session set optimizer_mode=all_rows ;

clear screen

prompt 
prompt [ What we will do : Aggregate of some data, on T and PT ] 
prompt 
prompt Data that would normally be in 1 or few partitions.
prompt 
prompt 
accept hit_enter prompt 'Hit enter to see Query and plan ... '

clear screen 

set feedb off
set echo on


select trunc ( id / 10000 ) as range
     , count (*) as nr_items, sum (amount)    as sumtotal
from T 
where id between 10000 and 19999
group by trunc(id / 10000)  
order by 1;

set echo off

prompt  
prompt We counted all records inside a range. 
prompt
accept hit_enter prompt "Let see the explain plan..."

clear screen
prompt

set autotrace on explain
set echo on

l
/

set echo off

prompt  
prompt CBO decided on FTS (I hope), but we know data is in limited range
prompt 
accept hit_enter prompt 'Now let see the stats of the Qry... '

clear screen
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

clear screen
prompt
prompt Here we run same SQL on the Partitioned Table PT ...
prompt 

set autotrace off
set feedback off
set echo on

select trunc ( id / 10000 ) as range
     ,  count (*) as nr_items, sum (amount)    as sumtotal
from PT 
where id between 10000 and 19999
group by trunc(id / 10000 )  
order by 1;

set echo off
set feed off
set echo off

prompt
prompt We counted records inside a range And we Know that is 1 partition.
prompt
accept hit_enter prompt "Let see the explain plan..."

clear screen
prompt

set autotrace on explain
set echo on


l
/

set echo off
set feedback off

prompt 
prompt CBO Knows it only needs (1) specific partition(s).
prompt 
accept hit_enter prompt 'hit enter to see the stats for this Query'

clear screen
prompt

set autotrace on statistics 
set feedback off
set echo on

l
/

set echo off
set feedb off
set autotrace off

prompt 
prompt The nr of db-blocks scanned, is comparably less.
prompt The required partition(s) can be a fraction of the table.
prompt
prompt Notice: No Index was touched in the making of these aggregates...
prompt 
accept hit_enter prompt 'hit enter to continue '

/* 

Optional: summerize the numbers, demonstrate that 1 partition was 25% of the effort..

*/

clear screen

prompt
prompt
prompt Summary: 
prompt 
prompt When searching throught the conventional table we scanned....        5700 blocks.
prompt
prompt When searching throught the partitioned, 1 partition, we scanned.... 1400 blocks.
prompt
prompt 
prompt We were "lucky": 
prompt 
prompt 1. our data was located in 1 partition, 
prompt And
prompt 2. Oracle, with SQL and DDL, _knew_ we only needed that one parittion.
prompt
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




