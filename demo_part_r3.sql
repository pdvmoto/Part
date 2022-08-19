
-- try ref-partitions with tech-keys, e.g. table only knows of 1st level parent.

create table trp1 (
  id          number
, created_dt  date default sysdate
, t_type      varchar2 (10) not null
, payload     varchar2 (200) 
);


