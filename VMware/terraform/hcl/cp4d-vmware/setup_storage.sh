


pvcreate /dev/sdb
vgextend vg_node1 /dev/sdb
lvextend /dev/vg_node1/lv_root /dev/sdb
resize2fs /dev/mapper/vg_node1-lv_root
