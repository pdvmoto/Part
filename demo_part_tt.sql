
-- allow explain plans to display
set linesize 120

/* 

demo the case of partitioned table, 3 global indexes..
- inlist SQL
- choosing partition-scan over index.
- experiment with nr inlist-binds -tbd
- replace PK by local index, with UNQ enforced - works
- remove the superfluous indexes, test, proof. - works, needs more tests

additional demos:
 - global-partitioned index, e.g. partitioned by accident
 - fill table and show how full-scan is first good, then bad
 - tweak statistics, to force index from start


prepare: 
 - 4 partitions, wiht significant data in BLOB (json copy of record)
 - demo part-scan and index usage.
 - demo that extra indexes dont help, even with orderby

sample data: 31 * 24      =  744 records (hrs in a month, not that much..)
sample data: 31 * 24 * 60 =  40K records (minutes in a month)


- fill several partitions with data.
- demonstrate that index is bigger than individual partitions.
- add a few lines to new partition
- calculate stats: now optimizer knows about large index and small partition
- demonstrate Full-scan on small partition
- fill partition and demonstrate still full scan, less efficient
- calcuate stats...
- re-qry, now use of index.

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
-- create index t1_idx_lvr on t1 ( oid, ttm, lvr ) ;
-- create index t1_idx_tst on t1 ( oid, ttm, tst ) ;
-- create index t1_idx_tnn on t1 ( oid, ttm, tnn ) ;


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
storage ( initial 64k next 64k )
-- partition by range ( ttm ) interval (numtodsinterval (1, 'DAY'  ) )
   partition by range ( ttm ) interval (numtoyminterval (1, 'MONTH') )
 (partition pt1_p0 values less than (to_date(' 2021-01-01', 'YYYY-MM-DD'))
  segment creation immediate
  tablespace users
  storage (initial 64k next 64k )
  lob ( blb ) store as securefile ( disable storage in row ) 
 ) ;


-- choose local or global..
create unique index pt1_pk on pt1 ( oid, ttm ) global ; 
alter table pt1 add constraint pt1_pk primary key ( oid, ttm ) ;

-- not yet : create unique index pt1_unq  on pt1 ( ttm, oid ) local ;

-- and the indexes, 3 additional, where two overlap with pk.
-- create index pt1_idx_lvr on pt1 ( oid, ttm, lvr ) ;
-- create index pt1_idx_tst on pt1 ( oid, ttm, tst ) ;
-- create index pt1_idx_tnn on pt1 ( oid, ttm, tnn ) ;

-- note: also test with local indexes.. show diff.

-- put some data in, try for 10K rows, to aim for 4 partitions?
-- 4 months, 1 rec/min.. 120 days.. 1440 min x 120 days = 15
-- try starting 01-Jan, and add rows..
-- 40K rows, 10K/month, 300/day, say... 

insert into pt1
select
   to_date ( '2021-JAN-01', 'YYYY-MON-DD' ) + (8*rownum/1440)  -- ttm
,  ''                                              -- blob, first empty
,  pt1_seq.nextval                                 -- id 
,  mod ( rownum-1, 10 )                            -- lvr 0-10
,  (sysdate - rownum/1440 )                        -- tst, some date
,  (sysdate - rownum/1440 - 2 )                    -- tmd, some date
,  (sysdate - rownum/1440 - 4 )                    -- tfn, some date
,  (sysdate - rownum/1440 - 6 )                    -- tnn, some date
,  rpad ( to_char (to_date ( trunc ( rownum ), 'J'), 'JSP' ), 20) -- some payload, words
from dual
connect by rownum <= 20000 ;

commit ;

begin
DBMS_STATS.gather_table_stats( ownname => user, tabname=>'PT1'  
                                  , partname=>null, estimate_percent=>100);
end;
/


-- -- -- here -- -- -- 

-- demo of selecting from 1 partition 
-- select min ( ttm), max ( ttm) 
-- from pt1 partition for ( to_date ( '2021-01-01', 'YYYY-MM-DD') ) ; 


-- use the demo from PI.sql.
-- add a few records to new partition
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
connect by rownum <= 2 ;

commit ;

-- give it statistics for the 1 day.
EXEC DBMS_STATS.gather_table_stats(user, 'PT1', null, 100);

-- verify sizes: indexes are larger than partitions
@segsizes scott pt1

accept hit_enter prompt 'verify that index is larger than partition.'

-- now run SQL that will scan the partition.. (which is still small, smaller than index)
select 'fullscan, few records ' from dual ;

select oid, ttm, substr ( pld, 1, 10 ) payload
from pt1
where 1=1
and ttm >= to_date ( '2021-MAY-01', 'YYYY-MON-DD' )
and ttm <  to_date ( '2021-MAY-02', 'YYYY-MON-DD' )
and oid in ( 20001, 20002, 20003 ) ;

set autotrace on
/

set autotrace off

accept hit_enter prompt 'verify: full scan on small partition, efficient.'

-- now insert a raft of data into that first partition, 30 days x 1440 min approx 40K 
-- make the partition large and therfore inefficient

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
connect by rownum <= 40000 ;

commit ;

-- verify sizes: indexes are larger than partitions
@segsizes scott pt1

accept hit_enter prompt 'verify: partition now larger than index, stats not yet gathered.'

-- verify same sql, still does full scan, but partition is larger..
select oid, ttm, substr ( pld, 1, 10 ) payload
from pt1
where 1=1
and ttm >= to_date ( '2021-MAY-01', 'YYYY-MON-DD' )
and ttm <  to_date ( '2021-MAY-02', 'YYYY-MON-DD' )
and oid in ( 20001, 20002, 20003 ) ;

set autotrace on
/

set autotrace off

accept hit_enter prompt 'verify: full scan of partition now more work.'


EXEC DBMS_STATS.gather_table_stats(user, 'PT1', null, 100);

-- verify same sql, still does full scan, but partition is larger..
select oid, ttm, substr ( pld, 1, 10 ) payload
from pt1
where 1=1
and ttm >= to_date ( '2021-MAY-01', 'YYYY-MON-DD' )
and ttm <  to_date ( '2021-MAY-02', 'YYYY-MON-DD' )
and oid in ( 20003, 20002, 20001 ) ;

set autotrace on
/
set autotrace off

accept hit_enter prompt 'verify: after correct partitions: index + efficient.'


-- replace the pk wiht Local index, without compromising uniquness-constraint
create unique index pt1_unq  on pt1 ( ttm, oid ) local online ; 

alter table pt1 drop constraint pt1_pk online ; 
drop index pt1_pk online;

create unique index pt1_pk  on pt1 ( oid, ttm ) local online ; 
alter table pt1 add constraint pt1_pk primary key ( oid, ttm ) using index pt1_pk ; 

drop index pt1_unq ; 

-- verify same sql, still does full scan, but partition is larger..
select oid, ttm, substr ( pld, 1, 10 ) payload
from pt1
where 1=1
and ttm >= to_date ( '2021-MAY-01', 'YYYY-MON-DD' )
and ttm <  to_date ( '2021-MAY-02', 'YYYY-MON-DD' )
and oid in ( 20003, 20001, 20002 ) ;

set autotrace on
/
set autotrace off

accept hit_enter prompt 'verify: just checking, new UNIQE LOCAL index.'



-- partition is now large, larger than index, but the statistics dont know that yet
select 'slowly from large partition' from dual;

-- now gather stats, 
-- and re-query



