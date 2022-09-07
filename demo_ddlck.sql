

set echo on

drop table abc ; 

create table abc ( id number ) ; 

alter table abc add constraint abc_pk primary key ( id ) ;

insert into abc values (1) ; 

set echo off

prompt .
prompt in 2nd window: insert into abc values ( 2 ) ; 
prompt .

accept a prompt "now insert via other window" 

prompt now insert same value here :
set echo on

insert into abc values  ( 2 ) ;


prompt .
prompt and in 2nd window: insert into abc values ( 1 ) ; 

prompt .  here is would hang until ..

