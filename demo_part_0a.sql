

-- delete records versus drop partition, global/local index..
-- since 12.x: Effort for update-global-indexes still there, but moved to background 


set echo off
set autotrace off
set verify off
set timing off

-- cleanup just in case.
drop indes pt_li_pay ;    
drop index pt_gi_pay ;

clear screen

prompt .
prompt Add a global index.
prompt .

set feedback on
set echo on

create index pt_gi_pay on pt ( payload, dt, active, id) GLOBAL ;

set echo off

accept hit_enter prompt 'Hit Enter to Continue...'

prompt .
prompt Resetting stats for measuring redo..
prompt (the nr you see is the redo from previous activity, if any)
prompt .

@show_redo 

clear screen

prompt .
prompt stats are reset, ready to drop some partitions and measure redo.

accept hit_enter prompt 'Hit Enter to Continue...'

set timing on
set echo on

alter table pt drop partition pt_3 update global indexes ; 

set echo off
set autotrace off
set timing off
set feedback off

prompt .
prompt Dropped 1 partition, 10K rows, now how much redo...? 
prompt .

@show_redo

prompt .   
prompt Now replace with a local index.
prompt .

set feedback on
set echo on

drop   index pt_gi_pay ;
create index pt_li_pay on pt ( payload, dt, active, id) LOCAL ;

set echo off
set feedback on

prompt .
prompt Reset statistics for measuring (notice the redo from index-creation)
promp . 

@show_redo

clear screen

set echo on
set feedback on
set timing on

prompt .
prompt now remove the partition with only Local Indexes
promp . 

alter table pt drop partition pt_4 ;

set echo off
set timing off
set autotrace off
set feedback off

@show_redo



clear screen

prompt .
prompt Now We have seen effect of a local index on partition operation: 
prompt - delete 10K records from Conventional table;              13   M redo.
prompt - delete 10K records from Partitioned table, 1 partition;  15   M redo.
prompt - remove 1 Partition with 10K records;                     0.01 M redo..
prompt .
prompt Bonus Question (homework!) will redo increase dropping Large Partition ? 
prompt .

accept hit_enter prompt 'Hit Enter to Continue...'

clear screen 

prompt .
prompt When you do this with Real Volumes of data, 
prompt the difference in effort and in time is noticable.
prompt .
prompt This is it; Best Use of Partitioning (imho)
prompt .
prompt back to ppt...
prompt .
