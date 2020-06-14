

-- delete records versus drop partition, global/local index..
-- since 12.x: Effort for update-global-indexes still there, but moved to background 
--  
-- only use as extra... incomplete demo, index-maintenance not "counted in session" 

-- 
--  ppt needed : partitioned-table + global index + local index... 
--  explain removal of partition, and effect on global indes (pointers)
-- 

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

create index pt_gi_pay on pt ( payload) GLOBAL ;

set echo off

accept hit_enter prompt 'Hit Enter to Continue...'

prompt .
prompt Resetting stats for measuring redo..
prompt (the nr you see is the redo from previous activity, if any)
prompt .

@show_redo_reset

clear screen

prompt .
prompt Redo-stats are reset, ready to drop partition and measure redo.

accept hit_enter prompt 'Hit Enter to Continue...'

set autotrace on stat
set echo on

alter table pt drop partition pt_3 ; 

alter index pt_gi_pay rebuild /* force the maintenance in this session */ ;

set echo off
set autotrace off
set feedback off

prompt .
prompt Dropped 1 partition, 10K rows, and rebuilt the index, how much redo...? 
prompt .
prompt [ Future demo: show unusable-idex, 
prompt   and explain maintenance by SYS.PMO_DEFERRED_GIDX_MAINT_JOB ] 
prompt .

@show_redo

prompt .   
prompt Now replace with a local index.
prompt .

set feedback on
set echo on

drop   index pt_gi_pay ;
create index pt_li_pay on pt ( payload) LOCAL ;

set echo off
set feedback on

prompt .
prompt Reset statistics for measuring (notice the redo from index-creation)
promp . 

@show_redo_reset

clear screen

set echo on
set feedback on

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
prompt We have seen effect of Global vs Local index on partition operation: 
prompt - drop partition, 10K records with global index,          13    M redo.
prompt - drop partition, 10K records with only local indexes,     0.04 M redo.
prompt .
prompt Bonus Question (homework!) how + which background process... ? 
prompt .

accept hit_enter prompt 'Hit Enter to Continue...'

clear screen 

prompt .
prompt When you do this with Real Volumes of data, 
prompt the difference in effort and in time is noticable.
prompt .
prompt Best: Avoid Global Indexes, Please.
prompt .
prompt back to ppt...
prompt .
