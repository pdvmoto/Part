
-- try ref-partitions with tech-keys, e.g. table only knows of 1st level parent.

-- note: depends on demo_part.sql to create+fill parent table

drop table pt_ccc ; 
drop table pt_cc ; 
drop table pt_c ; 
--drop table tp2 ; 
--drop table tp1 ; 

set echo on

create table pt_c (
  id          number  not null
, pt_id       number  not null
, created_dt  date default sysdate
, c_type      varchar2 (10) not null
, payload     varchar2 (200) 
, constraint pt_c_pk    primary key ( pt_id, id) USING INDEX LOCAL
, constraint pt_c_fk_pt foreign key ( pt_id) references pt ( id ) 
)
partition by 
 reference ( pt_c_fk_pt)
;


create table pt_cc (
  id            number  not null
, pt_c_id       number  not null
, pt_id         number  not null
, created_dt    date
, cc_type       varchar2(10)
, payload       varchar2(200)
, constraint pt_cc_pk primary key ( pt_id, pt_c_id, id) 
, constraint pt_cc_fk_pt_c foreign key ( pt_id, pt_c_id ) 
                       references pt_c ( pt_id,      id) 
)
partition by 
 reference ( pt_cc_fk_pt_c ) 
;


-- the nr4 child..

create table pt_ccc (
  id            number  not null -- effectively the pt_ccc_id
, pt_cc_id      number  not null 
, pt_c_id       number  not null 
, pt_id         number  not null 
, created_dt    date
, ccc_type      varchar2(10)
, payload       varchar2(200)
, constraint pt_ccc_pk primary key       ( pt_id, pt_c_id, pt_cc_id, id) 
, constraint pt_ccc_fk_pt_cc foreign key ( pt_id, pt_c_id, pt_cc_id ) 
                        references pt_cc ( pt_id, pt_c_id,       id) 
)
partition by 
 reference ( pt_ccc_fk_pt_cc ) 
;

-- now put some data in pt_c: 2 records for every parent

insert into pt_c ( id, pt_id, created_dt, c_type, payload ) 
     select  rownum, id, sysdate, 'TYP:C', 'parent_payld: '|| substr ( payload, 1, 150) 
from pt ;

insert into pt_c ( id, pt_id, created_dt, c_type, payload ) 
     select  rownum+1 , id, sysdate, 'TYP:C', 'parent_payld: '|| substr ( payload, 1, 150) 
from pt ;

commit ;


set timing on

-- put data in the pt_cc
-- theh cc
insert into pt_cc ( id, pt_id, pt_c_id, created_dt,  cc_type,  payload ) 
         select rownum, pt_id,      id,    sysdate, 'TYP:CC', 'p_cc_payld: '|| substr ( payload, 1, 150) 
from pt_c ;

insert into pt_cc ( id, pt_id, pt_c_id, created_dt,  cc_type,  payload ) 
       select rownum+1, pt_id,      id,    sysdate, 'TYP:CC', 'p_cc_payld: '|| substr ( payload, 1, 150) 
from pt_c ;

commit ;

-- the ccc
insert into pt_ccc ( id, pt_id, pt_c_id, pt_cc_id, created_dt,  ccc_type,  payload ) 
          select rownum, pt_id, pt_c_id,       id,    sysdate, 'TYP:CCC', 'p_cc_payld: '|| substr ( payload, 1, 150) 
from pt_cc ;

insert into pt_ccc ( id, pt_id, pt_c_id, pt_cc_id, created_dt,  ccc_type,  payload ) 
        select rownum+1, pt_id, pt_c_id,       id,    sysdate, 'TYP:CCC', 'p_cc_payld: '|| substr ( payload, 1, 150) 
from pt_cc ;

commit ; 

EXEC DBMS_STATS.gather_table_stats(user, 'PT_C', null, 1);
EXEC DBMS_STATS.gather_table_stats(user, 'PT_CC', null, 1);
EXEC DBMS_STATS.gather_table_stats(user, 'PT_CCC', null, 1);

set timing off
