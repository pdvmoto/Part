
-- demo global-partitioned indexes
-- partitioned on other key as table-partitioning.
-- leads to "partitioned"=YES, but is still a Global Index..
-- double-check in the dba_part_indexes, locality=GLOBAL


drop   index pt_gip_pay ; 
create index pt_gip_pay on pt (payload, active ) 
global partition by range (payload ) 
(
  partition pt_gip_pay_a2k values less than ('L') nocompress 
, partition pt_gip_pay_l2z values less than (MAXVALUE) nocompress  
);

select index_name, locality from user_part_indexes pi ;

