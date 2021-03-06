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

variable "driver_ip" {
  description = "IP Address of Driver VM for existing CP4D cluster"
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
# Security Groups
##############################################################

resource "ibm_security_group" "pubsg1" {
    name = "${var.vm_name_prefix}-pubsg1"
    description = "All external traffic"
}

resource "ibm_security_group_rule" "allow_port_443" {
    direction = "ingress"
    ether_type = "IPv4"
    port_range_min = "443"
    port_range_max = "443"
    protocol = "tcp"
    security_group_id = "${ibm_security_group.pubsg1.id}"
}


resource "ibm_security_group_rule" "allow_port_8443" {
    direction = "ingress"
    ether_type = "IPv4"
    port_range_min = "8443"
    port_range_max = "8443"
    protocol = "tcp"
    security_group_id = "${ibm_security_group.pubsg1.id}"
}


##############################################################
# Create VMs
##############################################################

###########################################################################################################################################################
# Public HAProxy
resource "ibm_compute_vm_instance" "pubhaproxy" {
  count                    = "1"
  hostname                 = "${var.vm_name_prefix}-pubhaproxy"
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
  public_security_group_ids = [ "${ibm_security_group.pubsg1.id}" ]

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
yum install expect -y

#passphrase=`cat /root/passphrase.fifo`
passphrase=`cat /root/passphrase`

eval `ssh-agent`
/opt/addSshKeyId.exp $passphrase

set -x 

wait_yum
yum install python rsync unzip ksh perl  wget httpd firewalld createrepo -y

wait_yum
yum groupinstall "Infrastructure Server" -y

mkdir -p /opt/cloud_install; 

cd /opt/cloud_install;

. /opt/monkey_cam_vars.txt;

wget http://$cam_monkeymirror/cloud_install/$cloud_install_tar_file_name

tar xf ./$cloud_install_tar_file_name

echo "Disable root login w/ password"
passwd -l root

cd /opt/cloud_install

ssh $cam_driver_ip "cd /opt/cloud_install;. ./setenv;env|egrep '^cloud_'">global.properties
. ./setenv

scp $cam_driver_ip:/etc/hosts /etc/hosts

wait_yum
/opt/cloud_install/rpm_repo_files/03_install_rpms.sh $MASTER_INSTALLER_HOME/haproxy_files/RPM_LIST-haproxy.txt /tmp/03_install_rpms-haproxy.log

systemctl enable haproxy.service
cp -p /etc/rsyslog.conf /etc/rsyslog.conf.bkup
cat /etc/rsyslog.conf | perl -f /opt/cloud_install/haproxy_files/03_update_rsyslog.pl > /etc/rsyslog.conf.new
mv -f /etc/rsyslog.conf.new /etc/rsyslog.conf
cat > /etc/rsyslog.d/haproxy.conf <<END
local2.*        /var/log/haproxy/haproxy.log
END

systemctl stop rsyslog.service
systemctl start rsyslog.service
/opt/cloud_install/cp4d_files/haproxy/02_configure_cp4d_haproxy.sh base;
/opt/cloud_install/cp4d_files/haproxy/02_configure_cp4d_haproxy.sh icp;

systemctl restart haproxy

echo "Wait 30s before checking ports..."
sleep 30

netstat -an | grep LISTEN | grep tcp

echo "Public HAProxy setup complete."

EOF

    destination = "/opt/installation.sh"

  }
}



############################################################################################################################################################
# Start Install
resource "null_resource" "start_install" {

  depends_on = [ 
  	"ibm_compute_vm_instance.pubhaproxy"
  ]
  
  connection {
    host     = "${ibm_compute_vm_instance.pubhaproxy.0.ipv4_address_private}"
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
      "echo  export cam_driver_ip=${var.driver_ip} >> /opt/monkey_cam_vars.txt",
   
      "echo  export cam_icp_public_haproxy_ip=${join(",",ibm_compute_vm_instance.pubhaproxy.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_public_haproxy_name=${join(",",ibm_compute_vm_instance.pubhaproxy.*.hostname)} >> /opt/monkey_cam_vars.txt",

       "echo ${var.ssh_key_passphrase} > /root/passphrase ",
       "chmod 600 /root/passphrase",

      "chmod 755 /opt/installation.sh",
      "nohup /opt/installation.sh &",
      "sleep 60"
    ]
  }
}
