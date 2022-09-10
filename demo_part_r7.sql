
-- demo non-use of bitmap indexes on large partitioned table

-- favour index, avoid surprises!
alter session set optimizer_mode = first_rows_1;
set autotrace off

cle scre 
set echo on
set feedb on

cle scre
-- demo use/non-use of bitmap indexes on large partitioned table

alter table  t_ccc add  ( att1 varchar2(32), m1 number  ) ;
alter table pt_ccc add  ( att1 varchar2(32), m1 number  ) ;

update pt_ccc set att1 = 'V' || to_char ( mod ( pt_id, 999) )
                , m1   = mod ( pt_id, 200 ) 
;

update t_ccc set att1 = 'V' || to_char ( mod ( t_id, 999) )
               , m1   = mod ( t_id, 200 ) 
;

set echo off

prompt .
prompt we added two columns with simple data
prompt .
host read -p "put bitmap indexes on it..."


drop index pt_ccc_ba1;
drop index pt_ccc_bm1;
drop index  t_ccc_ba1;
drop index  t_ccc_bm1;

set echo on

create bitmap index pt_ccc_ba1 on pt_ccc ( att1 ) local ; 
create bitmap index pt_ccc_bm1 on pt_ccc ( m1 ) local ; 

create bitmap index  t_ccc_ba1 on  t_ccc ( att1 )  ; 
create bitmap index  t_ccc_bm1 on  t_ccc ( m1 )  ; 

set echo off

prompt .
prompt two columns with bitmap indexes on them. note: LOCAL
prompt let see how that works
prompt .
host read -p "first.. bitmap indexes on T, as intended "

set linesize 130
set echo on
set autotrace on explain 

select 
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

l
/

set echo off

prompt .
prompt how much io was needed ?
prompt .

host read -p "bitmap index on T, read few blocks..."

set autotrace on explain

set echo on

select 
count (*), max (created_dt) as lastdd from pt_ccc t
where att1 = 'V1'
and m1 = 1 
and pt_id < 30000  -- try for several  partitions
;

set echo off

prompt .
prompt the PT also has bitmap indexes..
prompt but needs to scan mulitple-local bitmap-idex
prompt .

host read -p "how is use of bitmap indexes on PT, multi-partition ?"

set autotrace on stat

cle scr
set echo on

l
/

set echo off
cle scre
set echo on

/

set echo off
prompt .
prompt And how much io was done on the PT
prompt .

host read -p "bitmap index on partitions of PT, how many blocks..."

prompt .
prompt Bitmap-indexes are local, 
prompt but typical use may cover many/all partitions. 
prompt .
prompt 1. CBO seems to use less of the bitmap-inxes (is solvable..)
prompt 2. looping over partitions can (will) hurt performance...
prompt .
prompt note: I'd like a partial-global index here...?
prompt . 
