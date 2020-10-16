
/*** 
 r1: demo ref partitioning


 create ref-prt

 options: 
 - consider renaming partitions by pl-sql, see stack overflow

 
***/
column table_name format A20
column index_name format A20
column status format A10

set echo off

-- easier to read.
set sqlprompt "SQL> "

set feedback on
set timing off

drop table mmt_chd_chd ;
drop table mmt_chd ; 
drop table mmt ; 
drop table pt ; 

purge recyclebin ; 

-- also remove traces of previous demo to get correct counts
drop table pt ; 

clear screen

set echo off

prompt
prompt [ What we will do : create a parent, child and grandchild table. ]
prompt
prompt parent     : MMT
prompt child      : MMT_CHD
prompt grandchild : MMT_CHD_CHD
prompt
prompt Ready to demonstrate some Ref-Partitioning.
prompt
accept  hit_enter prompt "hit enter to start creating tables..." 
prompt

clear screen
set echo on

create table mmt (
  ID number 
, dt date
, doctype varchar2(10)
, owner varchar2(32)
, vrt_id number
, tma_id number
, constraint mmt_pk primary key ( id) 
)
partition by range (id)
interval ( 10000 ) 
( partition mmt_p1 values less than (10)
, partition mmt_p2 values less than (20)
, partition mmt_p3 values less than (30)
, partition mmt_p4 values less than (40)
);

set echo off

prompt
accept  hit_enter prompt "check parent table..." 
prompt 

clear screen
set echo on

create table mmt_chd (
  mmt_id number not null
, chd_id number not null 
, object_name varchar2(32)
, constraint mcd_pk primary key ( mmt_id, chd_id )
, constraint mcd_mmt_fk foreign key ( mmt_id ) references mmt(id) ) 
partition by reference (mcd_mmt_fk );

set echo off
prompt
accept  hit_enter prompt "check child table, mmt_chd..." 
prompt

clear screen
set echo on

create table mmt_chd_chd (
  mmt_id number not null
, chd_id number not null
, ccd_id number not null
, column_name varchar (32 ) 
, constraint ccd_pk primary key ( mmt_id, chd_id, ccd_id )
, constraint ccd_mcd_fk foreign key ( mmt_id, chd_id ) references mmt_chd (mmt_id, chd_id) ) 
partition by reference (ccd_mcd_fk );

set echo off
prompt
accept  hit_enter prompt "check grandchild-table, mmt_chd_chd..." 
prompt

clear screen
set echo on

-- insert some data in parent..

insert into mmt 
select user_id , u.created 
, u.default_tablespace
, u.username 
, 0, 0
--, u.*
from dba_users u
where u.user_id < 40 
order by u.user_id desc ;  

commit ; 

set echo off
prompt
accept  hit_enter prompt "parent table filled... " 
prompt

clear screen
prompt

set echo on

insert into mmt_chd
select u.user_id, o.object_id, o.object_name 
--, o.* 
from
 dba_objects o 
 , dba_users u
where object_type = 'TABLE'
and o.owner = u.username
and u.user_id in ( select id from mmt );

commit ; 

set echo off

prompt
accept  hit_enter prompt "first child table, mmt_chd, filled... " 
prompt

clear screen
prompt

set echo on

insert into mmt_chd_chd
select mmt.id, mcd.chd_id , c.column_id, c.column_name
-- , c.*
from mmt_chd mcd
   , mmt     mmt
   , dba_tab_columns c
where mmt.id = mcd.mmt_id
and mmt.owner = c.owner 
and mcd.object_name = c.table_name 
;

commit ; 

set echo off

prompt
accept  hit_enter prompt "grand-child table, mmt_chd_chd, filled... " 
prompt

-- @show_redo_reset

set verify off
set feedback on

clear screen

prompt
prompt Now drop a top-level partition, 
prompt and verify that dependent partitions get dropped too.
prompt
prompt We have 3 tables with 4 partitions each..
set echo on

select count (*) from user_tab_partitions;

set echo off

prompt
accept hit_enter prompt "Let us drop 1 partition and re-count... "

set echo on

alter table mmt drop partition mmt_p2 ; 

select table_name, index_name, status from user_indexes 
where index_name like 'M%' or status <> 'VALID' ;

set echo off
set timing off

-- @show_redo

set echo on
select count (*) from user_tab_partitions;
set echo off

prompt
prompt
prompt 3 partitions dropped, 
prompt e.g. the drop was cascaded into the ref-partitions.... 
prompt
prompt But we seem to have a problem with indexes ??
prompt
accept hit_enter prompt "This thing works, but with some caveats..."

clear screen

prompt
prompt
prompt Voila!
prompt
prompt
prompt Main Point made: You can drop top-level partition, 
prompt and Dependents will drop too...
prompt
prompt .. but what where those indexes..
prompt
prompt back to ppt (or skip to r2..)
prompt



