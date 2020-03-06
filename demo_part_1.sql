
/* 

  demo_part_1: global indexes are Bad, but local indexes also cause extra work.

*/

alter session set optimizer_mode = first_rows;

set linesize 120 
set timing off
set echo on


-- drop index pt_li_a ;
-- drop index pt_gi_a ;
create index pt_gi_a on pt ( active ) GLOBAL ; 
-- exec dbms_stats.gather_table_stats(user, 'PT');

set echo off
prompt .
accept hit_enter prompt 'we created a Global Index to use in a Select ...'
prompt .

set autotrace on explain
set echo on

select id, active, amount from pt where active = 'Y' ; 

set echo off
prompt .
accept hit_enter prompt 'we found some records (one in each partition)...'
prompt .
set echo on

set autotrace on stat
/

set autotrace off

set echo off
prompt .
accept hit_enter prompt 'Note the effort, 1x index and n jumps into table '
prompt .
set echo on

drop index pt_gi_a ;
create index pt_li_a on pt ( active ) LOCAL ; 
-- exec dbms_stats.gather_table_stats(user, 'PT');

set echo off
prompt .
accept hit_enter prompt 'Now with local index... '
prompt .

set autotrace on explain
set echo on
select id, active, amount from pt where active = 'Y' ; 

set echo off
accept hit_enter prompt 'Notice Partition-Range; scanning multiple partitions... '

set autotrace on stat
set echo on
/

set autotrace off
set echo off

prompt .
accept hit_enter prompt 'Note the effort, 6x index-range plus 6x jump into table'
prompt .

prompt .
prompt Notice the extra work when looping over local index(es) ..
prompt When working with 1000s of partitions, this quicly escalates.
prompt .

set echo on
drop index pt_li_a ;

