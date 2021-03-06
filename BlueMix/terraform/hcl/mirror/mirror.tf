#################################################################
# Terraform template that will deploy an VM with Cloud Install Mirror only
#
# This works with a private network-only VM.
#
# Julius Lerm, 8apr2018, 9:49pm
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

variable "hostname" {
  description = "Hostname of the virtual instance to be deployed"
}

variable "vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guest"
}

variable "ibm_cos_access_key_id" {
  description = "AWS Access Key Id"
}

variable "ibm_cos_secret_access_key" {
  description = "AWS Secret Access Key"
}

variable "ibm_cos_endpoint_url" {
  description = "AWS Endpoint URL"
}

variable "ibm_cos_source_mirror_path_list" {
  description = "AWS Source Mirror Path List (list of tar files containing the product distributions, open source components and EPEL and RHEL 7 mirrors)."
  type="list"
}

variable "ibm_cos_source_cloud_install_path" {
  description = "AWS Source Cloud Installer Path (points to a tar file containing the Cloud Install scripts)."
}

variable "vlan_number" {
  description = "VLAN Number"
}

variable "vlan_router" {
  description = "VLAN router"
}

variable "sudo_user" {
  description = "Sudo User"
}

variable "sudo_password" {
  description = "Sudo Password"
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
# Create Virtual Machine and install Cloud Install Mirror
##############################################################
resource "ibm_compute_vm_instance" "softlayer_virtual_guest" {
  count                    = "1"
  hostname                 = "${var.hostname}"
  os_reference_code        = "REDHAT_7_64"
  domain                   = "${var.vm_domain}"
  datacenter               = "${var.datacenter}"
  private_vlan_id          = "${data.ibm_network_vlan.cluster_vlan.id}"
  network_speed            = 1000
  hourly_billing           = true
  private_network_only     = true
  cores                    = 8
  memory                   = 8192
  wait_time_minutes        = 200
  disks                    = [100,2000,1000,2000]
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address_private}"
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i -e 's/# %wheel/%wheel/' -e 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers",
      "useradd ${var.sudo_user}",
      "echo ${var.sudo_password} | passwd ${var.sudo_user} --stdin",
      "usermod ${var.sudo_user} -g wheel"
    ]
  }
  
  provisioner "file" {
    source      = "awscli-bundle.zip"
    destination = "/tmp/awscli-bundle.zip"
  }

   
  provisioner "file" {
  
    content = <<EOF
#!/bin/bash

set -x

. /opt/monkey_cam_vars.txt


wait_yum() {
  while true
  do
        echo "wait_yum():..."
        yum repolist
        if [ `yum repolist 2>&1 | egrep "repolist: 0|There are no enabled repos|This system is not registered" | wc -l` -ne 0 ]
        then
                echo "Wating for yum repo (wait 5s)..."
                sleep 5
        else
                break
        fi
  done
}


wait_yum
yum install python rsync unzip ksh perl  wget expect httpd firewalld createrepo -y

#curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
#unzip awscli-bundle.zip
unzip /tmp/awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws


# Create /root/.aws/credentials
mkdir -p ~/.aws
cat<<END>>~/.aws/credentials
[default]
aws_access_key_id = $cam_ibm_cos_access_key_id
aws_secret_access_key = $cam_ibm_cos_secret_access_key
END

devname=/dev/xvdc
partname=/dev/xvdc1
parted -s $devname mklabel gpt
sleep 5
parted -s -a optimal $devname mkpart primary 0% 100%
sleep 5
mkfs.xfs $partname
sleep 5
mkdir -p /var/www/html
echo "$partname /var/www/html xfs defaults 1 1" >> /etc/fstab
mount -a 


devname=/dev/xvdf
partname=/dev/xvdf1
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

# Also download cloud_installer from AWS into /var/www/html/cloud_install
mkdir -p /var/www/html/cloud_install
aws --endpoint-url=$cam_ibm_cos_endpoint_url s3 cp $cam_ibm_cos_source_cloud_install_path /var/www/html/cloud_install

mkdir -p /opt/cloud_install
cd /opt/cloud_install
tar xf /var/www/html/cloud_install/`basename $cam_ibm_cos_source_cloud_install_path`

# Install HTTP server

#sudo yum -y install httpd
#sudo firewall-cmd --permanent --add-port=80/tcp
#sudo firewall-cmd --permanent --add-port=443/tcp
#sudo firewall-cmd --add-port=80/tcp
#sudo firewall-cmd --add-port=443/tcp
#sudo firewall-cmd --permanent --add-port=5000/
#sudo firewall-cmd --add-port=5000/tcp
#sudo firewall-cmd --reload


## Disable SELinux
#cat /etc/selinux/config|grep -v "^SELINUX=">/tmp/__selinuxConfig
#echo "SELINUX=disabled">>/tmp/__selinuxConfig
#mv -f /tmp/__selinuxConfig /etc/selinux/config
#setenforce 0

wait_yum
yum install -y policycoreutils-python
semanage fcontext -a -t httpd_sys_content_t "/var/www/html(/.*)?"
restorecon -Rv /var/www/html

sudo systemctl start httpd
sudo systemctl enable httpd

subscription-manager repos --enable=rhel-7-server-extras-rpms

# Install docker and set up image registry

wait_yum
yum install -y docker
cat<<END>/etc/sysconfig/docker-storage-setup
DEVS=/dev/xvde
VG=docker-vg
END
docker-storage-setup
sleep 5
systemctl enable docker
systemctl start docker

docker load -i /var/www/html/software/docker-registry.tar
cat<<END>/etc/containers/registries.conf
[registries.insecure]
registries = ["${self.ipv4_address_private}:5000"]
END
systemctl restart docker
sleep 5
docker run -v /data -d -p 5000:5000 --restart=always --name registry registry:2
sleep 5
docker ps -a
sleep 5
# Test registry
docker images
docker tag docker.io/busybox  ${self.ipv4_address_private}:5000/busybox
docker push ${self.ipv4_address_private}:5000/busybox

# Load images into the registry
cd /opt/cloud_install
cp4d_files/02_load_tag_push.sh /var/www/html/product_distr/CP4D2.5/ose-images/  ${self.ipv4_address_private}:5000


systemctl stop docker

echo "Mirror setup complete. Rebooting..."

reboot
EOF

    destination = "/opt/installation.sh"
  }

}

