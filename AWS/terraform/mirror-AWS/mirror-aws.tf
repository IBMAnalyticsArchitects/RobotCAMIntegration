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

data "aws_subnet" "selected" {
  state      = "available"
  vpc_id     = "${data.aws_vpc.selected.id}"
  cidr_block = "${var.subnet_cidr}"
}


variable "security_group_ids" {
  type = "list"
  description = "security_group_ids"
}

variable "public_ssh_key_name" {
  description = "Name of the public SSH key used to connect to the virtual guest"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guest"
}

#Variable : AWS image name
variable "aws_image" {
  type = "string"
  description = "Operating system image id / template that should be used when creating the virtual image"
  default = "ami-c998b6b2"
}

variable "ibm_cos_access_key_id" {
  description = "IBM Cloud COS Access Key Id"
}

variable "ibm_cos_secret_access_key" {
  description = " Secret AccesIBM Cloud COS s Key"
}

variable "ibm_cos_endpoint_url" {
  description = "IBM Cloud COS Endpoint URL"
}

variable "ibm_cos_source_mirror_path_list" {
  description = "IBM Cloud COS  Source Mirror Path (points to a tar file containing the product distributions, open source components and EPEL and RHEL 7 mirrors)."
  type="list"
}

variable "ibm_cos_source_cloud_install_path" {
  description = "IBM Cloud COS Source Cloud Installer Path (points to a tar file containing the Cloud Install scripts)."
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


variable "instance_type" {
  description = "instance_type"
}


variable "mirror_volume_size" {
  description = "Size of /var/www/html volume"
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
# Mirror
#
resource "aws_instance" "mirror" {
  count         = "1"
  tags { Name = "${var.vm_name_prefix}-mirror.${var.vm_domain}", Owner = "${var.aws_owner}" }
  instance_type = "${var.instance_type}"
  ami           = "${var.aws_image}"
  subnet_id     = "${data.aws_subnet.selected.id}"
  vpc_security_group_ids = "${var.security_group_ids}"
  key_name      = "${aws_key_pair.temp_public_key.id}"
  root_block_device = { "volume_type" = "gp2", "volume_size" = "100", "delete_on_termination" = true }
  ebs_block_device = { "device_name" = "/dev/sdb", "volume_type" = "st1", "volume_size" = "${var.mirror_volume_size}", "delete_on_termination" = true, "encrypted" = false }
  ebs_block_device = { "device_name" = "/dev/sdc", "volume_type" = "st1", "volume_size" = "500", "delete_on_termination" = true, "encrypted" = true }
  ebs_block_device = { "device_name" = "/dev/sdd", "volume_type" = "st1", "volume_size" = "${var.mirror_volume_size}", "delete_on_termination" = true, "encrypted" = false }
  
  connection {
    user        = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.private_ip}"
  }
  
   provisioner "file" {
    content = <<EOF
#!/bin/bash
LOGFILE="/var/log/addkey.log"
p_user_public_key=$1
if [ "$p_user_public_key" != "None" ] ; then
    echo "---start adding user_public_key----" | tee -a $LOGFILE 2>&1
    echo "$p_user_public_key" | tee -a $HOME/.ssh/authorized_keys          >> $LOGFILE 2>&1 || { echo "---Failed to add user_public_key---" | tee -a $LOGFILE; exit 1; }
    echo "---finish adding user_public_key----" | tee -a $LOGFILE 2>&1
fi
EOF

    destination = "/tmp/addkey.sh"
}

  provisioner "remote-exec" {
    inline = [
      "echo \"${var.vm_name_prefix}-mirror.${var.vm_domain}\">/tmp/hostname",
      "sudo mv /tmp/hostname /etc/hostname",
      "sudo hostname \"${var.vm_name_prefix}-mirror.${var.vm_domain}\"",
      "sudo chmod +x /tmp/addkey.sh; sudo bash /tmp/addkey.sh \"${var.public_ssh_key}\"",
      "sudo su - -c 'systemctl restart sshd'",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-optional'",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-rhscl'",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-extras'",
      "sudo su - -c 'yum-config-manager --enable rhui-REGION-rhel-server-supplementary'"
    ]
 }

  provisioner "file" {
  
    content = <<EOF
#!/bin/bash

set -x

. /opt/monkey_cam_vars.txt

yum install python rsync unzip ksh perl  wget expect createrepo -y
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws


# Create /root/.aws/credentials
mkdir -p ~/.aws
cat<<END>>~/.aws/credentials
[default]
aws_access_key_id = $cam_ibm_cos_access_key_id
aws_secret_access_key = $cam_ibm_cos_secret_access_key
END

devname=/dev/xvdb
partname=/dev/xvdb1
parted -s $devname mklabel gpt
sleep 5
parted -s -a optimal $devname mkpart primary 0% 100%
sleep 5
mkfs.xfs $partname
sleep 5
mkdir -p /var/www/html
echo "$partname /var/www/html xfs defaults 1 1" >> /etc/fstab
mount -a

devname=/dev/xvdd
partname=/dev/xvdd1
parted -s $devname mklabel gpt
sleep 5
parted -s -a optimal $devname mkpart primary 0% 100%
sleep 5
mkfs.xfs $partname
sleep 5
mkdir -p /landing
echo "$partname /landing xfs defaults 1 1" >> /etc/fstab
mount -a 


for f in `echo $cam_ibm_cos_source_mirror_path_list | sed 's/[,;]/ /g'`
do
  echo "Downloading $f ..."  
	aws --endpoint-url=$cam_ibm_cos_endpoint_url s3 cp $f /landing
done

cd /var/www/html
for f in /landing/*.tar
do
  echo "Expanding $f ..."
	tar xf $f
done 


# Also download cloud_installer from IBM Cloud COS into /var/www/html/cloud_install
mkdir -p /var/www/html/cloud_install
aws --endpoint-url=$cam_ibm_cos_endpoint_url s3 cp $cam_ibm_cos_source_cloud_install_path /var/www/html/cloud_install


# Set up /opt/cloud_install
mkdir -p /opt/cloud_install
cd /opt/cloud_install
tar xf /var/www/html/cloud_install/`basename $cam_ibm_cos_source_cloud_install_path`

# Set up /repo/sync folder
mkdir -p /repo/sync/
cp rpm_repo_files/02_epel_sync.sh /repo/sync/
chmod 755 /repo/sync/02_epel_sync.sh

## Sync EPEL
#cd /repo/sync
#./02_epel_sync.sh

# Install HTTP server

yum -y install httpd firewalld

systemctl stop firewalld
systemctl disable firewalld

#systemctl unmask firewalld
#firewall-cmd --add-port=80/tcp
#firewall-cmd --permanent --add-port=80/tcp
#firewall-cmd --add-port=443/tcp
#firewall-cmd --permanent --add-port=443/tcp
#firewall-cmd --add-port=5000/tcp
#firewall-cmd --permanent --add-port=5000/tcp
#firewall-cmd --reload
#systemctl start firewalld
#systemctl enable firewalld


# Disable SELinux
#cat /etc/selinux/config|grep -v "^SELINUX=">/tmp/__selinuxConfig
#echo "SELINUX=disabled">>/tmp/__selinuxConfig
#mv -f /tmp/__selinuxConfig /etc/selinux/config
#setenforce 0

yum install -y policycoreutils-python
semanage fcontext -a -t httpd_sys_content_t "/var/www/html(/.*)?"
restorecon -Rv /var/www/html

systemctl start httpd
systemctl enable httpd

yum install -y docker
cat<<END>/etc/sysconfig/docker-storage-setup
DEVS=/dev/xvdc
VG=docker-vg
END
docker-storage-setup
sleep 5
systemctl enable docker
systemctl start docker

docker load -i /var/www/html/software/docker-registry.tar
cat<<END>/etc/containers/registries.conf
[registries.insecure]
registries = ["${self.private_ip}:5000"]
END
systemctl restart docker
sleep 5
docker run -v /data -d -p 5000:5000 --restart=always --name registry registry:2
sleep 5
docker ps -a
sleep 5
# Test registry
docker images
docker tag docker.io/busybox  ${self.private_ip}:5000/busybox
docker push ${self.private_ip}:5000/busybox

# Load images into the registry
cd /opt/cloud_install
cp4d_files/02_load_tag_push.sh /var/www/html/product_distr/CP4D2.5/ose-images/  ${self.private_ip}:5000

systemctl stop docker

echo "Mirror setup complete. Rebooting..."

reboot
EOF

    destination = "/tmp/installation.sh"
  }

}


resource "null_resource" "start_install" {

  depends_on = [ 
  	"aws_instance.mirror"
  ]
  

  connection {
    host     = "${aws_instance.mirror.private_ip}"
    type     = "ssh"
    user     = "ec2-user"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - -c 'echo  export cam_ibm_cos_access_key_id=${var.ibm_cos_access_key_id} >> /opt/monkey_cam_vars.txt'",
      "sudo su - -c 'echo  export cam_ibm_cos_secret_access_key=${var.ibm_cos_secret_access_key} >> /opt/monkey_cam_vars.txt'",
      "sudo su - -c 'echo  export cam_ibm_cos_endpoint_url=${var.ibm_cos_endpoint_url} >> /opt/monkey_cam_vars.txt'",
      "sudo su - -c 'echo  export cam_ibm_cos_source_mirror_path_list=${join(",",var.ibm_cos_source_mirror_path_list)} >> /opt/monkey_cam_vars.txt'",
      "sudo su - -c 'echo  export cam_ibm_cos_source_cloud_install_path=${var.ibm_cos_source_cloud_install_path} >> /opt/monkey_cam_vars.txt'",
      
      "sudo su - -c 'chmod 755 /opt/monkey_cam_vars.txt'",
      "sudo su - -c 'mv /tmp/installation.sh /opt/installation.sh'",
      "sudo su - -c 'chmod 755 /opt/installation.sh'",
      "sudo su - -c 'nohup /opt/installation.sh &'",
      "sleep 60"
    ]
  }
}
