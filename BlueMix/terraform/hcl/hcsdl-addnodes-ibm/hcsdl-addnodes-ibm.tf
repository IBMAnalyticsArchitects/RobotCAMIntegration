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

variable "computenode_num_cpus" {
  description = "computenode_num_cpus"
}

variable "computenode_mem" {
  description = "computenode_mem"
}

variable "computenode_disks" {
  type = "list"
  description = "computenode_disks"
}

variable "driver_ip" {
  description = "Driver IP or Hostname"
}

variable "num_compute_nodes" {
  description = "Number of New HDP compute nodes to create"
}

variable "excluded_services" {
  description = "Comma-separated list of services to exclude from the new nodes"
}

variable "node_label" {
  description = "Node label for compute VMs"
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
    number = "${var.vlan_number}",
    router_hostname = "${var.vlan_router}"
}


##############################################################
# Create VMs
##############################################################




############################################################################################################################################################
# HDP Data Nodes
resource "ibm_compute_vm_instance" "hdp-computenodes" {
  count="${var.num_compute_nodes}"
  hostname = "${var.vm_name_prefix}-${var.node_label}-cn-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.computenode_num_cpus}"
  memory                   = "${var.computenode_mem}"
#  disks                    = "${var.computenode_disks}"
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
  	"ibm_compute_vm_instance.hdp-computenodes"
  ]
  
  connection {
    host     = "${ibm_compute_vm_instance.hdp-computenodes.0.ipv4_address_private}"
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
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
    content = <<EOF
#!/bin/sh

set -x 

yum install -y perl ksh rsync expect unzip  

#passphrase=`cat /root/passphrase.fifo`
passphrase=`cat /root/passphrase`
rm -f /root/passphrase

eval `ssh-agent`
chmod 700 /opt/addSshKeyId.exp
/opt/addSshKeyId.exp $passphrase

mkdir -p /opt/cloud_install; 

cd /opt/cloud_install;

. /opt/monkey_cam_vars.txt;

wget http://$cam_monkeymirror/cloud_install/$cloud_install_tar_file_name

tar xf ./$cloud_install_tar_file_name

echo "Generate new hosts.add"
perl -f cam_integration/01_gen_cam_addnodes_properties.pl

# Build cloud_hostpasswords only for the ones listed in the new hosts.add
s=""
for i in `cat hosts.add|awk '{print $2}'`; do if [ "$s" != "" ]; then sep=","; else sep="";fi; s="$s$sep$i:XXX"; done
export cloud_hostpasswords=$s

#####################
# Do some preparation on the original driver

ssh ${var.driver_ip} "set -x
cd /opt/cloud_install
. ./setenv
env|egrep "^cloud_" >global.properties
rm -rf /opt/cloud_install_${var.node_label}/
mkdir -p /opt/cloud_install_${var.node_label}
cd /opt/cloud_install_${var.node_label}
wget http://$cam_monkeymirror/cloud_install/$cloud_install_tar_file_name
tar xf ./$cloud_install_tar_file_name
cp /opt/cloud_install/global.properties /opt/cloud_install_${var.node_label}/
cp /opt/cloud_install/hosts /opt/cloud_install_${var.node_label}/
cp -r /opt/cloud_install/ssh_keys /opt/cloud_install_${var.node_label}/"

######################
# Copy hosts.add to driver
scp /opt/cloud_install/hosts.add ${var.driver_ip}:/opt/cloud_install_${var.node_label}

######################
# Create addNodes-${var.node_label}.sh to be executed on the driver
exclusions=""
if [ "${var.excluded_services}" != "" ]
then
	exclusions=" -e `echo ${var.excluded_services} | sed -r 's/[ \t]+/,/g'` "
fi
cat<<END>addNodes-${var.node_label}.sh
passphr=\$1
set -x
eval \`ssh-agent\`
/opt/addSshKeyId.exp \$passphr
cd /opt/cloud_install_${var.node_label}
. ./setenv

rm -f ~/.ssh/known_hosts
cat hosts.add >> /etc/hosts

# Set temporary cloud_hostpasswords
export cloud_hostpasswords=$cloud_hostpasswords
softlayer/01_setup_softlayer_vms.sh /dev/xvdc

. ./setenv

/opt/cloud_install_${var.node_label}/biginsights_files/01_add_datanodes.sh $exclusions /opt/cloud_install_${var.node_label}/hosts.add
END
chmod 700 addNodes-${var.node_label}.sh

#######################
# Copy addNodes-${var.node_label}.sh to driver
scp addNodes-${var.node_label}.sh ${var.driver_ip}:/opt/cloud_install_${var.node_label}/

#######################
# Invoke addNodes-${var.node_label}.sh w/ nohup
ssh ${var.driver_ip} "set -x
cd /opt/cloud_install_${var.node_label}/
nohup /opt/cloud_install_${var.node_label}/addNodes-${var.node_label}.sh $passphrase >/opt/cloud_install_${var.node_label}/addNodes-${var.node_label}.log 2>&1 &
sleep 60"

EOF

    destination = "/opt/addnode.sh"

  }
  

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = [
      "echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa",
      "chmod 600 /root/.ssh/id_rsa",
      
      "echo  export cam_sudo_password=XXXXX >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_node_label=${var.node_label} >> /opt/monkey_cam_vars.txt",   
      "echo  export cam_vm_domain=${var.vm_domain} >> /opt/monkey_cam_vars.txt",      
      "echo  export cam_vm_dns_servers=${join(",",var.vm_dns_servers)} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cloud_install_tar_file_name=${var.cloud_install_tar_file_name} >> /opt/monkey_cam_vars.txt",
            
      "echo  export cam_monkeymirror=${var.monkey_mirror} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_driver_ip=${var.driver_ip} >> /opt/monkey_cam_vars.txt",    
         
      "echo  export cam_hdp_addnodes_ip=${join(",",ibm_compute_vm_instance.hdp-computenodes.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_hdp_addnodes_name=${join(",",ibm_compute_vm_instance.hdp-computenodes.*.hostname)} >> /opt/monkey_cam_vars.txt",
    
      "echo ${var.ssh_key_passphrase} > /root/passphrase ",
      "chmod 600 /root/passphrase",

      "chmod 700 /opt/addnode.sh",
      "sleep 30",
      "nohup /opt/addnode.sh &",
      
      "sleep 60"
    ]
  }
}

