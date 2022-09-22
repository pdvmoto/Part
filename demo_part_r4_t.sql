
-- this version is r4_t, takes a non-partitioned table to ref-partitioning

-- try ref-partitions with tech-keys, e.g. table only knows of 1st level parent.

-- note: depends on demo_part.sql to create+fill parent table

drop table t_ccc ; 
drop table t_cc ; 
drop table t_c ; 

set autotrace off

set echo on

create table t_c (
  id          number  not null
, t_id       number  not null
, created_dt  date default sysdate
, c_type      varchar2 (10) not null
, payload     varchar2 (200) 
, constraint t_c_pk    primary key ( t_id, id) USING INDEX 
, constraint t_c_fk_t foreign key ( t_id) references t ( id ) 
)
;

host read -p "Press Enter to continue"

create table t_cc (
  id            number  not null
, t_c_id       number  not null
, t_id         number  not null
, created_dt    date
, cc_type       varchar2(10)
, payload       varchar2(200)
, constraint t_cc_pk primary key ( t_id, t_c_id, id) using index 
, constraint t_cc_fk_t_c foreign key ( t_id, t_c_id ) 
                       references t_c ( t_id,      id) 
)
;

-- the nr4 child..

create table t_ccc (
  id            number  not null -- effectively the t_ccc_id
, t_cc_id      number  not null 
, t_c_id       number  not null 
, t_id         number  not null 
, created_dt    date
, ccc_type      varchar2(10)
, payload       varchar2(200)
, constraint t_ccc_pk primary key       ( t_id, t_c_id, t_cc_id, id) using index 
, constraint t_ccc_fk_t_cc foreign key ( t_id, t_c_id, t_cc_id ) 
                        references t_cc ( t_id, t_c_id,       id) 
)
;

-- now put some data in t_c: 2 records for every parent

insert into t_c ( id, t_id, created_dt, c_type, payload ) 
     select  rownum, id, sysdate, 'TYP:C', 'parent_payld: '|| substr ( payload, 1, 150) 
from t ;

insert into t_c ( id, t_id, created_dt, c_type, payload ) 
     select  rownum+1 , id, sysdate, 'TYP:C', 'parent_payld: '|| substr ( payload, 1, 150) 
from t ;

commit ;


set timing on

-- put data in the t_cc
-- theh cc
insert into t_cc ( id, t_id, t_c_id, created_dt,  cc_type,  payload ) 
         select rownum, t_id,      id,    sysdate, 'TYP:CC', 'p_cc_payld: '|| substr ( payload, 1, 150) 
from t_c ;

insert into t_cc ( id, t_id, t_c_id, created_dt,  cc_type,  payload ) 
       select rownum+1, t_id,      id,    sysdate, 'TYP:CC', 'p_cc_payld: '|| substr ( payload, 1, 150) 
from t_c ;

commit ;

-- the ccc
insert into t_ccc ( id, t_id, t_c_id, t_cc_id, created_dt,  ccc_type,  payload ) 
          select rownum, t_id, t_c_id,       id,    sysdate, 'TYP:CCC', 'p_cc_payld: '|| substr ( payload, 1, 150) 
from t_cc ;

insert into t_ccc ( id, t_id, t_c_id, t_cc_id, created_dt,  ccc_type,  payload ) 
        select rownum+1, t_id, t_c_id,       id,    sysdate, 'TYP:CCC', 'p_cc_payld: '|| substr ( payload, 1, 150) 
from t_cc ;

commit ; 

set echo off

EXEC DBMS_STATS.gather_table_stats(user, 'T_C', null, 1);
EXEC DBMS_STATS.gather_table_stats(user, 'T_CC', null, 1);
EXEC DBMS_STATS.gather_table_stats(user, 'T_CCC', null, 1);

set echo off
cle scre


column table_name format A20
column part_name  format A20
column hv format 999999 head High_val

select table_name, '-' as part_name -- , num_rows
from user_tables
where table_name like 'T%'
order by table_name ;


prompt .
prompt We created the same 4-table hierarchy as regular, non-partitioned ables
prompt for comparision.
prompt .

set timing off
set verify off

