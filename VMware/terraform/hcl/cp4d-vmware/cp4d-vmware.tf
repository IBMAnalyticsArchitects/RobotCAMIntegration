
##############################################################
# Keys - CAMC (public/private) & optional User Key (public)
##############################################################
variable "allow_unverified_ssl" {
  description = "Communication with vsphere server with self signed certificate"
  default = "true"
}

##############################################################
# Define the vsphere provider
##############################################################

provider "vsphere" {
  allow_unverified_ssl = "${var.allow_unverified_ssl}"
  version = "~> 1.3" 
}



##############################################################
# Define pattern variables
##############################################################

##############################################################
# Vsphere data for provider
##############################################################
data "vsphere_datacenter" "vm_datacenter" {
  name = "${var.vm_datacenter}"
}

data "vsphere_datastore" "vm_datastores" {
  count         = "${length(var.vm_root_disk_datastores)}"
  name          = "${var.vm_root_disk_datastores[count.index]}"
  datacenter_id = "${data.vsphere_datacenter.vm_datacenter.id}"
}

data "vsphere_resource_pool" "vm_resource_pools" {
  count         = "${length(var.vm_resource_pools)}"
  name          = "${var.vm_resource_pools[count.index]}"
  datacenter_id = "${data.vsphere_datacenter.vm_datacenter.id}"
}

data "vsphere_network" "vm_network" {
  name = "${var.vm_network_interface_label}"
  datacenter_id = "${data.vsphere_datacenter.vm_datacenter.id}"
}

data "vsphere_virtual_machine" "vm_templates" {
  count         = "${length(var.vm-images)}"
  name          = "${var.vm-images[count.index]}"
  datacenter_id = "${data.vsphere_datacenter.vm_datacenter.id}"
}

##### Image Parameters variables #####

variable "vm_name_prefix" {
  description = "Prefix for vm names"
}




#########################################################
##### Resource : vm
#########################################################
variable "ssh_user" {
  description = "The user for ssh connection, which is default in template"
  default     = "root"
}

variable "public_ssh_key" {
  description = "Public SSH Key"
}
variable "private_ssh_key" {
  description = "Private SSH Key"
}
variable "ssh_key_passphrase" {
  description = "SSH Key Passphrase"
}


variable "ssh_user_password" {
  description = "The user password for ssh connection, which is default in template"
}

variable "sudo_user" {
  description = "Sudo User"
}

variable "sudo_password" {
  description = "Sudo Password"
}

variable "monkey_mirror" {
  description = "Monkey Mirror IP or Hostname"
}
    
variable "num_masters" {
  description = "number of masters"
}

variable "master_num_cpus" {
  description = "master_num_cpus"
}

variable "master_mem" {
  description = "master_mem"
}

variable "num_infra" {
  description = "number of infra nodes"
}

variable "infra_num_cpus" {
  description = "infra_num_cpus"
}

variable "infra_mem" {
  description = "infra_mem"
}

variable "num_workers" {
  description = "number of worker nodes"
}


variable "worker_num_cpus" {
  description = "worker_num_cpus"
}

variable "worker_mem" {
  description = "worker_mem"
}

variable "fully_disable_idm" {
  description = "Fully disable all FreeIPA/IDM-related functionality (0 or 1)"
  default="0"
}

variable "num_idm" {
  description = "number of idm nodes"
}

variable "vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "vm_domain" {
  description = "Domain Name of virtual machine"
}


variable "vm_resource_pools" {
  description = "Target vSphere Resource Pool(s) to host the virtual machines. If multiple values are provided, VMs are round-robined across the listed resource pools (in this case, they must match datastores in same order, if located on different ESXi hosts)"
  type = "list"
}

variable "vm_dns_servers" {
  type = "list"
  description = "DNS servers for the virtual network adapter"
}


variable "time_server" {
  description = "Hostname or IPv4 for time server"
}

variable "vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "vm_start_ipv4_address" {
  description = "Start IPv4 address for vNIC configuration"
}

variable "vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default = "vmxnet3"
}

variable "vm_root_disk_datastores" {
  description = "Data store(s) for target virtual machine's disks. If multiple values are provided, VMs are round-robined across the listed datastores (in this case, they must match resource pools in same order, if located on different ESXi hosts)"
  type = "list"
}

variable "vm_root_disk_type" {
  type = "string"
  description = "Type of template disk volume"
  default = "eager_zeroed"
}

