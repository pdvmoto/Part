
-- try ref-partitions with tech-keys, e.g. table only knows of 1st level parent.

drop table tp3 ; 
drop table tp3 ; 
drop table tp2 ; 
drop table tp1 ; 

create table tp1 (
  id          number
, created_dt  date default sysdate
, t_type      varchar2 (10) not null
, payload     varchar2 (200) 
, constraint tp1_pk primary key ( id)
)
partition by range (id)
interval ( 10 )
( partition tp1_p1 values less than (10)
, partition tp1_p2 values less than (20)
, partition tp1_p3 values less than (30)
, partition tp1_p4 values less than (40)
);


create table tp2 (
  id            number 
, tp1_id        number 
, create_dt     date
, t2_type       varchar2(10)
, payload       varchar2(200)
, constraint tp2_pk primary key ( id) 
, constraint tp2_tp1_fk foreign key ( tp1_id ) references tp1 (id) 
)
partition by reference (tp2_tp1_fk)
;


