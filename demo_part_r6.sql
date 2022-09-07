
-- experiment with null-columns..
-- in the end it all makes sense.. 

drop table pt_ccc ;
drop table pt_cc ;
drop table pt_c ;
--drop table tp2 ;
--drop table tp1 ;

set echo on

create table pt_c (
  id          number  -- mind the null...
, pt_id       number  
, created_dt  date default sysdate
, c_type      varchar2 (10) 
, payload     varchar2 (200)
, constraint pt_c_pk    primary key ( pt_id, id) USING INDEX LOCAL
, constraint pt_c_fk_pt foreign key ( pt_id) references pt ( id )
)
partition by
 reference ( pt_c_fk_pt)
;

-- mind the un-constrained fields id and parent_id, 
-- let's try
insert into pt_c ( id, pt_id ) values ( null, null ) ;  -- 
insert into pt_c ( id, pt_id ) values ( 1, null ) ;  -- 
insert into pt_c ( id, pt_id ) values ( null, 1 ) ;  -- 
insert into pt_c ( id, pt_id ) values ( 1, 1 ) ;  -- OK! 


-- now creating the cc: needs nn
create table pt_cc (
  id            number  
, pt_c_id       number  not null  -- works with just this constr.
, pt_id         number  --not null -- the grandparent doesnt need... ??
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

insert into pt_cc ( id, pt_c_id, pt_id ) values ( null, null, null ) ;  -- 
insert into pt_cc ( id, pt_c_id, pt_id ) values ( 1   , null, null ) ;  -- 
insert into pt_cc ( id, pt_c_id, pt_id ) values ( 1   , 1   , null ) ;  -- 
insert into pt_cc ( id, pt_c_id, pt_id ) values ( 1   , 1   , 1 ) ;  -- OK! 
insert into pt_cc ( id, pt_c_id, pt_id ) values ( null, 1   , 1 ) ;  -- 


