
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
data "vsphere_datastore" "vm_datastore" {
  name = "${var.vm_root_disk_datastore}"
  datacenter_id = "${data.vsphere_datacenter.vm_datacenter.id}"
}
data "vsphere_resource_pool" "vm_resource_pool" {
  name = "${var.vm_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.vm_datacenter.id}"
}
data "vsphere_network" "vm_network" {
  name = "${var.vm_network_interface_label}"
  datacenter_id = "${data.vsphere_datacenter.vm_datacenter.id}"
}

data "vsphere_virtual_machine" "vm_template" {
  name = "${var.vm-image}"
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

variable "num_workers" {
  description = "Number of OpenShift worker nodes to create"
}


variable "vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default = "1"
}

variable "vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default = "1024"
}


variable "vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
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

variable "vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
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
variable "vm-image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
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
  description = "OpenShift Network CIDR"
}

variable "icp_service_cluster_ip_range" {
  description = "OpenShift Cluster IP Range"
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



########
# Isolate IP address components:
locals {
  vm_ipv4_address_elements = "${split(".",var.vm_start_ipv4_address)}"
  vm_ipv4_address_base = "${format("%s.%s.%s",local.vm_ipv4_address_elements[0],local.vm_ipv4_address_elements[1],local.vm_ipv4_address_elements[2])}"
  vm_ipv4_address_start= "${local.vm_ipv4_address_elements[3] }"
  idm_install = "${ var.idm_primary_hostname=="" || var.idm_primary_ip=="" || var.idm_admin_password=="" || var.idm_ldapsearch_password=="" || var.idm_directory_manager_password=="" ? 1 : 0 }"
}

###########################################################################################################################################################

# Driver 
resource "vsphere_virtual_machine" "driver" {
  name = "${var.vm_name_prefix}-drv"
#  folder = "${var.vm_folder}"
  num_cpus = "4"
  memory = "4096"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
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
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
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
      "chmod 700 /opt/addSshKeyId.exp"
    ]
  }


  provisioner "file" {
    content = <<EOF
#!/bin/sh

yum install -y expect

#passphrase=`cat /root/passphrase.fifo`
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

sed -ri 's/cloud_icp_admin_password=.+$/cloud_icp_admin_password=password/' global.properties
#sed -i 's/cloud_replace_rhel_repo=1/cloud_replace_rhel_repo=0/' global.properties
echo "cloud_enable_yum_versionlock=0">>global.properties

. ./setenv

echo "Encrypt and remove global.properties"
$MASTER_INSTALLER_HOME/utils/01_encrypt_global_properties.sh global.properties
rm -f ./global.properties

utils/01_prepare_driver.sh

. $MASTER_INSTALLER_HOME/utils/00_globalFunctions.sh

# Add hosts entry for OpenShift console
firstMaster=`echo $cloud_icp_masters | cut -d',' -f1 | sed "s/,/ /g"`
echo "`get_host_ip $firstMaster` console.`echo $firstMaster|cut -d"." -f2-`" >> hosts

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

nohup $MASTER_INSTALLER_HOME/okd3_files/01_install_openshift.sh &

EOF

    destination = "/opt/installation.sh"

  }
  
}




###########################################################################################################################################################

# IDM
resource "vsphere_virtual_machine" "idm" {
  count="${ 1 * local.idm_install }"
#  count="0"
  name = "${var.vm_name_prefix}-idm-${ count.index }"
  num_cpus = "4"
  memory = "4096"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-idm-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + 1}"
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
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }


  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} > /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }

}



###########################################################################################################################################################

# HAProxy
resource "vsphere_virtual_machine" "haproxy" {
#  count="1"
  count="0"
  name = "${var.vm_name_prefix}-haproxy-${ count.index }"
  num_cpus = "4"
  memory = "4096"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-haproxy-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + 3 }"
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
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }


  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} > /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }

}




###########################################################################################################################################################

# OpenShift Master
resource "vsphere_virtual_machine" "icpmaster" {
  count="1"
  name = "${var.vm_name_prefix}-master-${ count.index }"
  num_cpus = "${var.vm_number_of_vcpu}"
  memory = "${var.vm_memory}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-master-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 4 + count.index }"
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
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  }
  
  disk {
    label = "${var.vm_name_prefix}1.vmdk"
    size = "300"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }
  
  disk {
    label = "${var.vm_name_prefix}3.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "3"
  }
  
  disk {
    label = "${var.vm_name_prefix}4.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "4"
  }


  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }


  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} > /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf",
      "pvcreate /dev/sdb",
      "vgextend vg_node1 /dev/sdb",
      "lvextend /dev/vg_node1/lv_root /dev/sdb",
      "resize2fs /dev/mapper/vg_node1-lv_root"
    ]
  }
}



###########################################################################################################################################################

# OpenShift Workers
resource "vsphere_virtual_machine" "icpworker" {
  count="${var.num_workers}"
  name = "${var.vm_name_prefix}-worker-${ count.index }"
#  folder = "${var.vm_folder}"
  num_cpus = "${var.vm_number_of_vcpu}"
  memory = "${var.vm_memory}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-worker-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 5 + count.index }"
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
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  }
  
  disk {
    label = "${var.vm_name_prefix}1.vmdk"
    size = "300"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }
  
  disk {
    label = "${var.vm_name_prefix}3.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "3"
  }
  
  disk {
    label = "${var.vm_name_prefix}4.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "4"
  }


  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }


  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} > /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf",
      "pvcreate /dev/sdb",
      "vgextend vg_node1 /dev/sdb",
      "lvextend /dev/vg_node1/lv_root /dev/sdb",
      "resize2fs /dev/mapper/vg_node1-lv_root"
    ]
  }
}

###########################################################################################################################################################

# OpenShift Infra
resource "vsphere_virtual_machine" "icpinfra" {
  count="1"
  name = "${var.vm_name_prefix}-infra-${ count.index }"
  num_cpus = "8"
  memory = "16384"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-infra-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 5 + var.num_workers + count.index }"
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
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  }
  
  disk {
    label = "${var.vm_name_prefix}1.vmdk"
    size = "300"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }
  
  disk {
    label = "${var.vm_name_prefix}3.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "3"
  }
  
  disk {
    label = "${var.vm_name_prefix}4.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "4"
  }
  
  
  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }
  
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} > /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf",
      "pvcreate /dev/sdb",
      "vgextend vg_node1 /dev/sdb",
      "lvextend /dev/vg_node1/lv_root /dev/sdb",
      "resize2fs /dev/mapper/vg_node1-lv_root"
    ]
  }
  
}

############################################################################################################################################################

# OpenShift NFS Server
resource "vsphere_virtual_machine" "icpnfs" {
	count  = "1"
  name = "${var.vm_name_prefix}-nfs-${ count.index }"
  num_cpus = "8"
  memory = "16384"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-nfs-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + 6 + var.num_workers }"
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
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  }
  
  disk {
    label = "${var.vm_name_prefix}1.vmdk"
    size = "1000"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  
  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
    host     = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
  }


  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} > /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
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
      
      "echo  export cam_icp_data_devices=/ibm@/dev/sdd,/data@/dev/sde >> /opt/monkey_cam_vars.txt",
      
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
