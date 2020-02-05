#################################################################
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2017, 2018.
#
#################################################################

#provider "aws" {
#  version = "~> 1.2"
#  region  = "${var.aws_region}"
#}

provider "aws" {
  region = "${var.aws_region}"
  version = "~> 2.13"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

variable "access_key" {
  description = "access_key"
}


variable "secret_key" {
  description = "secret_key"
}


variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "aws_owner" {
  description = "Owner of AWS instances."
  default     = "jlerm@us.ibm.com"
}

variable "default_tags" {
  type    = "map"
  default = {
    Owner         = "jlerm@us.ibm.com"
  }

}

variable "vpc_name_tag" {
  description = "Name of the Virtual Private Cloud (VPC) this resource is going to be deployed into"
}

#variable "subnet_cidrs" {
#  type = "list"
#  description = "Subnet cidrs"
#}
data "aws_vpc" "selected" {
  state = "available"

  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name_tag}"]
  }
}
#
#data "aws_subnet" "selected" {
#  state      = "available"
#  vpc_id     = "${data.aws_vpc.selected.id}"
#  cidr_block = "${var.subnet_cidr}"
#}

#Variable : AWS image name
variable "aws_image" {
  type = "string"
  description = "Operating system image id / template that should be used when creating the virtual image"
  default = "ami-c998b6b2"
}



variable "vm_ipv4_prefix_length" {
  description = "CIDR prefix for VM subnets"
}

variable "vm_name_prefix" {
  description = "Prefix for vm names"
}

variable "vm_domain" {
  description = "Domain Name of virtual machine"
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


#variable "icp_network_cidr" {
#  description = "ICP Network CIDR"
#}
#
#variable "icp_service_cluster_ip_range" {
#  description = "ICP Cluster IP Range"
#}

variable "instance_type" {
  description = "instance_type"
}

###


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



variable "public_ssh_key_name" {
  description = "Name of the public SSH key used to connect to the virtual guest"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guest"
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

variable "availability_zones" {
  type = "list"
  description = "availability_zones"
}

variable "subnet_ids" {
  type = "list"
  description = "subnet_ids"
}

variable "security_group_ids" {
  type = "list"
  description = "security_group_ids"
}

variable "ebs_vol_iops" {
  type = "string"
  description = "IOPS for EBS volume (ICP storage)"
  default = "1000"
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

locals {
  idm_install = "${ var.idm_primary_hostname=="" || var.idm_primary_ip=="" || var.idm_admin_password=="" || var.idm_ldapsearch_password=="" || var.idm_directory_manager_password=="" ? 1 : 0 }"
}


#######################

resource "aws_key_pair" "orpheus_public_key" {
  key_name   = "${var.public_ssh_key_name}"
  public_key = "${var.public_ssh_key}"
}


##############################################################
# Create temp public key for ssh connection
##############################################################
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "temp_public_key" {
  key_name   = "${var.public_ssh_key_name}-temp"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

##############################################################
# Create VMs
##############################################################

###########################################################################################################################################################
# Driver
#
resource "aws_instance" "driver" {
  count         = "1"
  tags { Name = "${var.vm_name_prefix}-driver.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-driver", Owner = "${var.aws_owner}" }
  instance_type = "m4.xlarge"
  availability_zone = "${element(var.availability_zones, 0)}"
  ami           = "${var.aws_image}"
  subnet_id     = "${element(var.subnet_ids, 0)}"
  vpc_security_group_ids = "${var.security_group_ids}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
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
    destination = "/tmp/addSshKeyId.exp"
  }

  

  provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-driver.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-driver.${var.vm_domain}\"",
      
      "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo su - -c 'systemctl restart sshd'",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo cp /tmp/addSshKeyId.exp /opt/addSshKeyId.exp",
      "sudo chmod 700 /opt/addSshKeyId.exp",
      "sudo yum update -y",
      "sudo yum-config-manager --enable *rhel*"
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

mkdir -p /opt/cloud_install; 

cd /opt/cloud_install;

. /opt/monkey_cam_vars.txt;

yum install -y ksh rsync expect unzip perl wget

wget http://$cam_monkeymirror/cloud_install/$cloud_install_tar_file_name

tar xf ./$cloud_install_tar_file_name

echo "Create key pair for the intra-cluster communications"
mkdir -p /opt/cloud_install/ssh_keys
ssh-keygen -t rsa -N "" -f /opt/cloud_install/ssh_keys/id_rsa
chmod 700 /opt/cloud_install/ssh_keys
chmod 600 /opt/cloud_install/ssh_keys/id_rsa

echo "Generate new global.properties"
perl -f cam_integration/01_gen_cam_install_properties.pl

sed -i 's/cloud_replace_rhel_repo=0/cloud_replace_rhel_repo=1/' global.properties
echo "cloud_enable_yum_versionlock=0">>global.properties

. ./setenv

#if [ "X$cam_icp_haproxy_vip" != "X"]
#then
#    ssh $cam_icp_haproxy_vip "halt -p"
#fi

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

aws_files/01_setup_ec2_instances.sh

utils/01_prepare_all_nodes.sh

#nohup icp_files/01_master_standalone_icp4d.sh &
nohup cp4d_files/01_master_cp4d.sh &

EOF

    destination = "/tmp/installation.sh"

  }
  
}


###########################################################################################################################################################
# ICP IDM
#
resource "aws_instance" "icpidm" {
#  count="${ 2 * local.idm_install }"
  count="1"
  tags { Name = "${var.vm_name_prefix}-icpidm-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-icpidm-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "m4.2xlarge"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  vpc_security_group_ids = "${var.security_group_ids}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }
  
 provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-icpidm-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-icpidm-${ count.index }.${var.vm_domain}\"",
      
      "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo su - -c 'systemctl restart sshd'",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo yum update -y",
      "sudo yum-config-manager --enable *rhel*"
    ]
 }

   provisioner "file" {
    content = <<EOF
var=60
tmp=10
opt=10
home=10
EOF
    destination = "/tmp/filesystemLayout.txt"
}
  
}



