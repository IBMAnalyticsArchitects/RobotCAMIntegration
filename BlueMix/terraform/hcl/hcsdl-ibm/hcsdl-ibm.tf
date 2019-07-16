#################################################################
# Terraform template that will deploy Hybrid Secure Data Lake on IBM Cloud
#
#
# Julius Lerm, 9apr2018
#
# Version: 1.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2017.
#
#################################################################


#########################################################
# Define the ibmcloud provider
#########################################################
provider "ibm" {
}


#########################################################
# Define the variables
#########################################################
variable "datacenter" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
}

variable "vm_name_prefix" {
  description = "Prefix for vm names"
}

variable "vm_domain" {
  description = "Domain Name of virtual machine"
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

variable "vlan_number" {
  description = "VLAN Number"
}

variable "vlan_router" {
  description = "VLAN router"
}

variable "time_server" {
  description = "time_server"
}

variable "vm_dns_servers" {
  type = "list"
  description = "vm_dns_servers"
}

variable "monkey_mirror" {
  description = "monkey_mirror"
}

variable "cloud_install_tar_file_name" {
  description = "cloud_install_tar_file_name"
}

variable "public_nic_name" {
  description = "public_nic_name"
}

variable "cluster_name" {
  description = "cluster_name"
}

variable "mgmtnode_num_cpus" {
  description = "mgmtnode_num_cpus"
}

variable "mgmtnode_mem" {
  description = "mgmtnode_mem"
}

variable "mgmtnode_disks" {
  type = "list"
  description = "mgmtnode_disks"
}

variable "num_datanodes" {
  description = "num_datanodes"
}

variable "num_edgenodes" {
  description = "Number of HDP edge nodes to create"
}

variable "datanode_num_cpus" {
  description = "datanode_num_cpus"
}

variable "datanode_mem" {
  description = "datanode_mem"
}

variable "datanode_disks" {
  type = "list"
  description = "datanode_disks"
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

variable "num_cassandra_nodes" {
  description = "Number of Cassandra nodes to create"
}

variable "install_infoserver" {
  description = "install_infoserver"
}

variable "install_bigsql" {
  description = "install_bigsql"
}


##############################################################
# Create public key in Devices>Manage>SSH Keys in SL console
##############################################################
resource "ibm_compute_ssh_key" "cam_public_key" {
  label      = "CAM Public Key"
  public_key = "${var.public_ssh_key}"
}

##############################################################
# Create temp public key for ssh connection
##############################################################
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "ibm_compute_ssh_key" "temp_public_key" {
  label      = "Temp Public Key"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

data "ibm_network_vlan" "cluster_vlan" {
    number = "${var.vlan_number}"
    router_hostname = "${var.vlan_router}"
}


##############################################################
# Create VMs
##############################################################

###########################################################################################################################################################
# Driver
resource "ibm_compute_vm_instance" "driver" {
  count                    = "1"
  hostname                 = "${var.vm_name_prefix}-drv"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = 4
  memory                   = 4096
  wait_time_minutes        = 200
  disks                    = [100]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
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
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
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

passphrase=`cat /root/passphrase.fifo`

eval `ssh-agent`
/opt/addSshKeyId.exp $passphrase

set -x 

yum install -y perl ksh rsync expect unzip  
yum groupinstall "Infrastructure Server" -y

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

echo "Disable root login w/ password"
passwd -l root

echo "Generate new global.properties"
perl -f cam_integration/01_gen_cam_install_properties.pl

sed -i 's/cloud_replace_rhel_repo=1/cloud_replace_rhel_repo=0/' global.properties
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
		ssh.exp $hostName $hostPwd "passwd -l root;"
#		ssh.exp $hostName $hostPwd "yum install -y bc perl ksh rsync expect unzip; yum groupinstall 'Infrastructure Server' -y"
	fi
done

utils/01_prepare_all_nodes.sh >01_prepare_all_nodes.log 2>&1

softlayer/01_setup_softlayer_vms.sh /dev/xvdc >01_setup_softlayer_vms.log 2>&1

nohup ./01_master_install_hdp.sh &

EOF

    destination = "/opt/installation.sh"

  }
}


###########################################################################################################################################################
# IDM
resource "ibm_compute_vm_instance" "idm" {
  count="2"
  hostname = "${var.vm_name_prefix}-idm-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = 4
  wait_time_minutes        = 200
  memory                   = 4096
  disks                    = [100,1000]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=400
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}


############################################################################################################################################################
# IS HTTP Front-end
resource "ibm_compute_vm_instance" "ishttp" {
#  count="1"
  count="${ 1 * var.install_infoserver}"
  hostname = "${var.vm_name_prefix}-ishttp-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = 4
  memory                   = 16384
  wait_time_minutes        = 200
  disks                    = [100,1000]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=400
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}

############################################################################################################################################################
# IS WAS-ND
resource "ibm_compute_vm_instance" "iswasnd" {
#  count="3"
  count="${ 3 * var.install_infoserver}"
  hostname = "${var.vm_name_prefix}-iswasnd-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = 8
  memory                   = 32768
  wait_time_minutes        = 200
  disks                    = [100,1000]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=400
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}


############################################################################################################################################################
# IS DB2
resource "ibm_compute_vm_instance" "isdb2" {
#  count="2"
  count="${ 2 * var.install_infoserver}"
  hostname = "${var.vm_name_prefix}-isdb2-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = 8
  memory                   = 32768
  wait_time_minutes        = 200
  disks                    = [100,1000,2000,2000]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=400
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}


############################################################################################################################################################
# IS Engine
resource "ibm_compute_vm_instance" "isds" {
#  count="1"
  count="${ 1 * var.install_infoserver}"
  hostname = "${var.vm_name_prefix}-isds"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.dsengine_num_cpus}"
  memory                   = "${var.dsengine_mem}"
  wait_time_minutes        = 200
  disks                    = [100,1000,2000,2000]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=400
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}



############################################################################################################################################################
# IS Enterprise Search
resource "ibm_compute_vm_instance" "ises" {
#  count="1"
  count="${ 1 * var.install_infoserver}"
  hostname = "${var.vm_name_prefix}-ises"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.enterprise_search_num_cpus}"
  memory                   = "${var.enterprise_search_mem}"
  wait_time_minutes        = 200
  disks                    = [100,1500]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=1200
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}



