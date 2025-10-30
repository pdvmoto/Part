
/*
 dp_uuid.sql: demo partitioning on RAW, UUID-V7, time ordered.

todo:
 - uuid7 ( dt systimestamp, random_data numbeer = [ 0,1 ] )  : 
   generate partition boundaries, and store YYYYMMDD in last fields
   if random_data = 0 : then store '%YYYYMMDD', else use random 

Risk:
 - non V7 UUIDs end up in 1 LARGE LEFTOVER partition
 - forget to add ranges.. (old problem)

*/
 
drop table pt_uuid ; 
create table pt_uuid
( id                raw ( 16 )    -- uuid-v7, the PK and partitioning-key.
, active            varchar2 ( 1 )   -- Y/N, show small set of Active.
, amount            number ( 10,2 )  -- supposedly some amount of money.
, dt                date             -- a date, case we want history stuff 
, payload           varchar2 ( 200 ) -- some text
, filler            varchar2 ( 750 ) -- some data to create 1K recordsize
)
partition by range ( id )  /* interval ( 10000 ) */ 
(   partition pt_0 values less than ( '0000000070000000000019700101' )  
,   partition pt_1 values less than ( '019A30867AD8705E82BE42B071B5' )  
,   partition pt_2 values less than ( '029A30867AD8705E82BE42B071B5' )  
,   partition pt_Y values less than ( 'FFFFFFFF7FFFFFFFFFFFFFFFFFFF' )   
,   partition pt_Z values less than (                       MAXVALUE ) 
)  
; 

-- constraint and index ...
create unique index pt_uuid_pk on  pt_uuid ( id ) local ;
alter table pt_uuid add constraint pt_uuid_pk primary key ( id ) ;



-- insert some data, UUID-V7
insert into pt_uuid
select
   uuid7()                               -- raw, uuid, preferably uuid7...
,  decode ( mod ( rownum, 10000), 0, 'Y', 'N' )     -- every 1/1000 active=Y
,  mod ( rownum-1, 10000 ) / 100                    -- 0-100, two decimals
,  (sysdate - rownum )                              -- some dates
,  rpad ( to_char (to_date ( trunc ( rownum ), 'J'), 'JSP' ), 198) -- words
,  rpad ( ' ', 750 )                                -- blanks
from dual
connect by rownum <= 10000 ;

-- and some UUID V4, Random
insert into pt_uuid
select
   uuid()                               -- raw, uuid, preferably uuid7...
,  decode ( mod ( rownum, 10000), 0, 'Y', 'N' )     -- every 1/1000 active=Y
,  mod ( rownum-1, 10000 ) / 100                    -- 0-100, two decimals
,  (sysdate - rownum )                              -- some dates
,  rpad ( to_char (to_date ( trunc ( rownum ), 'J'), 'JSP' ), 198) -- words
,  rpad ( ' ', 750 )                                -- blanks
from dual
connect by rownum <= 10000 ;

EXEC DBMS_STATS.gather_table_stats(user, 'PT_UUID', null, 1);

column table_name format A20
column part_name  format A20
column hv format 999999 head High_val

select table_name, partition_name part_name, num_rows
from user_tab_partitions
where table_name like 'PT%'
order by table_name, partition_name ;

