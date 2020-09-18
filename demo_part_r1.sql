
/*** 
 r1: demo ref partitioning


 create ref-prt

 options: 
 - consider renaming partitions by pl-sql, see stack overflow

 
***/


drop table mmt_chd_chd ;
drop table mmt_chd ; 
drop table mmt ; 

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

create table mmt_chd (
  mmt_id number not null
, chd_id number not null 
, object_name varchar2(32)
, constraint mcd_pk primary key ( mmt_id, chd_id )
, constraint mcd_mmt_fk foreign key ( mmt_id ) references mmt(id) ) 
partition by reference (mcd_mmt_fk );

create table mmt_chd_chd (
  mmt_id number not null
, chd_id number not null
, ccd_id number not null
, column_name varchar (32 ) 
, constraint ccd_pk primary key ( mmt_id, chd_id, ccd_id )
, constraint ccd_mcd_fk foreign key ( mmt_id, chd_id ) references mmt_chd (mmt_id, chd_id) ) 
partition by reference (ccd_mcd_fk );



-- mmt: 
insert into mmt 
select user_id , u.created 
, u.default_tablespace
, u.username 
, 0, 0
--, u.*
from dba_users u
where u.user_id < 40 
order by u.user_id desc ;  

-- mmt_chd
insert into mmt_chd
select u.user_id, o.object_id, o.object_name 
--, o.* 
from
 dba_objects o 
 , dba_users u
where object_type = 'TABLE'
and o.owner = u.username
and u.user_id in ( select id from mmt );

-- mmt_chk_chd
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



-- now delete.. 

select count (*) from user_tab_partitions;

alter table mmt drop partition mmt_p1 ; 

select count (*) from user_tab_partitions;