###########################################################################################################################################################
# ICP Master
#
resource "aws_instance" "icpmaster" {
  count         = "1"
  tags { Name = "${var.vm_name_prefix}-icpmaster-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-icpmaster-${ count.index }", Owner = "${var.aws_owner}" }
#  instance_type = "${var.instance_type}"
  instance_type = "m4.4xlarge"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  vpc_security_group_ids = "${var.security_group_ids}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "300", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "800", "delete_on_termination" = true }
#  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "io1", "volume_size" = "${var.docker_vol_size}", "delete_on_termination" = true iops="${var.ebs_vol_iops}" }
  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "gp2", "volume_size" = "${var.docker_vol_size}", "delete_on_termination" = true  }
 
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }
 
   provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-icpmaster-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-icpmaster-${ count.index }.${var.vm_domain}\"",
      
      "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo su - -c 'systemctl restart sshd'",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo yum update -y",
      "sudo yum-config-manager --enable *rhel*",
      "sudo mv /data /data.bkp",
      "sudo su - -c 'sed -i s/NM_CONTROLLED=.*/NM_CONTROLLED=YES/ /etc/sysconfig/network-scripts/ifcfg-eth0'"
    ]
 }


 
 provisioner "file" {
    content = <<EOF
var=400
tmp=30
opt=300
home=10
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}


###########################################################################################################################################################
# ICP Infra
#
resource "aws_instance" "icpinfra" {
  count         = "1"
  tags { Name = "${var.vm_name_prefix}-icpinfra-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-icpinfra-${ count.index }", Owner = "${var.aws_owner}" }
#  instance_type = "${var.instance_type}"
  instance_type = "m4.4xlarge"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  vpc_security_group_ids = "${var.security_group_ids}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "300", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "500", "delete_on_termination" = true }
#  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "io1", "volume_size" = "${var.docker_vol_size}", "delete_on_termination" = true iops="${var.ebs_vol_iops}" }
  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "gp2", "volume_size" = "${var.docker_vol_size}", "delete_on_termination" = true  }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }
 
   provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-icpinfra-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-icpinfra-${ count.index }.${var.vm_domain}\"",
      
      "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo su - -c 'systemctl restart sshd'",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo yum update -y",
      "sudo yum-config-manager --enable *rhel*",
      "sudo mv /data /data.bkp",
      "sudo su - -c 'sed -i s/NM_CONTROLLED=.*/NM_CONTROLLED=YES/ /etc/sysconfig/network-scripts/ifcfg-eth0'"
    ]
 }


 
 provisioner "file" {
    content = <<EOF
var=400
tmp=30
opt=10
home=10
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}




