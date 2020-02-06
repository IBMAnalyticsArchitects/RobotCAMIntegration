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

variable "vlan_number" {
  description = "VLAN Number"
}

variable "vlan_router" {
  description = "VLAN router"
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

variable "icp_network_cidr" {
  description = "ICP Network CIDR"
}

variable "icp_service_cluster_ip_range" {
  description = "ICP Cluster IP Range"
}

variable "cluster_name" {
  description = "Cluster Name"
  default = "MYCLUSTER"
}

variable "vm_dns_servers" {
  type = "list"
  description = "DNS servers for the virtual network adapter"
}

variable "num_workers" {
  description = "Number of ICP worker nodes to create"
  default="3"
}

variable "icp_num_cpus" {
  description = "Number of CPUs for ICP Master and Worker nodes"
  default = "16"
}

variable "icp_mem" {
  description = "Memory (MBs) for ICP Master and Worker nodes"
  default = "98384"
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

variable "docker_vol_size" {
  type = "string"
  description = "Size of docker volume"
  default = "1000"
}

variable "portworx_vol_size" {
  type = "string"
  description = "Size of Portworx volume"
  default = "1000"
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

locals {
  idm_install = "${ var.idm_primary_hostname=="" || var.idm_primary_ip=="" || var.idm_admin_password=="" || var.idm_ldapsearch_password=="" || var.idm_directory_manager_password=="" ? 1 : 0 }"
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
#  private_subnet           = "${var.private_subnet}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
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

passphrase=`cat /root/passphrase.fifo`

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

if [ "`echo $cloud_icp_addons | grep hadoop_integration`" != "" -a "${var.hdp_driver_ip}" != "" -a "$cloud_icp4d_dsxhi_hostname" != "" -a "$cloud_icp4d_dsxhi_ip" != "" ]
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
   # Copy installDsxhi.sh to driver and run
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


###########################################################################################################################################################
# ICP IDM
resource "ibm_compute_vm_instance" "icpidm" {
#  count="${ 2 * local.idm_install }"
  count="1"
  hostname = "${var.vm_name_prefix}-icpidm-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = 4
  memory                   = 4096
  disks                    = [100,1000]
  dedicated_acct_host_only = false
  local_disk               = false
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

###########################################################################################################################################################
# ICP HAProxy
resource "ibm_compute_vm_instance" "icphaproxy" {
  count="1"
  hostname = "${var.vm_name_prefix}-icphaproxy"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = 4
  memory                   = 4096
  disks                    = [100,1000]
  dedicated_acct_host_only = false
  local_disk               = false
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
# ICP Masters
resource "ibm_compute_vm_instance" "icpmaster" {
  count="1"
  hostname = "${var.vm_name_prefix}-icpmaster-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.icp_num_cpus}"
  memory                   = "${var.icp_mem}"
  disks                    = [100,1000,1000]
  dedicated_acct_host_only = false
  local_disk               = false
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
# ICP Infra
resource "ibm_compute_vm_instance" "icpinfra" {
  count="1"
  hostname = "${var.vm_name_prefix}-icpinfra-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.icp_num_cpus}"
  memory                   = "${var.icp_mem}"
  disks                    = [100,1000,1000]
  dedicated_acct_host_only = false
  local_disk               = false
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
# ICP Workers
resource "ibm_compute_vm_instance" "icpworker" {
  count="${var.num_workers}"
  hostname = "${var.vm_name_prefix}-icpworker-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.icp_num_cpus}"
  memory                   = "${var.icp_mem}"
  disks                    = [100,1000,1000,1000]
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.temp_public_key.id}"]

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
# ICP NFS
resource "ibm_compute_vm_instance" "icpnfs" {
  count="1"
  hostname = "${var.vm_name_prefix}-icpnfs-${ count.index }"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = "${var.icp_num_cpus}"
  memory                   = "${var.icp_mem}"
  disks                    = [100,1000,1000]
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.temp_public_key.id}"]

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
  	"ibm_compute_vm_instance.icpidm",  
  	"ibm_compute_vm_instance.icphaproxy",  
  	"ibm_compute_vm_instance.icpmaster",  
  	"ibm_compute_vm_instance.icpworker",  
  	"ibm_compute_vm_instance.icpnfs",
  	"ibm_compute_vm_instance.icpinfra"
  ]
  
  connection {
    host     = "${ibm_compute_vm_instance.driver.0.ipv4_address_private}"
    type     = "ssh"
    user     = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }

  provisioner "remote-exec" {
    inline = [
    
#      "echo  export cam_sudo_user=${var.sudo_user} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_sudo_password=${var.sudo_password} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_vm_domain=${var.vm_domain} >> /opt/monkey_cam_vars.txt",  
      "echo  export cam_vm_dns_servers=${join(",",var.vm_dns_servers)} >> /opt/monkey_cam_vars.txt",     

      "echo  export cam_time_server=${var.time_server} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_cluster_name=${var.cluster_name} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_public_nic_name=${var.public_nic_name} >> /opt/monkey_cam_vars.txt",
      "echo  export cloud_install_tar_file_name=${var.cloud_install_tar_file_name} >> /opt/monkey_cam_vars.txt",

      "echo  export cam_icp_docker_device=/dev/xvde >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_nfs_data_devices=/disk2@/dev/xvde >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_portworx_devices=/dev/xvdf >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_monkeymirror=${var.monkey_mirror} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_driver_ip=${join(",",ibm_compute_vm_instance.driver.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_driver_name=${join(",",ibm_compute_vm_instance.driver.*.hostname)} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_icpmasters_ip=${join(",",ibm_compute_vm_instance.icpmaster.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpmasters_name=${join(",",ibm_compute_vm_instance.icpmaster.*.hostname)} >> /opt/monkey_cam_vars.txt",    
      
      "echo  export cam_icpworkers_ip=${join(",",ibm_compute_vm_instance.icpworker.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpworkers_name=${join(",",ibm_compute_vm_instance.icpworker.*.hostname)} >> /opt/monkey_cam_vars.txt",    
      
      "echo  export cam_icpinfra_ip=${join(",",ibm_compute_vm_instance.icpinfra.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpinfra_name=${join(",",ibm_compute_vm_instance.icpinfra.*.hostname)} >> /opt/monkey_cam_vars.txt",    
      
      "echo  export cam_icpnfs_ip=${join(",",ibm_compute_vm_instance.icpnfs.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpnfs_name=${join(",",ibm_compute_vm_instance.icpnfs.*.hostname)} >> /opt/monkey_cam_vars.txt", 
     
      "echo  export cam_cp4d_num_db2wh_nodes=${var.cp4d_num_db2wh_nodes} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_icp_network_cidr=${var.icp_network_cidr} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_service_cluster_ip_range=${var.icp_service_cluster_ip_range} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_idm_ip=${join(",",ibm_compute_vm_instance.icpidm.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_name=${join(",",ibm_compute_vm_instance.icpidm.*.hostname)} >> /opt/monkey_cam_vars.txt",
      
      
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
      "echo  export cam_idm_ip=${join(",",ibm_compute_vm_instance.icpidm.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_name=${join(",",ibm_compute_vm_instance.icpidm.*.hostname)} >> /opt/monkey_cam_vars.txt",
 
    
      "echo  export cam_icp_haproxy_ip=${join(",",ibm_compute_vm_instance.icphaproxy.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_haproxy_name=${join(",",ibm_compute_vm_instance.icphaproxy.*.hostname)} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_cp4d_addons=${join(",",var.cp4d_addons)} >> /opt/monkey_cam_vars.txt",

      "echo  export cam_dsxhi_hostname=${var.hdp_edge_node_hostname} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_dsxhi_ip=${var.hdp_edge_node_ip} >> /opt/monkey_cam_vars.txt",

      "mkfifo /root/passphrase.fifo",
      "chmod 600 /root/passphrase.fifo",
      "echo ${var.ssh_key_passphrase} > /root/passphrase.fifo &",

      "chmod 755 /opt/installation.sh",
      "nohup /opt/installation.sh &",
      "sleep 60"
    ]
  }
}
