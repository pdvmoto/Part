
/* 

  demo_part_1: global indexes are Bad, but local indexes also cause extra work.

  ppt needed:
    - show finding 1 or few records via index.
    - show how each local index takes 2-4 reads + 1 read to access table.
    - main message: always limit nr of partitions to search.

*/

set echo off

alter session set optimizer_mode = first_rows;

drop index pt_li_a ;
drop index pt_gi_a ;

set echo off
set linesize 120 
set timing off

clear screen

prompt 
prompt 
prompt Show how an index can pinpoint a record...
prompt 
prompt  

set echo on

create index pt_gi_a on pt ( active ) GLOBAL ; 

Exec dbms_stats.gather_table_stats(user, 'PT', null, null);


set echo off
prompt 
accept hit_enter prompt 'Global Index to use in a Select ...'
prompt 

set autotrace on explain
set echo on

select id, active, amount from pt where active = 'Y' ; 

set echo off
prompt 
accept hit_enter prompt 'we found some records (one in each partition)...'
prompt 
set echo on

set autotrace on stat
/

set autotrace off

set echo off
prompt 
prompt 
accept hit_enter prompt 'Effort: walk index blvl and jump into table for each record.'
prompt 

clear screen

prompt
prompt Now try local Index: think of it as a (smaller) index for each partion.
prompt 

set echo on

drop index pt_gi_a ;
create index pt_li_a on pt ( active ) LOCAL ; 

Exec dbms_stats.gather_table_stats(user, 'PT', null, null);

set echo off

prompt 
accept hit_enter prompt 'Now with local index, same SQL,  find same rows... '
prompt 

set autotrace on explain
set echo on

select id, active, amount from pt where active = 'Y' ; 

set echo off
prompt
accept hit_enter prompt 'Notice Partition-Range; scanning multiple partitions... '
prompt 

set autotrace on stat
set echo on
/

set echo off
set autotrace off

prompt  
accept hit_enter prompt 'Effort: for Each partition, index-range plus jump into table'
prompt  

prompt  
prompt Notice the extra work when looping over local index(es) ..
prompt When working with 1000s of partitions, this quicly escalates.
prompt  

set echo on
drop index pt_li_a ;