###########################################################################################################################################################
# ICP Workers
#
resource "aws_instance" "icpworker" {
  count         = "${var.num_workers}"
  tags { Name = "${var.vm_name_prefix}-icpworker-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-icpworker-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "${var.instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  vpc_security_group_ids = "${var.security_group_ids}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "300", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "500", "delete_on_termination" = true }
#  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "io1", "volume_size" = "${var.docker_vol_size}", "delete_on_termination" = true iops="${var.ebs_vol_iops}" }
#  ebs_block_device = { "device_name" = "/dev/sdd", "volume_type" = "io1", "volume_size" = "${var.portworx_vol_size}", "delete_on_termination" = true iops="${var.ebs_vol_iops}" }
  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "gp2", "volume_size" = "${var.docker_vol_size}", "delete_on_termination" = true  }
  ebs_block_device = { "device_name" = "/dev/sdd", "volume_type" = "gp2", "volume_size" = "${var.portworx_vol_size}", "delete_on_termination" = true  }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }
  
  
  provisioner "remote-exec" {
    inline = [
      "echo \"${var.vm_name_prefix}-icpworker-${ count.index }.${var.vm_domain}\">/tmp/hostname",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-icpworker-${ count.index }.${var.vm_domain}\"",
      
      
      "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo su - -c 'systemctl restart sshd'",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo yum update -y",
      "sudo yum-config-manager --enable *rhel*",
      "sudo mv /data /data.bkp",
      "sudo su - -c 'sed -i s/NM_CONTROLLED=.*/NM_CONTROLLED=YES/ /etc/sysconfig/network-scripts/ifcfg-eth0'"
    ]
 }

 provisioner "file" {
    content = <<EOF
var=400
tmp=30
opt=10
home=10
EOF
    destination = "/tmp/filesystemLayout.txt"
}
  
}



###########################################################################################################################################################
# ICP NFS
#
resource "aws_instance" "icpnfs" {
  count         = "1"
  tags { Name = "${var.vm_name_prefix}-icpnfs-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-icpnfs-${ count.index }", Owner = "${var.aws_owner}" }
#  instance_type = "${var.instance_type}"
  instance_type = "m4.4xlarge"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  vpc_security_group_ids = "${var.security_group_ids}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "gp2", "volume_size" = "1000", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }
  
  
  provisioner "remote-exec" {
    inline = [
      "echo \"${var.vm_name_prefix}-icpnfs-${ count.index }.${var.vm_domain}\">/tmp/hostname",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-icpnfs-${ count.index }.${var.vm_domain}\"",
      
      
      "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo su - -c 'systemctl restart sshd'",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo yum update -y",
      "sudo yum-config-manager --enable *rhel*",
      "sudo mv /data /data.bkp",
      "sudo su - -c 'sed -i s/NM_CONTROLLED=.*/NM_CONTROLLED=YES/ /etc/sysconfig/network-scripts/ifcfg-eth0'"
    ]
 }

 provisioner "file" {
    content = <<EOF
var=50
tmp=50
EOF
    destination = "/tmp/filesystemLayout.txt"
}
  
}



###########################################################################################################################################################
# ICP HAProxy
#
resource "aws_instance" "icphaproxy" {
  count         = "1"
  tags { Name = "${var.vm_name_prefix}-icphaproxy-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-icphaproxy-${ count.index }", Owner = "${var.aws_owner}" }
#  instance_type = "${var.instance_type}"
  instance_type = "m4.2xlarge"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  vpc_security_group_ids = "${var.security_group_ids}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }

  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }
  
  
  provisioner "remote-exec" {
    inline = [
      "echo \"${var.vm_name_prefix}-icphaproxy-${ count.index }.${var.vm_domain}\">/tmp/hostname",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-icphaproxy-${ count.index }.${var.vm_domain}\"",
      
      
      "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo su - -c 'systemctl restart sshd'",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo yum update -y",
      "sudo yum-config-manager --enable *rhel*",
      "sudo mv /data /data.bkp",
      "sudo su - -c 'sed -i s/NM_CONTROLLED=.*/NM_CONTROLLED=YES/ /etc/sysconfig/network-scripts/ifcfg-eth0'"
    ]
 }

 provisioner "file" {
    content = <<EOF
var=50
tmp=50
EOF
    destination = "/tmp/filesystemLayout.txt"
}
  
}