############################################################################################################################################################
# HAProxy
resource "ibm_compute_vm_instance" "haproxy" {
  count="1"
  hostname = "${var.vm_name_prefix}-haproxy-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = 4
  memory                   = 4096
  wait_time_minutes        = 200
  disks                    = [100,1000]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=400
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}


############################################################################################################################################################
# HDP MAnagement Nodes
resource "ibm_compute_vm_instance" "hdp-mgmtnodes" {
  count="4"
  hostname = "${var.vm_name_prefix}-mn-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.mgmtnode_num_cpus}"
  wait_time_minutes        = 200
  memory                   = "${var.mgmtnode_mem}"
#  disks                    = "${var.mgmtnode_disks}"
  disks                    = [ 100,1000,2000,2000 ]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=400
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}


############################################################################################################################################################
# HDP Data Nodes
resource "ibm_compute_vm_instance" "hdp-datanodes" {
  count="${var.num_datanodes}"
  hostname = "${var.vm_name_prefix}-dn-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.datanode_num_cpus}"
  wait_time_minutes        = 200
  memory                   = "${var.datanode_mem}"
#  disks                    = "${var.datanode_disks}"
  disks                    = [100,1000,2000,2000,2000]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=400
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}

############################################################################################################################################################
# HDP Edge Nodes
resource "ibm_compute_vm_instance" "hdp-edgenodes" {
  count="${var.num_edgenodes}"
  hostname = "${var.vm_name_prefix}-en-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.datanode_num_cpus}"
  memory                   = "${var.datanode_mem}"
  wait_time_minutes        = 200
#  disks                    = "${var.datanode_disks}"
  disks                    = [100,1000,2000,2000,2000]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=400
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}

############################################################################################################################################################
# BigSQL Head Node
resource "ibm_compute_vm_instance" "bigsql-head" {
  count = "${ 1 * var.install_bigsql }"
  hostname = "${var.vm_name_prefix}-bigsql-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.datanode_num_cpus}"
  memory                   = "${var.datanode_mem}"
  wait_time_minutes        = 200
#  disks                    = "${var.datanode_disks}"
  disks                    = [100,1000,2000,2000,2000]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=400
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}



############################################################################################################################################################
# Cassandra Nodes
resource "ibm_compute_vm_instance" "cassandra-nodes" {
  count="${var.num_cassandra_nodes}"
  hostname = "${var.vm_name_prefix}-cass-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.datanode_num_cpus}"
  memory                   = "${var.datanode_mem}"
  wait_time_minutes        = 200
#  disks                    = "${var.datanode_disks}"
  disks                    = [100,1000,2000,2000,2000]
  dedicated_acct_host_only = false
  local_disk               = false
#  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  ssh_key_ids              = [ "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=400
tmp=100
opt=200
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}



