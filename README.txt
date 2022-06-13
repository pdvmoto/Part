
These scripts go with the ppt on partitioning..

demo_part = initialize
demo_part_0 = drop-partition, redo.
demo_part_0a = drop, global index, redo..
demo_part_1 = 
demo_part_sum = show how summation over 1 partition is efficient


etc..


bonus1 : fabricate partiion key from Y-M-D+Seq..

bonus2: global_partitioned index: is NOT a local index... beware: demo_part_gip.sql

bonus3: tt = show how global index is not used on small partitions.
