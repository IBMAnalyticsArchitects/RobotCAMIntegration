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


variable "icp_network_cidr" {
  description = "ICP Network CIDR"
}

variable "icp_service_cluster_ip_range" {
  description = "ICP Cluster IP Range"
}

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


variable "ebs_vol_iops" {
  type = "string"
  description = "IOPS for EBS volume (ICP storage)"
  default = "1000"
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
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'"
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

sed -i 's/cloud_replace_rhel_repo=1/cloud_replace_rhel_repo=0/' global.properties
echo "cloud_enable_yum_versionlock=0">>global.properties

. ./setenv

#if [ "X$cam_icp_haproxy_vip" != "X"]
#then
#    ssh $cam_icp_haproxy_vip "halt -p"
#fi

echo "Encrypt and remove global.properties"
$MASTER_INSTALLER_HOME/utils/01_encrypt_global_properties.sh global.properties
rm -f ./global.properties

utils/01_prepare_driver.sh

aws_files/01_setup_ec2_instances.sh

utils/01_prepare_all_nodes.sh

nohup icp_files/01_master_standalone_icp4d.sh &

EOF

    destination = "/tmp/installation.sh"

  }
  
}


###########################################################################################################################################################
# ICP IDM
#
resource "aws_instance" "icpidm" {
  count="${ 2 * local.idm_install }"
  tags { Name = "${var.vm_name_prefix}-icpidm-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-icpidm-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "m4.2xlarge"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
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
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'"
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
# HAProxyVIP
#
# This VM is created for the sole purpose of obtaining a VIP.
# It is immediately shut down after created.
# It's create with the smallest instance type and should not be destroyed so as to keep the IP allocated and never reused, for as long as this cluster is in use.
#
# Update: This approach does not work on AWS. You can't re-use the IP address of an instance as VIP for other instances.
# Setting count to 0.
#
resource "aws_instance" "icphaproxyvip" {
  count         = "0"
  tags { Name = "${var.vm_name_prefix}-icphaproxyvip.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-icphaproxyvip", Owner = "${var.aws_owner}", Obs = "Make sure to keep this VM down. Don't destroy it until the entire cluster is removed. Its only purpose is get an IP allocated for ICP4D HAProxy purposes."  }
  instance_type = "t3.nano"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, 0)}"
  subnet_id     = "${element(var.subnet_ids, 0)}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "20", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }
   
 provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'halt -p'"
    ]
 }
  
}

###########################################################################################################################################################
# HAProxy
#
resource "aws_instance" "icphaproxy" {
  count         = "1"
  tags { Name = "${var.vm_name_prefix}-icphaproxy-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-icphaproxy-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "m4.2xlarge"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
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
      "sudo su - -c 'echo \"${var.vm_name_prefix}-icphaproxy-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
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
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'"
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
  count         = "3"
  tags { Name = "${var.vm_name_prefix}-icpmaster-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-icpmaster-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "${var.instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "300", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "1000", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "io1", "volume_size" = "1000", "delete_on_termination" = true iops="${var.ebs_vol_iops}" }
  ebs_block_device = { "device_name" = "/dev/sdd", "volume_type" = "io1", "volume_size" = "1000", "delete_on_termination" = true iops="${var.ebs_vol_iops}" }
  ebs_block_device = { "device_name" = "/dev/sde", "volume_type" = "io1", "volume_size" = "1000", "delete_on_termination" = true iops="${var.ebs_vol_iops}" }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }
 
   provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-icpmaster-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
