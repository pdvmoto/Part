

-- delete records versus drop partition.

set echo off
set autotrace off
set verify off
set timing off

prompt  
prompt Resetting stats for measuring redo..
prompt (the nr you see is the redo from previous activity, if any)
prompt  

@show_redo_reset

clear screen

prompt  
prompt [ What we will do : delete-from-T, delete-from-PT, and Drop-Partition. ]
prompt  
prompt Ready to demonstrate and measure redo.
prompt  

accept hit_enter prompt 'Hit Enter to Continue...'

set autotrace on stat
set echo on

DELETE from t where id < 10000;

set echo off
set autotrace off
set timing off
set feedback off

prompt  
prompt Deleted from Conventional Table, how much redo...? 
prompt  

@show_redo

set autotrace on stat
set feedback on
set echo on

DELETE from pt where id < 10000;

set echo off
set timing off
set autotrace off
set feedback off

prompt  
prompt Deleted from Partitioned table, how much redo...?
prompt  

@show_redo

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

prompt  
prompt We have seen: 
prompt - delete 10K records from Conventional table;             23000 K redo.
prompt - delete 10K records from Partitioned table, 1 partition; 26000 K redo.
prompt - remove 1 Partition with 10K records;                     0.04 K redo..
prompt  
prompt Bonus Question (homework!) Will redo increase when dropping Large Partition ? 
prompt  

accept hit_enter prompt 'Hit Enter to Continue...'

clear screen 

prompt
prompt
Prompt Voila!
prompt  
prompt Main Point Made.
prompt 
prompt 
prompt DROP PARTITION Saves ...
prompt
prompt - Saves Redo-effort (logwriter, archiving, standby...)
prompt
prompt - Saves Time! 
prompt 
prompt
prompt On Volumes, This Counts.
prompt
prompt 
prompt back to ppt...
prompt  
