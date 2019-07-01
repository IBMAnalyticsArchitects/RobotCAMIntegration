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

variable "vpc_name_tag" {
  description = "Name of the Virtual Private Cloud (VPC) this resource is going to be deployed into"
}

variable "subnet_cidr" {
  description = "Subnet cidr"
}

data "aws_vpc" "selected" {
  state = "available"

  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name_tag}"]
  }
}


variable "vm_ipv4_prefix_length" {
  description = "CIDR prefix for VM subnets"
}

#data "aws_subnet" "selected" {
#  state      = "available"
#  vpc_id     = "${data.aws_vpc.selected.id}"
#  cidr_block = "${var.subnet_cidr}"
#}

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


#Variable : AWS image name
variable "aws_image" {
  type = "string"
  description = "Operating system image id / template that should be used when creating the virtual image"
  default = "ami-c998b6b2"
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

variable "mgmtnode_instance_type" {
  description = "mgmtnode_instance_type"
}

variable "mgmtnode_data_disk_size" {
  description = "mgmtnode_data_disk_size"
}

    
variable "datanode_instance_type" {
  description = "datanode_instance_type"
}

variable "datanode_data_disk_size" {
  description = "datanode_data_disk_size"
}

variable "edgenode_instance_type" {
  description = "edgenode_instance_type"
}

variable "num_datanodes" {
  description = "num_datanodes"
}

variable "num_edgenodes" {
  description = "Number of HDP edge nodes to create"
}

variable "bigsql_head_instance_type" {
  description = "bigsql_head_instance_type"
}

variable "idm_instance_type" {
  description = "idm_instance_type"
}

variable "haproxy_instance_type" {
  description = "haproxy_instance_type"
}

variable "ishttp_instance_type" {
  description = "ishttp_instance_type"
}

variable "iswas_instance_type" {
  description = "iswas_instance_type"
}

variable "isdb2_instance_type" {
  description = "isdb2_instance_type"
}

variable "isds_instance_type" {
  description = "isds_instance_type"
}

variable "ises_instance_type" {
  description = "isds_instance_type"
}


variable "ises_weave_net_ip_range" {
  description = "ises_weave_net_ip_range"
}

variable "ises_service_ip_range" {
  description = "ises_service_ip_range"
}

variable "install_infoserver" {
  description = "install_infoserver"
}

variable "install_bigsql" {
  description = "install_bigsql"
}


variable "availability_zones" {
  type = "list"
  description = "availability_zones"
}

variable "subnet_ids" {
  type = "list"
  description = "subnet_ids"
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
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  ami           = "${var.aws_image}"
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

set -x

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
#sed -i 's/cloud_biginsights_bigsql_/#cloud_biginsights_bigsql_/' global.properties
#sed -i 's/cloud_skip_prepare_nodes=0/cloud_skip_prepare_nodes=1/' global.properties
echo "cloud_enable_yum_versionlock=0">>global.properties

. ./setenv

echo "Encrypt and remove global.properties"
$MASTER_INSTALLER_HOME/utils/01_encrypt_global_properties.sh global.properties
rm -f ./global.properties

utils/01_prepare_driver.sh

aws_files/01_setup_ec2_instances.sh

utils/01_prepare_all_nodes.sh

nohup ./01_master_install_hdp.sh &

EOF

    destination = "/tmp/installation.sh"

  }
  
}