#########################################################
# Output
#########################################################
#output "The IP address of the VM with Mirror installed" {
#  value = "join(",",ibm_compute_vm_instance.softlayer_virtual_guest.ipv4_address_private)}"
#}


resource "null_resource" "start_install" {

  depends_on = [ 
  	"ibm_compute_vm_instance.softlayer_virtual_guest"
  ]

  connection {
    host     = "${ibm_compute_vm_instance.softlayer_virtual_guest.0.ipv4_address_private}"
    type     = "ssh"
    user     = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }

  provisioner "remote-exec" {
    
   inline = [
      "echo  export cam_ibm_cos_access_key_id=${var.ibm_cos_access_key_id} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ibm_cos_secret_access_key=${var.ibm_cos_secret_access_key} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ibm_cos_endpoint_url=${var.ibm_cos_endpoint_url} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ibm_cos_source_mirror_path_list=${join(",",var.ibm_cos_source_mirror_path_list)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ibm_cos_source_cloud_install_path=${var.ibm_cos_source_cloud_install_path} >> /opt/monkey_cam_vars.txt",
            
      "chmod 755 /opt/monkey_cam_vars.txt",
      "chmod 755 /opt/installation.sh",
      "nohup /opt/installation.sh &",
      "sleep 60"
    ]


  }
}


# ${join(",",var.cp4d_addons)}