############################################################################################################################################################
# Start Install
resource "null_resource" "start_install" {

  depends_on = [ 
  	"ibm_compute_vm_instance.driver",  
  	"ibm_compute_vm_instance.idm",  
  	"ibm_compute_vm_instance.ishttp",  
  	"ibm_compute_vm_instance.iswasnd",  
  	"ibm_compute_vm_instance.isdb2",  
  	"ibm_compute_vm_instance.isds",   
  	"ibm_compute_vm_instance.ises",  
  	"ibm_compute_vm_instance.haproxy",  
  	"ibm_compute_vm_instance.hdp-mgmtnodes",
  	"ibm_compute_vm_instance.hdp-datanodes",
  	"ibm_compute_vm_instance.hdp-edgenodes",
  	"ibm_compute_vm_instance.bigsql-head",
  	"ibm_compute_vm_instance.cassandra-nodes"
  ]
  
  connection {
    host     = "${ibm_compute_vm_instance.driver.0.ipv4_address_private}"
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }

  provisioner "remote-exec" {
    inline = [
    
      "echo  export cam_sudo_password=XXXXXX >> /opt/monkey_cam_vars.txt",

      "echo  export cam_vm_domain=${var.vm_domain} >> /opt/monkey_cam_vars.txt",      
      "echo  export cam_vm_dns_servers=${join(",",var.vm_dns_servers)} >> /opt/monkey_cam_vars.txt",

      "echo  export cam_time_server=${var.time_server} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_public_nic_name=${var.public_nic_name} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_cluster_name=${var.cluster_name} >> /opt/monkey_cam_vars.txt",
      "echo  export cloud_install_tar_file_name=${var.cloud_install_tar_file_name} >> /opt/monkey_cam_vars.txt",
      
      # Hardcode the list of data devices here...
      # It must be updated if the data node template is modified.
      # This list must match the naming format, for the data node template definition.
      
      # For the SL VMs used so far, /dev/xvdb is defined as swap.
      # /dev/xvdc is used for file systems such as /var,/home,/tmp.
      # /dev/xvdd does not exist.
#      "echo  export cam_cloud_biginsights_data_devices=/disk1@/dev/xvde,/disk2@/dev/xvdf,/disk3@/dev/xvdg,/disk4@/dev/xvdh,/disk5@/dev/xvdi,/disk6@/dev/xvdj,/disk7@/dev/xvdk,/disk8@/dev/xvdl,/disk9@/dev/xvdm,/disk10@/dev/xvdn >> /opt/monkey_cam_vars.txt",
      "echo  export cam_cloud_biginsights_data_devices=/disk1@/dev/xvde,/disk2@/dev/xvdf,/disk3@/dev/xvdg >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_monkeymirror=${var.monkey_mirror} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_driver_ip=${join(",",ibm_compute_vm_instance.driver.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_driver_name=${join(",",ibm_compute_vm_instance.driver.*.hostname)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_idm_ip=${join(",",ibm_compute_vm_instance.idm.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_name=${join(",",ibm_compute_vm_instance.idm.*.hostname)} >> /opt/monkey_cam_vars.txt",
    
    
      "echo  export cam_ishttp_ip=${join(",",ibm_compute_vm_instance.ishttp.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ishttp_name=${join(",",ibm_compute_vm_instance.ishttp.*.hostname)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_iswasnd_ip=${join(",",ibm_compute_vm_instance.iswasnd.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_iswasnd_name=${join(",",ibm_compute_vm_instance.iswasnd.*.hostname)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_isdb2_ip=${join(",",ibm_compute_vm_instance.isdb2.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_isdb2_name=${join(",",ibm_compute_vm_instance.isdb2.*.hostname)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_isds_ip=${join(",",ibm_compute_vm_instance.isds.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_isds_name=${join(",",ibm_compute_vm_instance.isds.*.hostname)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_ises_ip=${join(",",ibm_compute_vm_instance.ises.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ises_name=${join(",",ibm_compute_vm_instance.ises.*.hostname)} >> /opt/monkey_cam_vars.txt",
#      "echo  export cam_ises_ug_device=/dev/xvde >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ises_weave_net_ip_range=172.30.0.0/16 >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ises_service_ip_range=172.31.200.0/21 >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_haproxy_ip=${join(",",ibm_compute_vm_instance.haproxy.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_haproxy_name=${join(",",ibm_compute_vm_instance.haproxy.*.hostname)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_hdp_mgmtnodes_ip=${join(",",ibm_compute_vm_instance.hdp-mgmtnodes.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_hdp_mgmtnodes_name=${join(",",ibm_compute_vm_instance.hdp-mgmtnodes.*.hostname)} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_hdp_datanodes_ip=${join(",",ibm_compute_vm_instance.hdp-datanodes.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_hdp_datanodes_name=${join(",",ibm_compute_vm_instance.hdp-datanodes.*.hostname)} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_hdp_edgenodes_ip=${join(",",ibm_compute_vm_instance.hdp-edgenodes.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_hdp_edgenodes_name=${join(",",ibm_compute_vm_instance.hdp-edgenodes.*.hostname)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_cassandra_nodes_ip=${join(",",ibm_compute_vm_instance.cassandra-nodes.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_cassandra_nodes_name=${join(",",ibm_compute_vm_instance.cassandra-nodes.*.hostname)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_bigsql_head_ip=${join(",",ibm_compute_vm_instance.bigsql-head.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_bigsql_head_name=${join(",",ibm_compute_vm_instance.bigsql-head.*.hostname)} >> /opt/monkey_cam_vars.txt",
      
      "mkfifo /root/passphrase.fifo",
      "chmod 600 /root/passphrase.fifo",
      "echo ${var.ssh_key_passphrase} > /root/passphrase.fifo &",
      
      "chmod 700 /opt/installation.sh",
      "nohup /opt/installation.sh &",
      
      "sleep 120"
    ]
  }
}
