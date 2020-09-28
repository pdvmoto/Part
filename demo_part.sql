
/* 
 demo_part.sql: demonstrate use of partitions.

story to tell in ppt :
 - partitioning limited use
 - always + only needs local-indexes.
 - best use case is to prevent redo on delete (demo with 2x16M redo/WALs, but reality: gb/sec)
 - pitfall: global index when drop-partition (demo?)
 - positive: scanning 1 or few partitions to get your (aggregated) result.
 - pitfall: scanning of multiple local_indexes to find a (small) target.

Demo-notes:
 - screen 128 x 34 , need wide screen for explain in demo_1

 - re-test against 18.x and 12.1.

 - case 1:
 - delete data versus drop-partition.. effort is much less. demo_0

 - case 1a: 
 - drop partition with global index: see the extra time+effort

 - case 1b: 
 - delete data from non-partitioned table.. how much redo?

 - case 2:
 - find 1 record, use index..
    - if where-clause = part-key: OK
    - if where-clause != part-key :  loop over partitions
    
 - case 3 : 
 - find set of indexed-records: 
    - if in 1 partition: fine
    - if in multiple partions: loop..

 - other use-case (airmiles) to move partitions (in tablespaces) around without redo
 - other use cases depend on partition-eliminationm, key-in-whereclause.
 - subpartition-hash, for pq, limited usage

 - anecdote: status=current, most recrds in last partition, but 
    => global index.. ai..
    => local index.. still ai.
    => local index + where - clause.. only good solution.

notably
 - table with pk and payload and "compressible filler", (local) index on payload
 - generate  records.
 - demo delete from large table  (time + redo)
 - demo drop partition, see how fast?

extras
 - pk with yyyymmddSSS+sequence
 - locking, how long when delete, how long when drop/exchange..

Check:
 - on-line operations for partitioning ? 
 - license for partitioning still an issue ? 
 - filtered-partition operations - check+test+demo ?
 - compressed partitions, do they also use less memory ? 

 - note: logfile > 100, slow creation of tables: if LOG=16M to compare to PG..

test
 - date+seq idea for pk
 - volume of pk as integer, string or even timestamp, any impact ? 
 - function to create pk ? 

demo-items:
 - measure redo-volume, verify with log-switches or WAL files (16M files)
 - check_redo : report redo volume since last, minus 0.4 kb ? 
 - insert records into table and/or some partitions
 - remove via delete and via partition: no redo!
    notably on delete of "1 month" or one partition.
 - small partitions: easy full-scan.
 - compress old partitions (rebuild index ?), need to alter+move+rebuild-idx.
 - read-only partitions (tablespace and/or partition)
 - looping over many partitions.. extra effort even if indexed


items needed: 
 - an insert-routine for (trickle) inserts
 - a delete-routine for (trickle) deletes
 - a key-generator YMD-seq

create sequence pt_seq start with 1 maxvalue 99999 cycle;

with series as (
select rownum num 
,  to_char (to_date ( rownum, 'J'), 'JSP' ) 
from dual 
connect by rownum < 10 )
select * from series ; 

using YYYY DDD HH24MISS 
for   2020 366 23:59:59
we end up wth a ridiculous high nr ? 2 Trillion ? 
2.019.294.175.716

add to that 6 digit for Seq, and .. 25 digit precision, just inside oracle..

....,....1....,....2....,
2.020.366.235.959.000.000

assume: 1000 rec/sec -> 100M / day

100M = 8 or 9 digits (inside 1 day).


stored by day:  
5 or 8 digits for the day
8: YYYYMMDD
5: YYDDD 
then 8 digits for the seq in the day.
total 16  digits


10: YYYYMMDDHH 
stored by hr : 6 digits per hr..
same.. 16 digits.

stored by sec: 
14: YYYYMMDDHHMISS 
plus 3 or 4 digits for seq (999 /sec) 
total 15 or 16  digits, same, so might as well be clear and use YMD-HMS

in all cases: 16 digits...
but 16 digits is still only half of a GUID

Q: 
 - what if we put Day as interger, and intra-day as fraction behind dec-sep.?


Research Topics for Audience
 - would an artificial key on date-nr work ? YYY DDD HHMIDD + seq, avoid Global IDX.
 - what about ultra small partitions ? Compressed ?
 - any practical experience with mixed internal/external partitions ? 
 - 
 - 


create replace table pt2
( id number(25, 0) 
, payload varchar2/(1000)
)

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

prompt  
accept hit_enter prompt 'Check the Partitioned table... '

clear screen
set echo on

-- beware, constraint in table-def generates global index
-- hence create unique Local index first
-- 
create unique index pt_pk on  pt ( id ) local ; 

alter table pt add constraint pt_pk primary key ( id ) ;

set echo off

prompt  
accept hit_enter prompt 'Table now with PK over Local, Unique index...'

clear screen

set echo on

--
-- Create identical table T, non-partitioned
-- 
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

set echo off
prompt 
accept hit_enter prompt 'Check the indentical, conventional table T... '

set feedback on

clear screen

set echo on

--
-- fill with deliberately funny, compressible data
-- 4 partitions, 40K records was nice number for timing, effort, demo.. 
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

commit ; 

set echo on

--
-- and copy into conventional table.
--
insert into t select * from pt ;

set echo off
prompt
accept hit_enter prompt 'Same Data inserted into both tables... '

clear screen

set echo on

--
--  add extra index for realistic effect, and gather stats..
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

