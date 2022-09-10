
-- try ref-partitions with tech-keys, e.g. table only knows of 1st level parent.

-- note: depends on demo_part.sql to create+fill parent table

drop table pt_ccc ; 
drop table pt_cc ; 
drop table pt_c ; 
--drop table tp2 ; 
--drop table tp1 ; 

cle scre

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

set echo off

prompt .
prompt The 1st child of PT
prompt Notice the ref-constraint.
prompt .
prompt Notice the PK: local index, two fields...
prompt Dev comment: We dont want composite keys. ...OK
prompt .
host read -p "pt_c: retry with just ID as PK..."

cle scre
set echo on

drop table pt_c ;

create table pt_c (
  id          number  not null
, pt_id       number  not null
, created_dt  date default sysdate
, c_type      varchar2 (10) not null
, payload     varchar2 (200) 
, constraint pt_c_pk    primary key ( id) USING INDEX LOCAL
, constraint pt_c_fk_pt foreign key ( pt_id) references pt ( id ) 
)
partition by 
 reference ( pt_c_fk_pt)
;

set echo off

prompt .
prompt Did that work with just the ID ?
prompt .

host read -p "pt_c: 1st child, now with PK conform standard.. ? "

cle scre

set echo on

drop table pt_c ; 

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

set echo off

prompt .
prompt So we have to carry the parent key...
prompt .

host read -p "pt_c: 1st child, again, with composite PK. "

cle scre

set echo on

-- how to do it correctly: repeat all keys.

create table pt_cc (
  id            number  not null
, pt_c_id       number  not null
, pt_id         number  not null
, created_dt    date
, cc_type       varchar2(10)
, payload       varchar2(200)
, constraint pt_cc_pk primary key ( pt_id, pt_c_id, id) using index local
, constraint pt_cc_fk_pt_c foreign key ( pt_id, pt_c_id ) 
                       references pt_c ( pt_id,      id) 
)
partition by 
 reference ( pt_cc_fk_pt_c ) 
;

set echo off

prompt . 
prompt pt_cc: the PK and FK become less readable already.
prompt .
host read -p "pt_cc: 3rd level, using parent keys for simplicity."

cle scre

set echo on

-- the nr4 child..

create table pt_ccc (
  id             number  not null -- effectively the pt_ccc_id
, pt_cc_id       number  not null 
, pt_c_id        number  not null 
, pt_id          number  not null 
, created_dt     date
, ccc_type       varchar2(10)
, payload        varchar2(200)
, constraint pt_ccc_pk primary key       ( pt_id, pt_c_id, pt_cc_id, id) using index local
, constraint pt_ccc_fk_pt_cc foreign key ( pt_id, pt_c_id, pt_cc_id ) 
                        references pt_cc ( pt_id, pt_c_id,       id) 
)
partition by 
 reference ( pt_ccc_fk_pt_cc ) 
;

set echo off

prompt .
prompt last level, using parent keys, column-names, for simplicity.
prompt Not quite happy with the field names though..
prompt .
prompt That ID column... where does it relate to... ?
prompt .
prompt Can we do better ?
prompt .

host read -p "pt_ccc: 4rd level, but let's try something... (4a)"

set timing off
