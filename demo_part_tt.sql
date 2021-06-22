

/* 

demo the case of partitioned table, 3 global indexes..
- inlist SQL
- choosing partition-scan over index.
- experiment with nr inlist-binds
- replace PK by local index, with UNQ enforced.
- remove the superfluous indexes, test, proof.

additional demos:
 - fill table and show how full-scan is first good, then bad
 - tweak statistics, to force index from start

prepare: 
 - 4 partitions, wiht significant data in BLOB (json copy of record)
 - demo part-scan and index usage.
 - demo that extra indexes dont help, even with orderby

sample data: 31 * 24      =  744 records (hrs in a month, not that much..)
sample data: 31 * 24 * 60 =  40K records (minutes in a month)

*/



-- experiment with indexes and partitions, and blob,
-- inspired by cases from JohnT.

-- earlier notes: see pi.sql

drop table t1;
drop table pt1;

drop sequence t1_seq ;
drop sequence pt1_seq ; 

create sequence t1_seq ;
create sequence pt1_seq ; 

create table t1 (
  ttm  date not null
, blb  blob not null
, oid  number not null
, lvr  number not null
, tst  date not null
, tmd  date not null
, tfn  date not null
, tnn  date not null
, pld  varchar2(4000)
) 
tablespace users
lob ( blb ) store as securefile t_secfile (
  disable storage in row chunk 16384
  cache logging  nocompress  keep_duplicates )
;

create unique index t1_pk on t1 ( oid, ttm ) ; 
alter table t1 add constraint t1_pk primary key ( oid, ttm ) ;

-- and the indexes, 3 additional, where two overlap with pk.
create index t1_idx_lvr on t1 ( oid, ttm, lvr ) ;
create index t1_idx_tst on t1 ( oid, ttm, tst ) ;
create index t1_idx_tnn on t1 ( oid, ttm, tnn ) ;


-- and the partitioned version
create table pt1 (
  ttm  date
, blb  blob
, oid  number
, lvr  number
, tst  date
, tmd  date
, tfn  date not null
, tnn  date not null
, pld  varchar2(4000)
)
STORAGE(INITIAL 65536 NEXT 64k MINEXTENTS 1 MAXEXTENTS 2147483645)
partition by range ( ttm ) interval (numtodsinterval(1, 'DAY'))
 (partition pt1_p0 values less than (to_date(' 2020-01-01', 'YYYY-MM-DD'))
  segment creation immediate
  tablespace users
  storage (initial 64k next 64k )
  lob ( blb ) store as securefile ( disable storage in row ) 
 ) ;


-- choose local or global..
-- create unique index pt1_pk on pt1 ( oid, ttm ) local ; 
alter table pt1 add constraint pt1_pk primary key ( oid, ttm ) ;

-- and the indexes, 3 additional, where two overlap with pk.
create index pt1_idx_lvr on pt1 ( oid, ttm, lvr ) ;
create index pt1_idx_tst on pt1 ( oid, ttm, tst ) ;
create index pt1_idx_tnn on pt1 ( oid, ttm, tnn ) ;

-- note: also test with local indexes.. show diff.

-- put some data in, try for 10K rows, to aim for 4 partitions?
-- 4 months, 1 rec/min.. 120 days.. 1440 min x 120 days = 15
-- try starting 01-Jan, and add rows..
-- 40K rows, 10K/month, 300/day, say... 

insert into pt1
select
   to_date ( '2021-JAN-01', 'YYYY-MON-DD' ) + (4*rownum/1440)  -- ttm
,  ''                                              -- blob, first empty
,  pt1_seq.nextval                                 -- id 
,  mod ( rownum-1, 10 )                            -- lvr 0-10
,  (sysdate - rownum/1440 )                        -- tst, some date
,  (sysdate - rownum/1440 - 2 )                    -- tmd, some date
,  (sysdate - rownum/1440 - 4 )                    -- tfn, some date
,  (sysdate - rownum/1440 - 6 )                    -- tnn, some date
,  rpad ( to_char (to_date ( trunc ( rownum ), 'J'), 'JSP' ), 20) -- some payload, words
from dual
connect by rownum <= 40000 ;

commit ;

EXEC DBMS_STATS.gather_table_stats(user, 'PT1', null, 1);


-- -- -- here -- -- -- 

-- demo of selecting from 1 partition 
select min ( ttm), max ( ttm) 
from pt1 partition for ( to_date ( '2021-01-01', 'YYYY-MM-DD') ) ; 


-- use the demo from PI.sql.
-- add 1 day of records, appro 1440, for month of May, just outside pi-demo range
-- select 1 of the two, probably (use last seq-value and time-interval)
-- then fill the month to 25 days.. 

insert into pt1
select
   to_date ( '2021-MAY-01', 'YYYY-MON-DD' ) + (rownum/1440)  -- ttm
,  ''                                              -- blob, first empty
,  pt1_seq.nextval                                 -- id 
,  mod ( rownum-1, 10 )                             -- lvr 0-10
,  (sysdate - rownum/1440 )                        -- tst, some date
,  (sysdate - rownum/1440 - 2 )                    -- tmd, some date
,  (sysdate - rownum/1440 - 4 )                    -- tfn, some date
,  (sysdate - rownum/1440 - 6 )                    -- tnn, some date
,  rpad ( to_char (to_date ( trunc ( rownum ), 'J'), 'JSP' ), 20) -- some payload, words
from dual
connect by rownum <= 1440 ;

commit ;

-- give it statistics for 1 day.
EXEC DBMS_STATS.gather_table_stats(user, 'PT1', null, 1);

-- now run SQL that will scan the partition.. (which is still small, smaller than index)
select 'fullscan ' from dual ;

-- now insert a raft of data into that first partition, 80K 
-- make the partition large and therfore inefficient


-- partition is now large, larger than index, but the statistics dont know that yet
select 'slowly from large partition' from dual;

-- now gather stats, 
-- and re-query



