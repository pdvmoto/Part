

alter session set optimizer_mode = first_rows;

set echo on

-- drop index pt_li_a ;
create index pt_li_a on pt ( active ) GLOBAL ; 
exec dbms_stats.gather_table_stats(user, 'PT');

set autotrace on
select id, active, amount from pt where active = 'Y' ; 
set autotrace off

set echo off

accept hit_enter prompt 'Note the effort, 1x index and 6 jumps into table'


set echo on
drop index pt_li_a ;
create index pt_gi_a on pt ( active ) LOCAL ; 
exec dbms_stats.gather_table_stats(user, 'PT');

set autotrace on
select id, active, amount from pt where active = 'Y' ; 
set autotrace off

set echo off

accept hit_enter prompt 'Note the effort, 6x index-range plus 6x jump into table'

prompt notice the extra work when looping over local index ..

drop index pt_gi_a ;

