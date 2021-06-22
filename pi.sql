

-- experiment with indexes and partitions, and blob,
-- inspired by cases from JohnT.

/**

Cases to examine:
 - the funny indexes pk (id, dtc), pk+lvl, pk+dtm
 - global and local indexes (proof of...)
 - which field in pk to put first ?
 - partion by dtc: does field order in pk matter ?
 - what if the BLOB is several block in size
 - blob-storage, any specific needs? 

Recommendations:
R1: Focus all activity for 1 dom on 1 node: 
eliminates any doubt of interconnect-traffic, and makes it easier to diagnose a specific dom.

R2: examine multiple AWR reports, and compare problem-intervals to normal-intervals.
R2a: reduce snapshot-interval to 15min ? 


Questions:
Q: do we have the real problem? any other AWR to confirm?
Q: AWR thresholds, why are we missing stmnts?

Q: observe in real-time?
Q: count connections and connection-creation, can +/- use ASH to find in 24hrs...

Q: count-id-date: how selective are the fields id, dt, why double-key
Q: count of records, total and per partition
Q: is there a data-life-cycle? when is data deleted?
Q: index-usage, any use for the 3rd field?
Q: usage of 3rd field in where-clauses or order-by? scan SQL

Q: is there a test-system with realistic data+workload?


twitter:
What do I tell the Architect...?

create unique index t1_pk       on t1 ( id, dtc )      ; 
create        index t1_idx_dtm  on t1 ( id, dtc, dtm ) ;
create        index t1_idx_lvl  on t1 ( id, dtc, lvl ) ;

Every stmnt seems to have ...where id=3113, 
plus, expect high freq of ins/upd on this data. 

And we may want to partition monthly on dtc (date_created). 

notes on indexes:

note that those indexes would only make sense if a range or all of the 3rd field needs to be selected. The AWR seems to show only SQL that retrieves Single Records (1 row per exec)..

my suggestion would be that the PK index alone is sufficient ?

note: check if id - count-date shows multiple dates per id.

notes on lobs:
if lobsize is <8K, the chuncksize is a waste of space+effort

Notes 03June
 - adjusted table to resemble bindata and indexes (pk + 3 indexes)
 - script to examine table-structure: tab + indexes, global, local..
 - check for lob-wait-events
 - sql-baselines: ignored when .... ?  ID 2308153.1
 - script for usage of indexes (obj_usage)

****/

drop table t1;
drop table pt1;

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
partition by range ( ttm ) interval (numtoyminterval(1, 'month'))
 (partition pt1_p0 values less than (to_date(' 2020-01-01', 'YYYY-MM-DD'))
  segment creation immediate
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
,  trunc ( rownum -1)                               -- id 
,  mod ( rownum-1, 10 )                             -- lvr 0-10
,  (sysdate - rownum/1440 )                        -- tst, some date
,  (sysdate - rownum/1440 - 2 )                    -- tmd, some date
,  (sysdate - rownum/1440 - 4 )                    -- tfn, some date
,  (sysdate - rownum/1440 - 6 )                    -- tnn, some date
,  rpad ( to_char (to_date ( trunc ( rownum ), 'J'), 'JSP' ), 20) -- some payload, words
from dual
connect by rownum <= 40000 ;

commit ;

EXEC DBMS_STATS.gather_table_stats(user, 'PT1', null, 1);

