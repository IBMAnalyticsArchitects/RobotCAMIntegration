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

variable "sudo_user" {
  description = "Sudo User"
}

variable "sudo_password" {
  description = "Sudo Password"
}

variable "private_vlan_number" {
  description = "Private VLAN Number"
}

variable "private_vlan_router" {
  description = "Private VLAN router"
}

variable "public_vlan_number" {
  description = "Public VLAN Number"
}

variable "public_vlan_router" {
  description = "Public VLAN router"
}

variable "time_server" {
  description = "time_server"
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

variable "private_nic_name" {
  description = "private_nic_name"
}

variable "vm_dns_servers" {
  type = "list"
  description = "DNS servers for the virtual network adapter"
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

data "ibm_network_vlan" "private_cluster_vlan" {
    number = "${var.private_vlan_number}"
    router_hostname = "${var.private_vlan_router}"
}

data "ibm_network_vlan" "public_cluster_vlan" {
    number = "${var.public_vlan_number}"
    router_hostname = "${var.public_vlan_router}"
}


##############################################################
# Create VMs
##############################################################

###########################################################################################################################################################
# Driver
resource "ibm_compute_vm_instance" "icppubhaproxy" {
  count                    = "1"
  hostname                 = "${var.vm_name_prefix}-drv"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.private_cluster_vlan.id}"
  public_vlan_id          = "${data.ibm_network_vlan.public_cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = false
  cores                    = 4
  memory                   = 4096
  disks                    = [100]
  dedicated_acct_host_only = false
  local_disk               = false
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

while true
do
	yum install expect -y
	rc=$?
	if [ $rc -ne 0 ]
	then
		echo "Retrying yum install (wait 5s)..."
		sleep 5
	else
		break
	fi
done

#passphrase=`cat /root/passphrase.fifo`
passphrase=`cat /root/passphrase`

eval `ssh-agent`
/opt/addSshKeyId.exp $passphrase

set -x 

yum install python rsync unzip ksh perl  wget httpd firewalld createrepo -y
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


sed -i 's/cloud_replace_rhel_repo=0/cloud_replace_rhel_repo=1/' global.properties
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


softlayer/01_setup_softlayer_vms.sh /dev/xvdc >01_setup_softlayer_vms.log 2>&1

utils/01_prepare_all_nodes.sh >01_prepare_all_nodes.log 2>&1


#nohup icp_files/01_master_standalone_icp4d.sh &
nohup cp4d_files/01_master_cp4d.sh &

EOF

    destination = "/opt/installation.sh"

  }
}



############################################################################################################################################################
# Start Install
resource "null_resource" "start_install" {

  depends_on = [ 
  	"ibm_compute_vm_instance.icppubhaproxy"
  ]
  
  connection {
    host     = "${ibm_compute_vm_instance.driver.0.ipv4_address_private}"
    type     = "ssh"
    user     = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }

  provisioner "remote-exec" {
    inline = [

      "echo  export cam_sudo_password=${var.sudo_password} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_vm_domain=${var.vm_domain} >> /opt/monkey_cam_vars.txt",  
      "echo  export cam_vm_dns_servers=${join(",",var.vm_dns_servers)} >> /opt/monkey_cam_vars.txt",     

      "echo  export cam_time_server=${var.time_server} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_public_nic_name=${var.public_nic_name} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_private_nic_name=${var.private_nic_name} >> /opt/monkey_cam_vars.txt",
      "echo  export cloud_install_tar_file_name=${var.cloud_install_tar_file_name} >> /opt/monkey_cam_vars.txt",

      
      "echo  export cam_monkeymirror=${var.monkey_mirror} >> /opt/monkey_cam_vars.txt",
   
      "echo  export cam_icp_public_haproxy_ip=${join(",",ibm_compute_vm_instance.icppubhaproxy.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_public_haproxy_name=${join(",",ibm_compute_vm_instance.icppubhaproxy.*.hostname)} >> /opt/monkey_cam_vars.txt",

       "echo ${var.ssh_key_passphrase} > /root/passphrase ",
       "chmod 600 /root/passphrase",

      "chmod 755 /opt/installation.sh",
      "nohup /opt/installation.sh &",
      "sleep 60"
    ]
  }
}