variable "vm_root_disk_controller_type" {
  type = "string"
  description = "Type of template disk controller"
  default = "scsi"
}

variable "vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default = "25"
}
variable "vm-images" {
  description = "Operating system image id / template that should be used when creating the virtual image"
  type = "list"
}

variable "public_nic_name" {
  description = "Name of the public network interface"
  default = "ens192"
}

variable "cloud_install_tar_file_name" {
  description = "Name of the tar file downloaded from the mirror, which contains the Cloud Installer code."
  default = "cloud_install.tar"
}

variable "icp_network_cidr" {
  description = "ICP Network CIDR"
  default = "172.1.0.0/16"
}

variable "icp_service_cluster_ip_range" {
  description = "ICP Cluster IP Range"
  default = "172.2.0.0/16"
}

variable "cluster_name" {
  description = "Cluster Name"
  default = "MYCLUSTER"
}

variable "idm_primary_hostname" {
  description = "Hostname of primary IDM server"
}

variable "idm_primary_ip" {
  description = "IP of primary IDM server"
}


variable "idm_replica_hostname" {
  description = "Hostname of replica IDM server"
}

variable "idm_replica_ip" {
  description = "IP of replica IDM server"
}

variable "idm_admin_password" {
  description = "Password for IDM admin user"
}

variable "idm_ldapsearch_password" {
  description = "Password for IDM ldapsearch user"
}

variable "idm_directory_manager_password" {
  description = "Password for IDM directory admin user"
}

variable "cp4d_addons" {
  description = "List of Cloud Pak for Data Add-Ons"
  type = "list"
}

variable "cp4d_num_db2wh_nodes" {
  description = "Number of nodes dedicated to DB2WH"
  type = "string"
}

variable "hdp_driver_ip" {
  description = "IP of the driver for HDP cluster"
}

variable "hdp_edge_node_hostname" {
  description = "Hostname of HDP Edge Node, hadoop integration service host"
}

variable "hdp_edge_node_ip" {
  description = "IP of HDP Edge Node, hadoop integration service host"
}


variable "install_portworx" {
  description = "Install Portworx (0/1)"
}

########
# Isolate IP address components:
locals {
  vm_ipv4_address_elements = "${split(".",var.vm_start_ipv4_address)}"
  vm_ipv4_address_base = "${format("%s.%s.%s",local.vm_ipv4_address_elements[0],local.vm_ipv4_address_elements[1],local.vm_ipv4_address_elements[2])}"
  vm_ipv4_address_start= "${local.vm_ipv4_address_elements[3] }"
  idm_install = "${ ( var.idm_primary_hostname=="" || var.idm_primary_ip=="" || var.idm_admin_password=="" || var.idm_ldapsearch_password=="" || var.idm_directory_manager_password=="" ) && var.fully_disable_idm=="0" ? 1 : 0 }"
  
  num_driver = "1"
  num_idm = "${ var.num_idm * local.idm_install }"
  num_haproxy = "1"
  num_nfs = "1"
  num_master = "${var.num_masters}"
  num_infra = "${var.num_infra}"
  num_worker = "${var.num_workers}"
}

###########################################################################################################################################################

