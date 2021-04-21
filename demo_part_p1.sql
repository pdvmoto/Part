
/* 
demonstrate partial indexing and what it does to explain plan.

*/

set echo on

drop index pt_gi_a ; 
drop index pt_li_a ; 

ALTER TABLE pt MODIFY PARTITION pt_4 INDEXING OFF;

create index pt_li_a on pt ( active ) LOCAL indexing partial ;

set autotrace on explain

select id, active from pt where active='Y';

set autotrace on stats

/

set echo off

prompt 
prompt check explain plan
prompt
accept hit_enter prompt check if partial indexins has caused scan..

set autotrace on explain

select id, active from pt where active='Y' and id < 30000 ;

set autotrace on stats

/


