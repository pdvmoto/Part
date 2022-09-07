
-- insert 1  value to create new partition

insert into pt ( id   , active) 
         select  id+1 , active 
           from pt 
          where id = (select max(id) from pt) ; 

echo show the new partition...

-- insert into next level, using the max/new pt_id..


insert into pt_c ( id, pt_id, created_dt, c_type, payload )
     select  rownum, id, sysdate, 'TYP:C', 'parent_payld: '|| substr ( payload, 1, 150)
from pt 
where id = (select max(id) from pt) ; 

echo show the new partition...