############################################################################################################################################################
# Start Install
resource "null_resource" "start_install" {

  depends_on = [ 
  	"aws_instance.driver",   
  	"aws_instance.icpidm",   
  	"aws_instance.icphaproxy", 
  	"aws_instance.icpmaster", 
  	"aws_instance.icpworker", 
  	"aws_instance.icpnfs",
  	"aws_instance.icpinfra"
  ]

  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${aws_instance.driver.*.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
    
#      "echo  export cam_sudo_user=${var.sudo_user} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_sudo_password=XXXXX >> /tmp/monkey_cam_vars.txt",
      
      "echo  export cam_cluster_name=${var.cluster_name} >> /tmp/monkey_cam_vars.txt",
      
      "echo  export cam_private_ips=${join(",",aws_instance.driver.*.private_ip)} >> /tmp/monkey_cam_vars.txt",

      "echo  export cam_vm_domain=${var.vm_domain} >> /tmp/monkey_cam_vars.txt",     
      "echo  export cam_vm_dns_servers=${join(",",var.vm_dns_servers)} >> /tmp/monkey_cam_vars.txt",  

      "echo  export cam_time_server=${var.time_server} >> /tmp/monkey_cam_vars.txt",
     
      "echo  export cam_public_nic_name=${var.public_nic_name} >> /tmp/monkey_cam_vars.txt",
      "echo  export cloud_install_tar_file_name=${var.cloud_install_tar_file_name} >> /tmp/monkey_cam_vars.txt",
      
      "echo  export cam_monkeymirror=${var.monkey_mirror} >> /tmp/monkey_cam_vars.txt",
    
      "echo  export cam_driver_ip=${join(",",aws_instance.driver.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_driver_name=${join(",",aws_instance.driver.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
      
      "echo  export cam_icp_docker_device=/dev/xvdc >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_icp_portworx_devices=/dev/xvdd >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_icp_nfs_data_devices=/disk2@/dev/xvdc >> /tmp/monkey_cam_vars.txt",
      
      "echo  export cam_icpmasters_ip=${join(",",aws_instance.icpmaster.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_icpmasters_name=${join(",",aws_instance.icpmaster.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",    
      
      "echo  export cam_icpworkers_ip=${join(",",aws_instance.icpworker.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_icpworkers_name=${join(",",aws_instance.icpworker.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",     
      
      "echo  export cam_icpinfra_ip=${join(",",aws_instance.icpinfra.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_icpinfra_name=${join(",",aws_instance.icpinfra.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt", 
      
      "echo  export cam_icpnfs_ip=${join(",",aws_instance.icpnfs.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_icpnfs_name=${join(",",aws_instance.icpnfs.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt", 
     
      "echo  export cam_idm_install=${local.idm_install} >> /tmp/monkey_cam_vars.txt",
      # These variables are only relevant when tying the new cluster with an existing IDM instance
      "echo  export cam_idm_primary_hostname=${var.idm_primary_hostname} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_idm_primary_ip=${var.idm_primary_ip} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_idm_replica_hostname=${var.idm_replica_hostname} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_idm_replica_ip=${var.idm_replica_ip} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_idm_admin_password=${var.idm_admin_password} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_idm_ldapsearch_password=${var.idm_ldapsearch_password} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_idm_directory_manager_password=${var.idm_directory_manager_password} >> /tmp/monkey_cam_vars.txt",
      
      # These variables are relevant only when a new IDM instance is created.
      # In this case, no IDM passwords are set here (they are created by the CAM integration Perl script)
      "echo  export cam_idm_ip=${join(",",aws_instance.icpidm.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_idm_name=${join(",",aws_instance.icpidm.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",

      "echo  export cam_icp_haproxy_ip=${join(",",aws_instance.icphaproxy.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_icp_haproxy_name=${join(",",aws_instance.icphaproxy.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
      
      # cam_icp_load_balancer_name
      #"echo  export cam_icp_load_balancer_name=${aws_lb.icp-console.dns_name} >> /tmp/monkey_cam_vars.txt",
    
#      "echo  export cam_icp_network_cidr=${var.icp_network_cidr} >> /tmp/monkey_cam_vars.txt",
#      "echo  export cam_icp_service_cluster_ip_range=${var.icp_service_cluster_ip_range} >> /tmp/monkey_cam_vars.txt",
      
      "echo  export cam_vm_ipv4_prefix_length=${var.vm_ipv4_prefix_length} >> /tmp/monkey_cam_vars.txt",
      
      
      "echo  export cam_cp4d_addons=${join(",",var.cp4d_addons)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_cp4d_num_db2wh_nodes=${var.cp4d_num_db2wh_nodes} >> /tmp/monkey_cam_vars.txt",

      "echo  export cam_dsxhi_hostname=${var.hdp_edge_node_hostname} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_dsxhi_ip=${var.hdp_edge_node_ip} >> /tmp/monkey_cam_vars.txt",

      "sudo mv /tmp/monkey_cam_vars.txt /opt/monkey_cam_vars.txt",
      "sudo mv /tmp/installation.sh /opt/installation.sh",
      "sudo chmod 755 /opt/installation.sh",
      
      "sudo mkfifo /root/passphrase.fifo",
      "sudo chmod 600 /root/passphrase.fifo",
      "sudo su - -c 'echo ${var.ssh_key_passphrase} > /root/passphrase.fifo &'",
      
      "sudo su -c 'cd;nohup /opt/installation.sh &'",
      "sleep 60"
    ]
  }
}

      

