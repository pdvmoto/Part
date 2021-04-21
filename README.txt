
These scripts go with the ppt on partitioning..

demo_part = initialize
demo_part_0 = drop-partition, redo.
demo_part_0a = drop, global index, redo..
demo_part_1 = 


etc..


bonus1 : fabricate partiion key from Y-M-D+Seq..

bonus2: global_partitioned index: is NOT a local index... beware: demo_part_gip.sql
