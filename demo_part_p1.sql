
/* 
demonstrate partial indexing and what it does to explain plan.

*/


drop index pt_gi_a ; 
drop index pt_li_a ; 

ALTER TABLE pt MODIFY PARTITION pt_4 INDEXING OFF;

create index pt_li_a on pt ( active ) LOCAL ;


set autotrace on explain

select id, active from pt where active='Y';

set autotrace on stats

/

prompt 
prompt check explain plan
prompt


