

-- delete records versus drop partition.

set echo off
set autotrace off
set verify off
set timing off

prompt .
prompt Resetting stats for measuring redo..
prompt (the nr you see is the redo from previous activity, if any)
prompt .

@show_redo_reset

clear screen

prompt .
prompt [ the ppt has shown what we will do : delete-T, delete-PT, and Drop-P. ]
prompt .
prompt Ready to demonstrate and measure redo.
prompt .

accept hit_enter prompt 'Hit Enter to Continue...'

set timing on
set autotrace on stat
set echo on

delete from t where id < 10000;

set echo off
set autotrace off
set timing off
set feedback off

prompt .
prompt Conventional Table, how much redo...? 
prompt .

@show_redo

set timing on
set autotrace on stat
set feedback on
set echo on

delete from pt where id < 10000;

set echo off
set timing off
set autotrace off
set feedback off

prompt .
prompt Partitioned table, how much redo...?
prompt .

@show_redo

set timing on
set autotrace on stat
set feedback on
set echo on

alter table pt DROP PARTITION pt_2 ;

set echo off
set timing off
set autotrace off
set feedback off

prompt  
prompt Dropped a Partition, how much redo...?
prompt  

prompt  

@show_redo

set feedback on

clear screen 

prompt .
prompt We have seen: 
prompt - delete 10K records from Conventional table;             13000 K redo.
prompt - delete 10K records from Partitioned table, 1 partition; 15000 K redo.
prompt - remove 1 Partition with 10K records;                     0.02 K redo..
prompt .
prompt Bonus Question (homework!) will redo increase dropping Large Partition ? 
prompt .

accept hit_enter prompt 'Hit Enter to Continue...'

clear screen 

prompt
prompt
Prompt Voila!
prompt  
prompt Main Point Made.
prompt 
prompt 
prompt When you do this with Real Volumes of data, 
prompt the difference in effort and in time is noticable.
prompt 
prompt Removing data with "drop partition" Saves ...
prompt - Saves Redo-effort (logwriter, archiving, standby...)
prompt - Saves Time! 
prompt 
prompt This is it; Best Use of Partitioning (imho)
prompt 
prompt 
prompt back to ppt...
prompt .
