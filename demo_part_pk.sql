
set echo off
set feedbac off

set sqlprompt "SQL> "

-- 20 digits...
column the_id       format 99999999999999999999
column date_part    format 9999999999999
column seq_part     format 9999999
column the_msg      format A40
column vsize_of_id   format 99999999 

column date_part format A25
column seq_part  format A8

set feedback on
set echo on

drop sequence n_seq ;

set echo off

clear screen


prompt 
prompt 
prompt
prompt  [ What: Use Date +  SEQUENCE as PK field.
prompt          then show size in bytes ]
prompt 
prompt

accept hit_enter prompt 'Try it...  '

set echo on

drop sequence n_seq ;
drop table pt_testkey ;

clear screen 

create sequence n_seq 
    minvalue 1
    start with  999994
    maxvalue 999999 
    cycle;

create table pt_testkey  
( id  number ( 25)  primary key
, msg varchar2(4000)
);


set echo off

prompt 
prompt Check: Sequence and future table..
prompt 
accept hit_enter prompt 'now use them.  '

clear screen

set feedback on
set echo on


select  
    to_char ( sysdate, 'YYYY DDD SSSSS' )       as date_part
  , to_char ( n_seq.nextval , '099999' )        as seq_part
  , to_number ( 
      to_char ( sysdate, 'YYYYDDDSSSSS' ) ||
      to_char ( n_seq.nextval, '099999MI' ) ) as the_id
from dual
connect by level < 9 
;

set echo off
set feedback off

prompt
prompt Check the values..
prompt 
prompt 
accept press_enter prompt 'Now try to insert into table, and check size..'

clear screen

set feedback on
set echo on

insert into  pt_testkey 
select  
    to_number ( 
      to_char ( sysdate, 'YYYYDDDSSSSS' ) ||
      to_char ( n_seq.nextval, '099999MI' ) ) as id
  , 'date: '|| to_char ( sysdate, 'YYYY DDD SSSSS' ) || ', ' 
     || 'seq_part: ' || to_char ( n_seq.nextval , '099999' ) || '.'  as msg
from dual
connect by level < 9 
;


select id           as the_id
    , vsize ( id )  as vsize_of_id
from  pt_testkey
order by id;

set echo off

prompt
prompt 
prompt Check; The size of that huuuge number key is still only 10bytes
prompt 
prompt homework: how many objections to using this construct as a PK ??
prompt
prompt
prompt ... Back to ppt...
prompt 
prompt 