# Driver 
resource "vsphere_virtual_machine" "driver" {
  name = "${var.vm_name_prefix}-drv"
  num_cpus = "4"
  memory = "4096"
  count = "${local.num_driver}"
  
  resource_pool_id = "${element(data.vsphere_resource_pool.vm_resource_pools.*.id, count.index )}"
  datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
  
  

  guest_id = "${element(data.vsphere_virtual_machine.vm_templates.*.guest_id, count.index )}"
  clone {
    template_uuid = "${element(data.vsphere_virtual_machine.vm_templates.*.id, count.index )}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-drv"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${ local.vm_ipv4_address_start }"
        ipv4_netmask = "${ var.vm_ipv4_prefix_length }"
      }
    ipv4_gateway = "${var.vm_ipv4_gateway}"
    dns_server_list = "${var.vm_dns_servers}"
    }
  }

  network_interface {
    network_id = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${var.vm_adapter_type}"
  }

  disk {
    label = "${var.vm_name_prefix}0.vmdk"
    size = "${var.vm_root_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }


  provisioner "file" {
    content = <<EOF
#!/usr/bin/expect
set passphrase [lindex $argv 0]
spawn ssh-add
while { 1 == 1 } {
 expect {
   "(y/n)?" { send "y\r"; exp_continue; }
   "Enter passphrase for /root/.ssh/id_rsa:" { send "$passphrase\r"; exp_continue; }
   eof { exit }
 }
}
EOF
    destination = "/opt/addSshKeyId.exp"
  }


  
  provisioner "file" {
    source      = "redhat_monkey.repo"
    destination = "/tmp/redhat_monkey.repo"
  }
  
  provisioner "file" {
    source      = "init_vm.sh"
    destination = "/tmp/init_vm.sh"
  }


  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub",
      "echo ${var.public_ssh_key} > /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa",
      "chmod 600 /root/.ssh/id_rsa",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "chmod 700 /opt/addSshKeyId.exp",
      "chmod 700 /tmp/init_vm.sh",
      "/tmp/init_vm.sh ${var.monkey_mirror} ${var.vm_dns_servers[0]} '${var.public_ssh_key}'"
    ]
  }


  provisioner "file" {
    content = <<EOF
#!/bin/sh

yum install -y expect

passphrase=`cat /root/passphrase`

eval `ssh-agent`
/opt/addSshKeyId.exp $passphrase

set -x 

yum install -y ksh rsync unzip  

mkdir -p /opt/cloud_install; 

cd /opt/cloud_install;

. /opt/monkey_cam_vars.txt;

wget http://$cam_monkeymirror/cloud_install/$cloud_install_tar_file_name

tar xf ./$cloud_install_tar_file_name

echo "Create key pair for the intra-cluster communications"
mkdir -p /opt/cloud_install/ssh_keys
ssh-keygen -t rsa -N "" -f /opt/cloud_install/ssh_keys/id_rsa
chmod 700 /opt/cloud_install/ssh_keys
chmod 600 /opt/cloud_install/ssh_keys/id_rsa

echo "Generate new global.properties"
perl -f cam_integration/01_gen_cam_install_properties.pl

#sed -i 's/cloud_replace_rhel_repo=1/cloud_replace_rhel_repo=0/' global.properties
echo "cloud_enable_yum_versionlock=0">>global.properties

. ./setenv

echo "Encrypt and remove global.properties"
$MASTER_INSTALLER_HOME/utils/01_encrypt_global_properties.sh global.properties
rm -f ./global.properties

if [ "`echo $cloud_icp_addons | grep hadoop-addon`" != "" -a "${var.hdp_driver_ip}" != "" -a "$cloud_icp4d_dsxhi_hostname" != "" -a "$cloud_icp4d_dsxhi_ip" != "" ]
then
   cloud_icp4d_dsxhi_master_install_home=/opt/cloud_install_cp4d_dsxhi
   ssh ${var.hdp_driver_ip} "set -x
cd /opt/cloud_install
. ./setenv
rm -rf $cloud_icp4d_dsxhi_master_install_home
mkdir -p $cloud_icp4d_dsxhi_master_install_home
cd $cloud_icp4d_dsxhi_master_install_home
wget http://$cam_monkeymirror/cloud_install/${var.cloud_install_tar_file_name}
tar xf ./${var.cloud_install_tar_file_name}
env|egrep "^cloud_" >global.properties
echo "cloud_icp4d_distribution_url=$cloud_icp4d_distribution_url" >> global.properties
echo "cloud_icp_haproxy_vip=$cloud_icp_haproxy_vip" >> global.properties
echo "cloud_icp4d_dsxhi_gateway_password=$cloud_icp4d_dsxhi_gateway_password" >> global.properties
echo "cloud_icp4d_dsxhi_hostname=$cloud_icp4d_dsxhi_hostname" >> global.properties
echo "cloud_icp4d_console_virtual_hostname=$${cloud_icp4d_consle_name:-zen-cpd-zen}.apps.$cloud_freeipa_domain" >> global.properties
cp /opt/cloud_install/hosts $cloud_icp4d_dsxhi_master_install_home/
cp -r /opt/cloud_install/ssh_keys $cloud_icp4d_dsxhi_master_install_home/"

   cat<<END>prepDsxhi.sh
passphr=\$1
set -x
eval \`ssh-agent\`
/opt/addSshKeyId.exp \$passphr
cd $cloud_icp4d_dsxhi_master_install_home
. ./setenv
$cloud_icp4d_dsxhi_master_install_home/utils/01_send_cloud_installer.sh $cloud_icp4d_dsxhi_hostname
END
chmod 700 prepDsxhi.sh

   #######################
   # Copy prepDsxhi.sh to driver and run
   scp prepDsxhi.sh ${var.hdp_driver_ip}:$cloud_icp4d_dsxhi_master_install_home/
   ssh ${var.hdp_driver_ip} "$cloud_icp4d_dsxhi_master_install_home/prepDsxhi.sh $passphrase"
fi

utils/01_prepare_driver.sh

. $MASTER_INSTALLER_HOME/utils/00_globalFunctions.sh
nodeList=`echo $cloud_hostpasswords|awk -v RS="," -v FS=":" '{s=sprintf("%s %s",s,$1);}END{print s}'`
for hostName in `echo $nodeList|sed 's/,/ /g'`
do
  if [ "$hostName" != "" ]
	then
    hostPwd=`get_root_password $hostName`
		ssh.exp $hostName $hostPwd "echo \`hostname\`.\`hostname -d\`>/etc/hostname;passwd -l root;"
	fi
done

utils/01_prepare_all_nodes.sh >01_prepare_all_nodes.log 2>&1

nohup cp4d_files/01_master_cp4d.sh &

EOF

    destination = "/opt/installation.sh"

  }
  
}




###########################################################################################################################################################

# IDM
resource "vsphere_virtual_machine" "idm" {
  count="${local.num_idm}"
  name = "${var.vm_name_prefix}-idm-${ count.index }"
  num_cpus = "4"
  memory = "4096"

  resource_pool_id = "${element(data.vsphere_resource_pool.vm_resource_pools.*.id, count.index )}"
  datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
  
  guest_id = "${element(data.vsphere_virtual_machine.vm_templates.*.guest_id, count.index )}"
  clone {
    template_uuid = "${element(data.vsphere_virtual_machine.vm_templates.*.id, count.index )}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-idm-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + local.num_driver }"
        ipv4_netmask = "${ var.vm_ipv4_prefix_length }"
      }
    ipv4_gateway = "${var.vm_ipv4_gateway}"
    dns_server_list = [ "127.0.0.1" , "10.0.80.11" , "10.0.80.12" ]
    }
  }

  network_interface {
    network_id = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${var.vm_adapter_type}"
  }

  disk {
    label = "${var.vm_name_prefix}0.vmdk"
    size = "${var.vm_root_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }

  provisioner "file" {
    source      = "redhat_monkey.repo"
    destination = "/tmp/redhat_monkey.repo"
  }
  
  provisioner "file" {
    source      = "init_vm.sh"
    destination = "/tmp/init_vm.sh"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod 700 /tmp/init_vm.sh",
      "/tmp/init_vm.sh ${var.monkey_mirror} ${var.vm_dns_servers[0]} '${var.public_ssh_key}'"
    ]
  }

}



###########################################################################################################################################################

# HAProxy
resource "vsphere_virtual_machine" "haproxy" {
  count="${local.num_haproxy}"
  name = "${var.vm_name_prefix}-haproxy-${ count.index }"
  num_cpus = "4"
  memory = "4096"
  

  resource_pool_id = "${element(data.vsphere_resource_pool.vm_resource_pools.*.id, count.index )}"
  datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
  
  
  guest_id = "${element(data.vsphere_virtual_machine.vm_templates.*.guest_id, count.index )}"
  clone {
    template_uuid = "${element(data.vsphere_virtual_machine.vm_templates.*.id, count.index )}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-haproxy-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + local.num_driver + local.num_idm }"
        ipv4_netmask = "${ var.vm_ipv4_prefix_length }"
      }
    ipv4_gateway = "${var.vm_ipv4_gateway}"
    }
  }

  network_interface {
    network_id = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${var.vm_adapter_type}"
  }

  disk {
    label = "${var.vm_name_prefix}0.vmdk"
    size = "${var.vm_root_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }
 
  provisioner "file" {
    source      = "redhat_monkey.repo"
    destination = "/tmp/redhat_monkey.repo"
  }
  
  provisioner "file" {
    source      = "init_vm.sh"
    destination = "/tmp/init_vm.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /tmp/init_vm.sh",
      "/tmp/init_vm.sh ${var.monkey_mirror} ${var.vm_dns_servers[0]} '${var.public_ssh_key}'"
    ]
  }

}




###########################################################################################################################################################

# NFS
resource "vsphere_virtual_machine" "icpnfs" {
  count="${local.num_nfs}"
  name = "${var.vm_name_prefix}-nfs-${ count.index }"

  num_cpus = "8"
  memory = "16384"

  resource_pool_id = "${element(data.vsphere_resource_pool.vm_resource_pools.*.id, count.index )}"
  datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"

  guest_id = "${element(data.vsphere_virtual_machine.vm_templates.*.guest_id, count.index )}"
  clone {
    template_uuid = "${element(data.vsphere_virtual_machine.vm_templates.*.id, count.index )}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-nfs-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + local.num_driver + local.num_idm  + local.num_haproxy }"
        ipv4_netmask = "${ var.vm_ipv4_prefix_length }"
      }
    ipv4_gateway = "${var.vm_ipv4_gateway}"
    }
  }

  network_interface {
    network_id = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${var.vm_adapter_type}"
  }

  disk {
    label = "${var.vm_name_prefix}0.vmdk"
    size = "${var.vm_root_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
  }
  
  disk {
    label = "${var.vm_name_prefix}1.vmdk"
    size = "2000"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
    unit_number = "1"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }
  
  provisioner "file" {
    source      = "redhat_monkey.repo"
    destination = "/tmp/redhat_monkey.repo"
  }
  
  provisioner "file" {
    source      = "init_vm.sh"
    destination = "/tmp/init_vm.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /tmp/init_vm.sh",
      "/tmp/init_vm.sh ${var.monkey_mirror} ${var.vm_dns_servers[0]} '${var.public_ssh_key}'"
    ]
  }
}



###########################################################################################################################################################

# ICP Master
resource "vsphere_virtual_machine" "icpmaster" {
  count         = "${local.num_master}"
#  count         = "0"
  name = "${var.vm_name_prefix}-master-${ count.index }"
  num_cpus = "${var.master_num_cpus}"
  memory = "${var.master_mem}"

  resource_pool_id = "${element(data.vsphere_resource_pool.vm_resource_pools.*.id, count.index )}"
  datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"

  guest_id = "${element(data.vsphere_virtual_machine.vm_templates.*.guest_id, count.index )}"
  clone {
    template_uuid = "${element(data.vsphere_virtual_machine.vm_templates.*.id, count.index )}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-master-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + local.num_driver + local.num_idm  + local.num_haproxy + local.num_nfs }"
        ipv4_netmask = "${ var.vm_ipv4_prefix_length }"
      }
    ipv4_gateway = "${var.vm_ipv4_gateway}"
    }
  }
  
  hv_mode = "hvOn"
  ept_rvi_mode = "on"
  nested_hv_enabled = "true"

  network_interface {
    network_id = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${var.vm_adapter_type}"
  }

  disk {
    label = "${var.vm_name_prefix}0.vmdk"
    size = "${var.vm_root_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
  }
  
  disk {
    label = "${var.vm_name_prefix}1.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
    unit_number = "2"
  }


  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }
 
  provisioner "file" {
    source      = "redhat_monkey.repo"
    destination = "/tmp/redhat_monkey.repo"
  }

  
  provisioner "file" {
    source      = "init_vm.sh"
    destination = "/tmp/init_vm.sh"
  }
  
  provisioner "file" {
    source      = "setup_storage.sh"
    destination = "/tmp/setup_storage.sh"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod 755 /tmp/*.sh",
      "/tmp/init_vm.sh ${var.monkey_mirror} ${var.vm_dns_servers[0]} '${var.public_ssh_key}'",
      "/tmp/setup_storage.sh master"
    ]
  }
}



###########################################################################################################################################################

# ICP Infra
resource "vsphere_virtual_machine" "icpinfra" {
  count         = "${local.num_infra}"
#  count         = "0"
  name = "${var.vm_name_prefix}-infra-${ count.index }"

  num_cpus = "${var.infra_num_cpus}"
  memory = "${var.infra_mem}"

  resource_pool_id = "${element(data.vsphere_resource_pool.vm_resource_pools.*.id, count.index )}"
  datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"

  guest_id = "${element(data.vsphere_virtual_machine.vm_templates.*.guest_id, count.index )}"
  clone {
    template_uuid = "${element(data.vsphere_virtual_machine.vm_templates.*.id, count.index )}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-infra-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + local.num_driver + local.num_idm  + local.num_haproxy + local.num_nfs + local.num_master }"
        ipv4_netmask = "${ var.vm_ipv4_prefix_length }"
      }
    ipv4_gateway = "${var.vm_ipv4_gateway}"
    }
  }

  network_interface {
    network_id = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${var.vm_adapter_type}"
  }

  disk {
    label = "${var.vm_name_prefix}0.vmdk"
    size = "${var.vm_root_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
  }
  
  disk {
    label = "${var.vm_name_prefix}1.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
    unit_number = "2"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }
  
  provisioner "file" {
    source      = "redhat_monkey.repo"
    destination = "/tmp/redhat_monkey.repo"
  }
  
  provisioner "file" {
    source      = "init_vm.sh"
    destination = "/tmp/init_vm.sh"
  }
  
  provisioner "file" {
    source      = "setup_storage.sh"
    destination = "/tmp/setup_storage.sh"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod 755 /tmp/*.sh",
      "/tmp/init_vm.sh ${var.monkey_mirror} ${var.vm_dns_servers[0]} '${var.public_ssh_key}'",
      "/tmp/setup_storage.sh infra"
    ]
  }
}


###########################################################################################################################################################

# ICP Workers
resource "vsphere_virtual_machine" "icpworker" {
  count="${local.num_worker}"
#  count         = "0"
  name = "${var.vm_name_prefix}-worker-${ count.index }"

  num_cpus = "${var.worker_num_cpus}"
  memory = "${var.worker_mem}"

  resource_pool_id = "${element(data.vsphere_resource_pool.vm_resource_pools.*.id, count.index )}"
  datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
  
  guest_id = "${element(data.vsphere_virtual_machine.vm_templates.*.guest_id, count.index )}"
  clone {
    template_uuid = "${element(data.vsphere_virtual_machine.vm_templates.*.id, count.index )}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-worker-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + local.num_driver + local.num_idm  + local.num_haproxy + local.num_nfs + local.num_master + local.num_infra }"
        ipv4_netmask = "${ var.vm_ipv4_prefix_length }"
      }
    ipv4_gateway = "${var.vm_ipv4_gateway}"
    }
  }
  
  hv_mode = "hvOn"
  ept_rvi_mode = "on"
  nested_hv_enabled = "true"

  network_interface {
    network_id = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${var.vm_adapter_type}"
  }

  disk {
    label = "${var.vm_name_prefix}0.vmdk"
    size = "${var.vm_root_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
  }
  
  disk {
    label = "${var.vm_name_prefix}1.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
    unit_number = "2"
  }
  
  disk {
    label = "${var.vm_name_prefix}3.vmdk"
    size = "1000"
    keep_on_remove = "false"
    datastore_id = "${element(data.vsphere_datastore.vm_datastores.*.id, count.index )}"
    unit_number = "3"
  }


  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }

 
  provisioner "file" {
    source      = "redhat_monkey.repo"
    destination = "/tmp/redhat_monkey.repo"
  }
  
  provisioner "file" {
    source      = "init_vm.sh"
    destination = "/tmp/init_vm.sh"
  }
  
  provisioner "file" {
    source      = "setup_storage.sh"
    destination = "/tmp/setup_storage.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 755 /tmp/*.sh",
      "/tmp/init_vm.sh ${var.monkey_mirror} ${var.vm_dns_servers[0]} '${var.public_ssh_key}'",
      "/tmp/setup_storage.sh worker"
    ]
  }
}

resource "null_resource" "start_install" {

  
  
  depends_on = [ 
  	"vsphere_virtual_machine.driver",  
  	"vsphere_virtual_machine.idm",   
  	"vsphere_virtual_machine.icpmaster",  
  	"vsphere_virtual_machine.icpworker",  
  	"vsphere_virtual_machine.icpinfra",  
  	"vsphere_virtual_machine.icpnfs"
  ]

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host     = "${vsphere_virtual_machine.driver.clone.0.customize.0.network_interface.0.ipv4_address}"
    type     = "ssh"
    user     = "root"
    password = "${var.ssh_user_password}"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = [
    
      "echo  export cam_ssh_user=${var.ssh_user} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ssh_user_password=${var.ssh_user_password} >> /opt/monkey_cam_vars.txt",
    
#      "echo  export cam_sudo_user=${var.sudo_user} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_sudo_password=${var.sudo_password} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_vm_domain=${var.vm_domain} >> /opt/monkey_cam_vars.txt",      
      "echo  export cam_vm_dns_servers=${join(",",var.vm_dns_servers)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_vm_ipv4_prefix_length=${var.vm_ipv4_prefix_length} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_time_server=${var.time_server} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_cluster_name=${var.cluster_name} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_public_nic_name=${var.public_nic_name} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cloud_install_tar_file_name=${var.cloud_install_tar_file_name} >> /opt/monkey_cam_vars.txt",
      

      # For the SL VMs used so far, /dev/xvdb is defined as swap. Removing it for now...
      "echo  export cam_icp_nfs_data_devices=/disk2@/dev/sdb >> /opt/monkey_cam_vars.txt",

      "echo  export cam_icp_docker_device=/dev/sdc >> /opt/monkey_cam_vars.txt",
      
#      "echo  export cam_icp_data_devices=/ibm@/dev/sdd,/data@/dev/sde >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_portworx_devices=/dev/sdd >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_monkeymirror=${var.monkey_mirror} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_driver_ip=${join(",",vsphere_virtual_machine.driver.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_driver_name=${join(",",vsphere_virtual_machine.driver.*.name)} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_icpmasters_ip=${join(",",vsphere_virtual_machine.icpmaster.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpmasters_name=${join(",",vsphere_virtual_machine.icpmaster.*.name)} >> /opt/monkey_cam_vars.txt",    
      
      "echo  export cam_icpworkers_ip=${join(",",vsphere_virtual_machine.icpworker.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpworkers_name=${join(",",vsphere_virtual_machine.icpworker.*.name)} >> /opt/monkey_cam_vars.txt", 
      
      "echo  export cam_icpinfra_ip=${join(",",vsphere_virtual_machine.icpinfra.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpinfra_name=${join(",",vsphere_virtual_machine.icpinfra.*.name)} >> /opt/monkey_cam_vars.txt",  
     
      "echo  export cam_icpnfs_ip=${join(",",vsphere_virtual_machine.icpnfs.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpnfs_name=${join(",",vsphere_virtual_machine.icpnfs.*.name)} >> /opt/monkey_cam_vars.txt", 
     
      "echo  export cam_idm_install=${local.idm_install} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_fully_disable_idm=${var.fully_disable_idm} >> /opt/monkey_cam_vars.txt",
      # These variables are only relevant when tying the new cluster with an existing IDM instance
      "echo  export cam_idm_primary_hostname=${var.idm_primary_hostname} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_primary_ip=${var.idm_primary_ip} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_replica_hostname=${var.idm_replica_hostname} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_replica_ip=${var.idm_replica_ip} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_admin_password=${var.idm_admin_password} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_ldapsearch_password=${var.idm_ldapsearch_password} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_directory_manager_password=${var.idm_directory_manager_password} >> /opt/monkey_cam_vars.txt",
      
      # These variables are relevant only when a new IDM instance is created.
      # In this case, no IDM passwords are set here (they are created by the CAM integration Perl script)
      "echo  export cam_idm_ip=${join(",",vsphere_virtual_machine.idm.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_name=${join(",",vsphere_virtual_machine.idm.*.name)} >> /opt/monkey_cam_vars.txt",
  
      "echo  export cam_icp_haproxy_ip=${join(",",vsphere_virtual_machine.haproxy.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_haproxy_name=${join(",",vsphere_virtual_machine.haproxy.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_icp_network_cidr=${var.icp_network_cidr} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_service_cluster_ip_range=${var.icp_service_cluster_ip_range} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_cp4d_addons=${join(",",var.cp4d_addons)} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_cp4d_num_db2wh_nodes=${var.cp4d_num_db2wh_nodes} >> /opt/monkey_cam_vars.txt",

      "echo  export cam_dsxhi_hostname=${var.hdp_edge_node_hostname} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_dsxhi_ip=${var.hdp_edge_node_ip} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_install_portworx=${var.install_portworx} >> /opt/monkey_cam_vars.txt",
      
#      "echo  export cam_icp_cluster_vip=${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start} >> /opt/monkey_cam_vars.txt",
#      "echo  export cam_icp_proxy_vip=${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 1} >> /opt/monkey_cam_vars.txt",

#      "mkfifo /root/passphrase.fifo",
#      "chmod 600 /root/passphrase.fifo",
#      "echo ${var.ssh_key_passphrase} > /root/passphrase.fifo &",
       "echo ${var.ssh_key_passphrase} > /root/passphrase ",
       "chmod 600 /root/passphrase",
      
      "chmod 755 /opt/installation.sh",
      "nohup /opt/installation.sh &",
      "sleep 60"
    ]
  }
  
  
}
