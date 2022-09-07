
-- demo non-use of bitmap indexes on large partitioned table

set autotrace off
set echo on
set feedb on

alter table t_ccc add  ( att1 varchar2(32), m1 number  ) ;

alter table pt_ccc add  ( att1 varchar2(32), m1 number  ) ;

-- add some data in PT and T ... and we need bitmap index..
update pt_ccc 
set att1 =  'V' || to_char ( mod ( pt_id, 999) )
, m1 = mod ( pt_id, 200 ) 
where 1=1 
;

update t_ccc 
set att1 =  'V' || to_char ( mod ( t_id, 999) )
, m1 = mod ( t_id, 200 ) 
where 1=1 
;

drop index pt_ccc_ba1;
drop index pt_ccc_bm1;
drop index  t_ccc_ba1;
drop index  t_ccc_bm1;

create bitmap index pt_ccc_ba1 on pt_ccc ( att1 ) local ; 
create bitmap index pt_ccc_bm1 on pt_ccc ( m1 ) local ; 

create bitmap index  t_ccc_ba1 on  t_ccc ( att1 )  ; 
create bitmap index  t_ccc_bm1 on  t_ccc ( m1 )  ; 


set linesize 130
set echo on
set autotrace on explain 

select /*+ use index (t) */
count (*), max (created_dt) as lastdd from t_ccc t
where att1 = 'V1'
and m1 = 1 
and t_id < 30000  
;

set echo off

prompt .
prompt select from normal table, expect bitmap-and combination
prompt and notice the PK is not used, filter is on the table-row.
prompt .

host read -p "use of bitmap indexes on T, as intended "

set autotrace on stat
set echo on

/

set echo off

prompt .
prompt how much io was needed ?
prompt .

host read -p "bitmap index on T, read few blocks..."

set autotrace on explain

set echo on

select /*+ use index (t) */
count (*), max (created_dt) as lastdd from pt_ccc t
where att1 = 'V1'
and m1 = 1 
and pt_id < 30000  -- try for 2 partitions
;

set echo off

prompt .
prompt the PT also has bitmap indexes..
prompt but needs to scan mulitple-local bitmap-idex
prompt .

host read -p "how is use of bitmap indexes on PT, multi-partition ?"

set autotrace on stat

set echo on

/

set echo off
prompt .
prompt And how much io was done on the PT
prompt .

host read -p "bitmap index on PT, how many blocks..."


prompt .
prompt End of Bitmap-demo: explain that bitmap-indexes not as easily combined, 
prompt and that seaching and may need multi-partitions.
prompt .

