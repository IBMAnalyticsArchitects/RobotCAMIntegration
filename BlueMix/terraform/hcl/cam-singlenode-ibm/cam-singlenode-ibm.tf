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
variable "icp_num_cpus" {
  description = "Number of CPUs for ICP Master and Worker nodes"
  default = "16"
}

variable "icp_mem" {
  description = "Memory (MBs) for ICP Master and Worker nodes"
  default = "98384"
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
  wait_time_minutes        = 200
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

  provisioner "remote-exec" {
    inline = [
      "sed -i -e 's/# %wheel/%wheel/' -e 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers",
      "useradd ${var.sudo_user}",
      "echo ${var.sudo_password} | passwd ${var.sudo_user} --stdin",
      "usermod ${var.sudo_user} -g wheel"
    ]
  }

  provisioner "file" {
    content = <<EOF
#!/bin/sh

set -x 

mkdir -p /opt/cloud_install; 

cd /opt/cloud_install;

. /opt/monkey_cam_vars.txt;

wget http://$cam_monkeymirror/cloud_install/$cloud_install_tar_file_name

tar xf ./$cloud_install_tar_file_name

yum install -y ksh rsync expect unzip perl

perl -f cam_integration/01_gen_cam_install_properties.pl

sed -i 's/cloud_replace_rhel_repo=1/cloud_replace_rhel_repo=0/' global.properties
#sed -i 's/cloud_biginsights_bigsql_/#cloud_biginsights_bigsql_/' global.properties
#sed -i 's/cloud_skip_prepare_nodes=0/cloud_skip_prepare_nodes=1/' global.properties

. ./setenv

utils/01_prepare_driver.sh

softlayer/01_setup_softlayer_vms.sh /dev/xvdc

utils/01_prepare_all_nodes.sh

nohup icp_files/01_icp_cam.sh &
#nohup icp_files/01_master_icp.sh &

EOF

    destination = "/opt/installation.sh"

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
  disks                    = [100,1000,1000,1000]
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
      "sed -i -e 's/# %wheel/%wheel/' -e 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers",
      "useradd ${var.sudo_user}",
      "echo ${var.sudo_password} | passwd ${var.sudo_user} --stdin",
      "usermod ${var.sudo_user} -g wheel",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
  
 provisioner "file" {
    content = <<EOF
var=200
tmp=100
opt=200
home=100
ibm=300
EOF
    destination = "/tmp/filesystemLayout.txt"
}

}





############################################################################################################################################################
# Start Install
resource "null_resource" "start_install" {

  depends_on = [ 
  	"ibm_compute_vm_instance.driver",  
  	"ibm_compute_vm_instance.icpmaster"
  ]
  
  connection {
    host     = "${ibm_compute_vm_instance.driver.0.ipv4_address_private}"
    type     = "ssh"
    user     = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }

  provisioner "remote-exec" {
    inline = [
    
      "echo  export cam_sudo_user=${var.sudo_user} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_sudo_password=${var.sudo_password} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_vm_domain=${var.vm_domain} >> /opt/monkey_cam_vars.txt",  
      "echo  export cam_vm_dns_servers=${join(",",var.vm_dns_servers)} >> /opt/monkey_cam_vars.txt",     

      "echo  export cam_time_server=${var.time_server} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_cluster_name=${var.cluster_name} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_public_nic_name=${var.public_nic_name} >> /opt/monkey_cam_vars.txt",
      "echo  export cloud_install_tar_file_name=${var.cloud_install_tar_file_name} >> /opt/monkey_cam_vars.txt",
      
      # Hardcode the list of data devices here...
      # It must be updated if the data node template is modified.
      # This list must match the naming format, for the data node template definition.
      
      # For the SL VMs used so far, /dev/xvdb is defined as swap. Removing it for now...
      "echo  export cam_icp_nfs_data_devices=/disk2@/dev/xvde >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_docker_device=/dev/xvdf >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_monkeymirror=${var.monkey_mirror} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_driver_ip=${join(",",ibm_compute_vm_instance.icpmaster.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_driver_name=${join(",",ibm_compute_vm_instance.icpmaster.*.hostname)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_icpboot_ip=${join(",",ibm_compute_vm_instance.icpmaster.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpboot_name=${join(",",ibm_compute_vm_instance.icpmaster.*.hostname)} >> /opt/monkey_cam_vars.txt",    
      
      "echo  export cam_icpmasters_ip=${join(",",ibm_compute_vm_instance.icpmaster.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpmasters_name=${join(",",ibm_compute_vm_instance.icpmaster.*.hostname)} >> /opt/monkey_cam_vars.txt",    
      
      "echo  export cam_icpworkers_ip=${join(",",ibm_compute_vm_instance.icpmaster.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpworkers_name=${join(",",ibm_compute_vm_instance.icpmaster.*.hostname)} >> /opt/monkey_cam_vars.txt", 
      
      "echo  export cam_icpproxies_ip=${join(",",ibm_compute_vm_instance.icpmaster.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpproxies_name=${join(",",ibm_compute_vm_instance.icpmaster.*.hostname)} >> /opt/monkey_cam_vars.txt", 
      
      "echo  export cam_icpnfs_ip=${join(",",ibm_compute_vm_instance.icpmaster.*.ipv4_address_private)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpnfs_name=${join(",",ibm_compute_vm_instance.icpmaster.*.hostname)} >> /opt/monkey_cam_vars.txt",

      "echo  export cam_icp_network_cidr=${var.icp_network_cidr} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_service_cluster_ip_range=${var.icp_service_cluster_ip_range} >> /opt/monkey_cam_vars.txt",
    
      "chmod 755 /opt/installation.sh",
      "nohup /opt/installation.sh &",
      "sleep 60"
    ]
  }
}
