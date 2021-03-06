
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

variable "ssh_user_password" {
  description = "The user password for ssh connection, which is default in template"
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



variable "monkey_mirror" {
  description = "Monkey Mirror IP or Hostname"
}

variable "num_datanodes" {
  description = "Number of HDP Datanodes to create"
}

variable "num_edgenodes" {
  description = "Number of HDP edge nodes to create"
}

variable "num_cassandra_nodes" {
  description = "Number of Cassandra nodes to create"
}

variable "vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "vm_domain" {
  description = "Domain Name of virtual machine"
}

#variable "vm_number_of_vcpu" {
#  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
#  default = "1"
#}

#variable "vm_memory" {
#  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
#  default = "1024"
#}


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

variable "drv_num_cpus" {
  description = "Driver node CPU's"
}

variable "drv_mem" {
  description = "Driver node memory amount"
}

variable "idm_num_cpus" {
  description = "IDM node CPU's"
}

variable "idm_mem" {
  description = "IDM node memory amount"
}

variable "http_num_cpus" {
  description = "IS HTTP node CPU's"
}

variable "http_mem" {
  description = "IS HTTP node memory amount"
}

variable "was_num_cpus" {
  description = "IS Services WAS node CPU's"
}

variable "was_mem" {
  description = "IS Services WAS node memory amount"
}

variable "db2_num_cpus" {
  description = "IS DB2 node CPU's"
}

variable "db2_mem" {
  description = "IS DB2 node memory amount"
}

variable "haproxy_num_cpus" {
  description = "HAProxy node CPU's"
}

variable "haproxy_mem" {
  description = "HAProxy node memory amount"
}

variable "bigsql_num_cpus" {
  description = "BigSQL management node CPU's"
}

variable "bigsql_mem" {
  description = "BigSQL management node memory amount"
}

variable "edge_num_cpus" {
  description = "Edge node CPU's"
}

variable "edge_mem" {
  description = "Edge node memory amount"
}

variable "cassandra_num_cpus" {
  description = "Cassandra node CPU's"
}

variable "cassandra_mem" {
  description = "Cassandra node memory amount"
}

variable "datanode_num_cpus" {
  description = "datanode_num_cpus"
}

variable "datanode_mem" {
  description = "datanode_mem"
}

variable "vm_datanode_disk_size" {
  description = "Datanode Data Disk Size"
  default = "100"
}

variable "mgmtnode_num_cpus" {
  description = "mgmtnode_num_cpus"
}

variable "mgmtnode_mem" {
  description = "mgmtnode_mem"
}

variable "vm_mgmtnode_disk_size" {
  description = "Management Node Data Disk Size"
  default = "20"
}

variable "vm-image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

variable "public_nic_name" {
  description = "Name of the public network interface"
  default = "ens192"
}

variable "cluster_name" {
  description = "HDP Cluster Name"
  default = "MYCLUSTER"
}

variable "cloud_install_tar_file_name" {
  description = "Name of the tar file downloaded from the mirror, which contains the Cloud Installer code."
  default = "cloud_install.tar"
}

variable "install_infoserver" {
  description = "install_infoserver"
}

variable "install_bigsql" {
  description = "install_bigsql"
}

variable "enable_bigsql_ranger" {
  description = "Enable Ranger plug-in for Big SQL"
}

variable "dsengine_mem" {
  description = "dsengine_mem"
}

variable "dsengine_num_cpus" {
  description = "dsengine_num_cpus"
}

variable "enterprise_search_mem" {
  description = "enterprise_search_mem"
}

variable "enterprise_search_num_cpus" {
  description = "enterprise_search_num_cpus"
}


########
# Isolate IP address components:
locals {
  vm_ipv4_address_elements = "${split(".",var.vm_start_ipv4_address)}"
  vm_ipv4_address_base = "${format("%s.%s.%s",local.vm_ipv4_address_elements[0],local.vm_ipv4_address_elements[1],local.vm_ipv4_address_elements[2])}"
  vm_ipv4_address_start= "${local.vm_ipv4_address_elements[3] }"
}