###########################################################################################################################################################
# IDM
#
resource "aws_instance" "idm" {
  count         = "2"
  tags { Name = "${var.vm_name_prefix}-idm-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-idm-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "${var.idm_instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
#  subnet_id     = "${data.aws_subnet.selected.id}"
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
      "sudo su - -c 'echo \"${var.vm_name_prefix}-idm-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-idm-${ count.index }.${var.vm_domain}\"",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo mv /data /data.bkp"
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
# IS HTTP Front End
#
resource "aws_instance" "ishttp" {
  count         = "${ 1 * var.install_infoserver}"
  tags { Name = "${var.vm_name_prefix}-ishttp-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-ishttp-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "${var.ishttp_instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "500", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }
  

  provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-ishttp-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-ishttp-${ count.index }.${var.vm_domain}\"",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo mv /data /data.bkp"
    ]
 }
 
 provisioner "file" {
    content = <<EOF
var=100
tmp=100
opt=100
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}




###########################################################################################################################################################
# IS WAS-ND
#
resource "aws_instance" "iswasnd" {
  count         = "${ 2 * var.install_infoserver}"
  tags { Name = "${var.vm_name_prefix}-iswasnd-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-iswasnd-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "${var.iswas_instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "500", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-iswasnd-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-iswasnd-${ count.index }.${var.vm_domain}\"",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo mv /data /data.bkp"
    ]
 }

 provisioner "file" {
    content = <<EOF
var=100
tmp=100
opt=100
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}
  
}



###########################################################################################################################################################
# IS HTTP DB2
#
resource "aws_instance" "isdb2" {
  count         = "${ 1 * var.install_infoserver }"
  tags { Name = "${var.vm_name_prefix}-isdb2-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-isdb2-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "${var.isdb2_instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "500", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-isdb2-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-isdb2-${ count.index }.${var.vm_domain}\"",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo mv /data /data.bkp"
    ]
 }
 
 provisioner "file" {
    content = <<EOF
var=100
tmp=100
opt=100
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}
  
}






###########################################################################################################################################################
# IS DS
#
resource "aws_instance" "isds" {
  count         = "${ 1 * var.install_infoserver }"
  tags { Name = "${var.vm_name_prefix}-isds.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-isds", Owner = "${var.aws_owner}" }
  instance_type = "${var.isds_instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "500", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-isds.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-idm.${var.vm_domain}\"",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo mv /data /data.bkp"
    ]
 }
 
 provisioner "file" {
    content = <<EOF
var=100
tmp=100
opt=100
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}
  
}

###########################################################################################################################################################
# IS ES
#
resource "aws_instance" "ises" {
  count         = "${ 1 * var.install_infoserver }"
  tags { Name = "${var.vm_name_prefix}-ises.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-ises", Owner = "${var.aws_owner}" }
  instance_type = "${var.ises_instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "1500", "delete_on_termination" = true }
#  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "st1", "volume_size" = "1000", "delete_on_termination" = true }
#  ebs_block_device = { "device_name" = "/dev/sdd", "volume_type" = "st1", "volume_size" = "1000", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-ises.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-ises.${var.vm_domain}\"",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo mv /data /data.bkp"
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




###########################################################################################################################################################
# HAProxy
#
resource "aws_instance" "haproxy" {
  count         = "1"
  tags { Name = "${var.vm_name_prefix}-haproxy.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-haproxy", Owner = "${var.aws_owner}" }
  instance_type = "${var.haproxy_instance_type}"
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
      "sudo su - -c 'echo \"${var.vm_name_prefix}-haproxy.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-haproxy.${var.vm_domain}\"",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo mv /data /data.bkp"
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
# HDP Management Nodes
#
resource "aws_instance" "hdp-mgmtnodes" {
  count         = "4"
  tags { Name = "${var.vm_name_prefix}-mn-${ count.index }.${var.vm_domain}",ShortName = "${var.vm_name_prefix}-mn-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "${var.mgmtnode_instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }  
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "500", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "st1", "volume_size" = "${var.mgmtnode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdd", "volume_type" = "st1", "volume_size" = "${var.mgmtnode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sde", "volume_type" = "st1", "volume_size" = "${var.mgmtnode_data_disk_size}", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-mn-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-mn-${ count.index }.${var.vm_domain}\"",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo mv /data /data.bkp"
    ]
 }

   provisioner "file" {
    content = <<EOF
var=100
tmp=100
opt=100
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}




###########################################################################################################################################################
# HDP Data Nodes
#
resource "aws_instance" "hdp-datanodes" {
  count         = "${var.num_datanodes}"
  tags { Name = "${var.vm_name_prefix}-dn-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-dn-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "${var.datanode_instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }  
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "500", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdd", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sde", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdf", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdg", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdh", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdi", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdj", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdk", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdl", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdm", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdn", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-dn-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-dn-${ count.index }.${var.vm_domain}\"",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo mv /data /data.bkp"
    ]
 }

   provisioner "file" {
    content = <<EOF
var=100
tmp=100
opt=100
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}




###########################################################################################################################################################
# HDP Edge Nodes
#
resource "aws_instance" "hdp-edgenodes" {
  count         = "${var.num_edgenodes}"
  tags { Name = "${var.vm_name_prefix}-en-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-en-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "${var.edgenode_instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }  
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "500", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdd", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-en-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-en-${ count.index }.${var.vm_domain}\"",
      
      "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo mv /data /data.bkp"
    ]
 }

   provisioner "file" {
    content = <<EOF
var=100
tmp=100
opt=100
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}




###########################################################################################################################################################
# HDP BigSQL Head Node
#
resource "aws_instance" "hdp-bigsql" {
  count         = "${ 1 * var.install_bigsql }"
  tags { Name = "${var.vm_name_prefix}-bigsql-${ count.index }.${var.vm_domain}", ShortName = "${var.vm_name_prefix}-bigsql-${ count.index }", Owner = "${var.aws_owner}" }
  instance_type = "${var.bigsql_head_instance_type}"
  ami           = "${var.aws_image}"
  availability_zone = "${element(var.availability_zones, count.index )}"
  subnet_id     = "${element(var.subnet_ids, count.index )}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }  
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "gp2", "volume_size" = "500", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdd", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sde", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdf", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdg", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdh", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdi", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdj", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdk", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdl", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdm", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdn", "volume_type" = "st1", "volume_size" = "${var.datanode_data_disk_size}", "delete_on_termination" = true }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo \"${var.vm_name_prefix}-bigsql-${ count.index }.${var.vm_domain}\">/tmp/hostname'",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-bigsql-${ count.index }.${var.vm_domain}\"",
      
      "sudo mkdir -p /root/.ssh",
      "sudo chmod 700 /root/.ssh",
      "sudo su - -c 'echo ${var.public_ssh_key} > /root/.ssh/id_rsa.pub'",
      "sudo su - -c 'echo ${var.public_ssh_key} >> /root/.ssh/authorized_keys'",
      "sudo chmod 600 /root/.ssh/authorized_keys",
      "sudo su - -c 'echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa'",
      "sudo chmod 600 /root/.ssh/id_rsa",
      "sudo su - -c 'echo StrictHostKeyChecking no > /root/.ssh/config'",
      "sudo chmod 600 /root/.ssh/config",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo mv /data /data.bkp"
    ]
 }

   provisioner "file" {
    content = <<EOF
var=100
tmp=100
opt=100
home=100
EOF
    destination = "/tmp/filesystemLayout.txt"
}
  
}




############################################################################################################################################################
# Start Install
resource "null_resource" "start_install" {

  depends_on = [ 
  	"aws_instance.driver",  
  	"aws_instance.idm", 
  	"aws_instance.haproxy",  
  	"aws_instance.hdp-mgmtnodes",
  	"aws_instance.hdp-datanodes",
  	"aws_instance.hdp-edgenodes",
  	"aws_instance.hdp-bigsql",
  	"aws_instance.ishttp",
  	"aws_instance.iswasnd",
  	"aws_instance.isdb2",
  	"aws_instance.isds",
  	"aws_instance.ises"
  ]

  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${aws_instance.driver.*.private_ip}"
  }

  provisioner "remote-exec" {
    inline = [
    
#      "echo  export cam_sudo_user=${var.sudo_user} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_sudo_password=pwd12345 >> /tmp/monkey_cam_vars.txt",
      
      "echo  export cam_private_ips=${join(",",aws_instance.driver.*.private_ip)} >> /tmp/monkey_cam_vars.txt",

      "echo  export cam_vm_domain=${var.vm_domain} >> /tmp/monkey_cam_vars.txt",      
      "echo  export cam_vm_dns_servers=${join(",",var.vm_dns_servers)} >> /tmp/monkey_cam_vars.txt",

      "echo  export cam_time_server=${var.time_server} >> /tmp/monkey_cam_vars.txt",
     
      "echo  export cam_public_nic_name=${var.public_nic_name} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_cluster_name=${var.cluster_name} >> /tmp/monkey_cam_vars.txt",
      "echo  export cloud_install_tar_file_name=${var.cloud_install_tar_file_name} >> /tmp/monkey_cam_vars.txt",
      
      # Hardcode the list of data devices here...
      # It must be updated if the data node template is modified.
      # This list must match the naming format, for the data node template definition.
      
      # For the SL VMs used so far, /dev/xvdb is defined as swap. Removing it for now...
      "echo  export cam_cloud_biginsights_data_devices=/disk2@/dev/sdc,/disk3@/dev/sdd,/disk4@/dev/sde,/disk5@/dev/sdf,/disk6@/dev/sdg,/disk7@/dev/sdh,/disk8@/dev/sdi,/disk9@/dev/sdj,/disk10@/dev/sdk,/disk11@/dev/sdl,/disk12@/dev/sdm,/disk13@/dev/sdn,/disk14@/dev/sdo,/disk15@/dev/sdp,/disk16@/dev/sdq,/xvdisk2@/dev/xvdc,/xvdisk3@/dev/xvdd,/xvdisk4@/dev/xvde,/xvdisk5@/dev/xvdf,/xvdisk6@/dev/xvdg,/xvdisk7@/dev/xvdh,/xvdisk8@/dev/xvdi,/xvdisk9@/dev/xvdj,/xvdisk10@/dev/xvdk,/xvdisk11@/dev/xvdl,/xvdisk12@/dev/xvdm,/xvdisk13@/dev/xvdn,/xvdisk14@/dev/xvdo,/xvdisk15@/dev/xvdp,/xvdisk16@/dev/xvdq >> /tmp/monkey_cam_vars.txt",
      
      "echo  export cam_monkeymirror=${var.monkey_mirror} >> /tmp/monkey_cam_vars.txt",
    
      "echo  export cam_driver_ip=${join(",",aws_instance.driver.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_driver_name=${join(",",aws_instance.driver.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
    
      "echo  export cam_idm_ip=${join(",",aws_instance.idm.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_idm_name=${join(",",aws_instance.idm.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
    
    
      "echo  export cam_ishttp_ip=${join(",",aws_instance.ishttp.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_ishttp_name=${join(",",aws_instance.ishttp.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
    
      "echo  export cam_iswasnd_ip=${join(",",aws_instance.iswasnd.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_iswasnd_name=${join(",",aws_instance.iswasnd.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
    
      "echo  export cam_isdb2_ip=${join(",",aws_instance.isdb2.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_isdb2_name=${join(",",aws_instance.isdb2.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
    
      "echo  export cam_isds_ip=${join(",",aws_instance.isds.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_isds_name=${join(",",aws_instance.isds.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
      
      "echo  export cam_ises_ip=${join(",",aws_instance.ises.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_ises_name=${join(",",aws_instance.ises.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
#      "echo  export cam_ises_docker_device=/dev/xvdc >> /tmp/monkey_cam_vars.txt",
#      "echo  export cam_ises_ug_device=/dev/xvdc >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_ises_weave_net_ip_range=${var.ises_weave_net_ip_range} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_ises_service_ip_range=${var.ises_service_ip_range} >> /tmp/monkey_cam_vars.txt",
    
      "echo  export cam_haproxy_ip=${join(",",aws_instance.haproxy.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_haproxy_name=${join(",",aws_instance.haproxy.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
    
      "echo  export cam_hdp_mgmtnodes_ip=${join(",",aws_instance.hdp-mgmtnodes.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_hdp_mgmtnodes_name=${join(",",aws_instance.hdp-mgmtnodes.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
      
      "echo  export cam_hdp_datanodes_ip=${join(",",aws_instance.hdp-datanodes.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_hdp_datanodes_name=${join(",",aws_instance.hdp-datanodes.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
    
      "echo  export cam_hdp_edgenodes_ip=${join(",",aws_instance.hdp-edgenodes.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_hdp_edgenodes_name=${join(",",aws_instance.hdp-edgenodes.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
    
      "echo  export cam_bigsql_head_ip=${join(",",aws_instance.hdp-bigsql.*.private_ip)} >> /tmp/monkey_cam_vars.txt",
      "echo  export cam_bigsql_head_name=${join(",",aws_instance.hdp-bigsql.*.tags.ShortName)} >> /tmp/monkey_cam_vars.txt",
    
      "sudo mv /tmp/monkey_cam_vars.txt /opt/monkey_cam_vars.txt",
      "sudo mv /tmp/installation.sh /opt/installation.sh",
      "sudo chmod 700 /opt/installation.sh",
      
      "sudo mkfifo /root/passphrase.fifo",
      "sudo chmod 600 /root/passphrase.fifo",
      "sudo su - -c 'echo ${var.ssh_key_passphrase} > /root/passphrase.fifo &'",
      
      "sudo su -c 'cd;nohup /opt/installation.sh &'",
      "sleep 60"
    ]
  }
}
