
/* 
 demo_part_reset.sql: quick reset, no stats

*/


-- table with integer-key, add some values, 
-- size it to be easily re-startable and no wait times.
-- name partitions explicit to allow easy drop.
-- 

-- easier to read.
set sqlprompt "SQL> " 

-- two tables, partitioned and conventional, for comparison
-- also consider: base-table with data-set for re-deployments

drop table pt ; 
drop table  t ; 

purge recyclebin ; 

clear screen

prompt  
prompt ____  original demo starts here... _____
prompt 

set echo on

create table pt 
( id                number ( 9,0)    -- the PK and partitioning-key.
, active            varchar2 ( 1 )   -- Y/N, show small set of Active.
, amount            number ( 10,2 )  -- supposedly some amount of money.
, dt                date             -- a date, case we want history stuff 
, payload           varchar2 ( 200 ) -- some text
, filler            varchar2 ( 750 ) -- some data to create 1K recordsize
)
partition by range ( id )  interval ( 10000 ) 
(   partition pt_1 values less than ( 10000 )  
  , partition pt_2 values less than ( 20000 ) 
  , partition pt_3 values less than ( 30000 ) 
  , partition pt_4 values less than ( 40000 ) ) ;

set echo off

prompt .

-- beware, constraint in table-def generates global index
create unique index pt_pk on  pt ( id ) local ; 

alter table pt add constraint pt_pk primary key ( id ) ;

create table t 
( id number ( 9,0)   
, active            varchar2 ( 1 )  
, amount            number ( 10,2 )
, dt                date          
, payload           varchar2 ( 200 ) 
, filler            varchar2 ( 750 ) 
) ;

create unique index t_pk on  t ( id ) ; 

alter table t add constraint t_pk primary key ( id ) ;

-- 40K records, nice number for timing, effort, demo.. 
set timing on

set feedback on
set timing on
set echo on

--
-- fill with deliberately funny, compressible data
--
insert into pt
select 
   trunc ( rownum -1)                               -- sequene...
,  decode ( mod ( rownum, 10000), 0, 'Y', 'N' )     -- every 1/1000 active=Y
,  mod ( rownum-1, 10000 ) / 100                    -- 0-100, two decimals
,  (sysdate - rownum )                              -- some dates
,  rpad ( to_char (to_date ( trunc ( rownum ), 'J'), 'JSP' ), 198) -- words
,  rpad ( ' ', 750 )                                -- blanks
from dual
connect by rownum <= 40000 ;

set echo off
set timing off

commit ; 

set echo on

--
-- and copy into conventional table.
--
insert into t select * from pt ;

-- 
--  add extra index for lookups, gather stats..
-- 

create index pt_li_pay on pt ( payload, filler, amount) local ;
create index  t_i_pay  on  t ( payload, filler, amount) ;

EXEC DBMS_STATS.gather_table_stats(user, 'PT', null, 1);
EXEC DBMS_STATS.gather_table_stats(user, 'T' , null, 1);

set echo off

column table_name format A20  
column part_name  format A20 
column hv format 999999 head High_val

select table_name, '-' as part_name, num_rows 
from user_tables
where table_name like 'T'
order by table_name ; 

select table_name, partition_name part_name, num_rows 
from user_tab_partitions
where table_name like 'PT%'
order by table_name, partition_name ; 

prompt 
prompt 
prompt Demo Ready... : 
prompt 
prompt We have two tables 
prompt T    conventional, all records in 1 table-segment 
prompt PT   partitioned, with partitions of 10K records each.
prompt 
prompt 