###########################################################################################################################################################

# Driver 
resource "vsphere_virtual_machine" "driver" {
  name = "${var.vm_name_prefix}-drv"
#  num_cpus = "4"
  num_cpus = "${var.drv_num_cpus}"
#  memory = "4096"
  memory = "${var.drv_mem}"
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
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start  }"
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

echo "cloud_enable_yum_versionlock=0">>global.properties

. ./setenv

echo "Encrypt and remove global.properties"
$MASTER_INSTALLER_HOME/utils/01_encrypt_global_properties.sh global.properties
rm -f ./global.properties

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

nohup ./01_master_install_hdp.sh &

EOF

    destination = "/opt/installation.sh"

  }
  
}



###########################################################################################################################################################

# IDM
resource "vsphere_virtual_machine" "idm" {
  count="2"
  name = "${var.vm_name_prefix}-idm-${ count.index }"
#  num_cpus = "4"
  num_cpus = "${var.idm_num_cpus}"
#  memory = "4096"
  memory = "${var.idm_mem}"
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
      "chmod 600 /root/.ssh/config"
    ]
  }

}


############################################################################################################################################################


# IS HTTP Front-end
resource "vsphere_virtual_machine" "ishttp" {
  count="${ 1 * var.install_infoserver}"
  name = "${var.vm_name_prefix}-ishttp-${ count.index }"
#  num_cpus = "4"
  num_cpus = "${var.http_num_cpus}"
#  memory = "4096"
  memory = "${var.http_mem}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-ishttp-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 3 + count.index}"
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



# IS WAS-ND
resource "vsphere_virtual_machine" "iswasnd" {
  count="${ 3 * var.install_infoserver}"
  name = "${var.vm_name_prefix}-iswasnd-${ count.index }"
#  num_cpus = "${var.vm_number_of_vcpu}"
  num_cpus = "${var.was_num_cpus}"
#  memory = "${var.vm_memory}"
  memory = "${var.was_mem}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-iswasnd-${ count.index }"
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


# IS DB2
resource "vsphere_virtual_machine" "isdb2" {
  count="${ 2 * var.install_infoserver}"
  name = "${var.vm_name_prefix}-isdb2-${ count.index }"
#  num_cpus = "4"
  num_cpus = "${var.db2_num_cpus}"
#  memory = "8192"
  memory = "${var.db2_mem}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-isdb2-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 7 + count.index }"
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




# IS Engine
resource "vsphere_virtual_machine" "isds" {
  count="${ 1 * var.install_infoserver}"
  name = "${var.vm_name_prefix}-isds"
#  num_cpus = "${var.vm_number_of_vcpu}"
  num_cpus = "${var.dsengine_num_cpus}"
#  memory = "${var.vm_memory}"
  memory = "${var.dsengine_mem}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-isds"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 9 }"
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

# IS Enterprise Search
resource "vsphere_virtual_machine" "ises" {
  count="${ 1 * var.install_infoserver}"
  name = "${var.vm_name_prefix}-ises"
#  num_cpus = "${var.vm_number_of_vcpu}"
  num_cpus = "${var.enterprise_search_num_cpus}"
#  memory = "${var.vm_memory}"
#  memory = "65536"
  memory = "${var.enterprise_search_mem}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-ises"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 10 }"
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

#  disk {
#    label = "${var.vm_name_prefix}2.vmdk"
#    size = "600"
#    keep_on_remove = "false"
#    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
#    unit_number = "2"
#  }

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

# HAProxy
resource "vsphere_virtual_machine" "haproxy" {
  count="1"
  name = "${var.vm_name_prefix}-haproxy-${ count.index }"
#  num_cpus = "4"
  num_cpus = "${var.haproxy_num_cpus}"
#  memory = "4096"
  memory = "${var.haproxy_mem}"
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
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 11 + count.index }"
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



# BigSQL
resource "vsphere_virtual_machine" "bigsql-head" {
  count         = "${ 1 * var.install_bigsql }"
  name = "${var.vm_name_prefix}-bigsql-${ count.index }"
#  num_cpus = "${var.vm_number_of_vcpu}"
  num_cpus = "${var.bigsql_num_cpus}"
#  memory = "${var.vm_memory}"
  memory = "${var.bigsql_mem}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-bigsql-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + 12}"
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
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }
  
  disk {
    label = "${var.vm_name_prefix}3.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "3"
  }
  
  disk {
    label = "${var.vm_name_prefix}4.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "4"
  }

  
  disk {
    label = "${var.vm_name_prefix}5.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "5"
  }
  
  disk {
    label = "${var.vm_name_prefix}6.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "6"
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



############################################################################################################################################################

# HDP Management
resource "vsphere_virtual_machine" "hdp-mgmtnodes" {
	count  = "4"
  name = "${var.vm_name_prefix}-mn-${ count.index }"
#  num_cpus = "${var.vm_number_of_vcpu}"
  num_cpus = "${var.mgmtnode_num_cpus}"
#  memory = "${var.vm_memory}"
  memory = "${var.mgmtnode_mem}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-mn-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + 13 }"
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
    size = "${var.vm_mgmtnode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "${var.vm_mgmtnode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }
  
  disk {
    label = "${var.vm_name_prefix}3.vmdk"
    size = "${var.vm_mgmtnode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "3"
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


# HDP Datanodes
resource "vsphere_virtual_machine" "hdp-datanodes" {
	count  = "${var.num_datanodes}"
  name = "${var.vm_name_prefix}-dn-${ count.index }"
#  num_cpus = "${var.vm_number_of_vcpu}"
  num_cpus = "${var.datanode_num_cpus}"
#  memory = "${var.vm_memory}"
  memory = "${var.datanode_mem}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-dn-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + 17}"
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
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }
  
  disk {
    label = "${var.vm_name_prefix}3.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "3"
  }
  
  disk {
    label = "${var.vm_name_prefix}4.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "4"
  }

  
  disk {
    label = "${var.vm_name_prefix}5.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "5"
  }
  
  disk {
    label = "${var.vm_name_prefix}6.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "6"
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



# HDP edge nodes
resource "vsphere_virtual_machine" "hdp-edgenodes" {
	count  = "${var.num_edgenodes}"
  name = "${var.vm_name_prefix}-en-${ count.index }"
#  num_cpus = "${var.vm_number_of_vcpu}"
  num_cpus = "${var.edge_num_cpus}"
#  memory = "${var.vm_memory}"
  memory = "${var.edge_mem}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-en-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + 17 + var.num_datanodes}"
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




# Cassandra nodes
resource "vsphere_virtual_machine" "cassandra-nodes" {
	count  = "${var.num_cassandra_nodes}"
  name = "${var.vm_name_prefix}-cass-${ count.index }"
#  num_cpus = "${var.vm_number_of_vcpu}"
  num_cpus = "${var.cassandra_num_cpus}"
#  memory = "${var.vm_memory}"
  memory = "${var.cassandra_mem}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-cass-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + 17 + var.num_datanodes + var.num_edgenodes }"
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
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }
  
  disk {
    label = "${var.vm_name_prefix}3.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "3"
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
  	"vsphere_virtual_machine.ishttp",  
  	"vsphere_virtual_machine.iswasnd",  
  	"vsphere_virtual_machine.isdb2",  
  	"vsphere_virtual_machine.isds",    
  	"vsphere_virtual_machine.ises",  
  	"vsphere_virtual_machine.haproxy",  
  	"vsphere_virtual_machine.hdp-mgmtnodes",
  	"vsphere_virtual_machine.hdp-datanodes",
  	"vsphere_virtual_machine.hdp-edgenodes",
  	"vsphere_virtual_machine.bigsql-head",
  	"vsphere_virtual_machine.cassandra-nodes"
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
      
      "echo  export cam_sudo_password=XXXXX >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_vm_domain=${var.vm_domain} >> /opt/monkey_cam_vars.txt",      
      "echo  export cam_vm_dns_servers=${join(",",var.vm_dns_servers)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_vm_ipv4_prefix_length=${var.vm_ipv4_prefix_length} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_time_server=${var.time_server} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_public_nic_name=${var.public_nic_name} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_cluster_name=${var.cluster_name} >> /opt/monkey_cam_vars.txt",
      "echo  export cloud_install_tar_file_name=${var.cloud_install_tar_file_name} >> /opt/monkey_cam_vars.txt",
      
      # Hardcode the list of data devices here...
      # It must be updated if the data node template is modified.
      # This list must match the number of disks and naming format, for the data node template definition.
      "echo  export cam_cloud_biginsights_data_devices=/disk1@/dev/sdb,/disk2@/dev/sdc,/disk3@/dev/sdd,/disk4@/dev/sde,/disk5@/dev/sdf,/disk6@/dev/sdg,/disk7@/dev/sdh,/disk8@/dev/sdi,/disk9@/dev/sdj,/disk10@/dev/sdk,/disk11@/dev/sdl,/disk12@/dev/sdm,/disk13@/dev/sdn >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_monkeymirror=${var.monkey_mirror} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_driver_ip=${join(",",vsphere_virtual_machine.driver.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_driver_name=${join(",",vsphere_virtual_machine.driver.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_idm_ip=${join(",",vsphere_virtual_machine.idm.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_name=${join(",",vsphere_virtual_machine.idm.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_ishttp_ip=${join(",",vsphere_virtual_machine.ishttp.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ishttp_name=${join(",",vsphere_virtual_machine.ishttp.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_iswasnd_ip=${join(",",vsphere_virtual_machine.iswasnd.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_iswasnd_name=${join(",",vsphere_virtual_machine.iswasnd.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_isdb2_ip=${join(",",vsphere_virtual_machine.isdb2.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_isdb2_name=${join(",",vsphere_virtual_machine.isdb2.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_isds_ip=${join(",",vsphere_virtual_machine.isds.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_isds_name=${join(",",vsphere_virtual_machine.isds.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_ises_ip=${join(",",vsphere_virtual_machine.ises.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ises_name=${join(",",vsphere_virtual_machine.ises.*.name)} >> /opt/monkey_cam_vars.txt",
#      "echo  export cam_ises_ug_device=/dev/sdc >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ises_weave_net_ip_range=172.30.0.0/16 >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ises_service_ip_range=172.31.200.0/21 >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_haproxy_ip=${join(",",vsphere_virtual_machine.haproxy.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_haproxy_name=${join(",",vsphere_virtual_machine.haproxy.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_hdp_mgmtnodes_ip=${join(",",vsphere_virtual_machine.hdp-mgmtnodes.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_hdp_mgmtnodes_name=${join(",",vsphere_virtual_machine.hdp-mgmtnodes.*.name)} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_hdp_datanodes_ip=${join(",",vsphere_virtual_machine.hdp-datanodes.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_hdp_datanodes_name=${join(",",vsphere_virtual_machine.hdp-datanodes.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_hdp_edgenodes_ip=${join(",",vsphere_virtual_machine.hdp-edgenodes.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_hdp_edgenodes_name=${join(",",vsphere_virtual_machine.hdp-edgenodes.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_cassandra_nodes_ip=${join(",",vsphere_virtual_machine.cassandra-nodes.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_cassandra_nodes_name=${join(",",vsphere_virtual_machine.cassandra-nodes.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_bigsql_head_ip=${join(",",vsphere_virtual_machine.bigsql-head.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_bigsql_head_name=${join(",",vsphere_virtual_machine.bigsql-head.*.name)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_bigsql_ranger_plugin=${var.enable_bigsql_ranger} >> /opt/monkey_cam_vars.txt",
      
#      "mkfifo /root/passphrase.fifo",
#      "chmod 600 /root/passphrase.fifo",
#      "echo ${var.ssh_key_passphrase} > /root/passphrase.fifo &",
       "echo ${var.ssh_key_passphrase} > /root/passphrase ",
       "chmod 600 /root/passphrase",

      "chmod 700 /opt/installation.sh",
      "nohup /opt/installation.sh &",
      
      "sleep 120"
    ]
  }
}
