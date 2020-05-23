node_type=$1

if [ "$node_type" == "master" ] || [ "$node_type" == "infra" ] || [ "$node_type" == "worker" ] 
then
	pvcreate /dev/sdb
	vgextend vg_node1 /dev/sdb
	lvextend /dev/vg_node1/lv_root /dev/sdb
	resize2fs /dev/mapper/vg_node1-lv_root
fi
      