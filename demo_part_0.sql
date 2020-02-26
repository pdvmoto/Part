

-- delete records versus drop partition.

set autotrace off
set echo off
set verify off
set timing off

@show_redo 

set echo on

delete from pt where id < 10000;

set echo off

@show_redo 

set echo on

alter table pt drop partition pt_2 ;

set echo off

@show_redo

