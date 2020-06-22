

-- delete records versus drop partition, global/local index..
-- since 12.x: Effort for update-global-indexes still there, but moved to background 
--  
-- only use as extra... incomplete demo, index-maintenance not "counted in session" 

-- 
--  ppt needed : partitioned-table + global index + local index... 
--  explain removal of partition, and effect on global indes (pointers)
-- 

column index_name format A15
column partition_name format A10
column status format A15

set echo off
set autotrace off
set verify off
set timing off

-- cleanup just in case.
drop index pt_li_pay ;    
drop index pt_gi_pay ;

clear screen

prompt .
prompt Add a global index.
prompt .

set feedback on
set echo on

create index pt_gi_pay on pt ( payload, filler, amount) GLOBAL ;

set echo off

-- accept hit_enter prompt 'Hit Enter to Continue...'

-- prompt .
-- prompt Resetting stats for measuring redo..
-- prompt (the nr you see is the redo from previous activity, if any)
-- prompt .

@show_redo_reset

-- clear screen

prompt 
prompt Ready to DROP a PARTITION (with GLOBAL INDEX) and measure redo.
prompt 
accept hit_enter prompt 'Hit Enter to Continue...'

clear screen
set feedb on
set echo on

alter table pt DROP PARTITION pt_1 ; 

select index_name, status from user_indexes where index_name like 'PT_G%';

set echo off

prompt 
prompt Check status of index, it may need rebuilding..
prompt 
accept hit_enter prompt 'Hit Enter to rebuild it here+now...'

set echo on

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

clear screen

prompt     
prompt Now replace with a local index.
prompt  

set feedback on
set echo on

drop   index pt_gi_pay ;
create index pt_li_pay on pt ( payload, filler, amount) LOCAL ;

set echo off
set feedback on

@show_redo_reset


prompt  
prompt Replaced the Global index with a LOCAL INDEX.
promp   
prompt Ready to DROP a PARTITION (with LOCAL INDEX) and measure redo.
prompt 
accept hit_enter prompt 'Hit Enter to Continue...'


clear screen
set feedback on
set echo on

alter table pt drop partition pt_3 ;

select index_name, partition_name, status 
from user_ind_partitions where index_name like 'PT_L%';

set echo off
set timing off
set autotrace off
set feedback off

@show_redo

clear screen

prompt  
prompt We have seen effect of Global vs Local index on partition operation: 
prompt - GLOBAL index, drop partition, index "UNUSABLE",   200 K redo.
prompt - LOCAL  index, drop partition, index USABLE,        30 K redo.
prompt  
prompt Bonus Question 1 (homework!) what happens if partiions are TB size?
prompt
prompt Bonus Question 2 (homework!) which background process, and how long... ? 
prompt  

accept hit_enter prompt 'Hit Enter to Continue...'

clear screen 

prompt  
prompt 
prompt Main Point:
prompt
prompt 
prompt Avoid Global Indexes.
prompt 
prompt 
prompt On Real Volumes, this Counts.
prompt  
prompt
prompt (but, Improvements with Every Version.)
prompt  
prompt 
prompt Back to ppt...
prompt  
