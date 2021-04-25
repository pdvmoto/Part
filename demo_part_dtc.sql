

-- experiment with indexes and partitions, and blob,
-- inspired by cases from JohnT.

/**

Cases to examine:
 - the funny indexes pk (id, dtc), pk+lvl, pk+dtm
 - global and local indexes
 - which field in pk to put first ?
 - partion by dtc: does field order in pk matter ?
 - what if the BLOB is several block in size
 - blob-storage, any specific needs? 

twitter:
What do I tell the Architect...?

create unique index t1_pk       on t1 ( id, dtc )      ; 
create        index t1_idx_dtm  on t1 ( id, dtc, dtm ) ;
create        index t1_idx_lvl  on t1 ( id, dtc, lvl ) ;

Every stmnt seems to have ...where id=3113, 
plus, expect high freq of ins/upd on this data. 
And we may want to partition monthly on dtc (date_created). 


****/

drop table t1;
drop table pt1;

create table pt1 (
  id   number
, dtc  date
, Blb  blob
, lvl  number
, dtm  date
, pld  varchar2(4000)
) ;

create unique index pt1_pk on pt1 ( id, dtc ) ; 

alter table pt1 add constraint pt1_pk primary key ( id, dtc ) ;

-- and the two funny indexes
create index pt1_idx_lvl on pt1 ( id, dtc, lvl ) ;
create index pt1_idx_dtm on pt1 ( id, dtc, dtm ) ;


-- put some data in, try for 10K rows, to aim for 4 partitions?
-- 4 months, 1 rec/min.. 120 days.. 1440 min x 120 days = 15
-- try starting 01-Jan, and add rows..
-- 40K rows, 10K/month, 300/day, say... 

insert into pt1
select
   trunc ( rownum -1)                               -- sequene, id...
,  to_date ( '2021-JAN-01', 'YYYY-MON-DD' ) + (rownum/1440)  -- dtc
,  ''                                              -- blob, first empty
,  mod ( rownum-1, 10 )                             -- levels 0-10
,  (sysdate - rownum/1440 )                        -- some date-modified?
,  rpad ( to_char (to_date ( trunc ( rownum ), 'J'), 'JSP' ), 198) -- some payload, words
from dual
connect by rownum <= 40000 ;


