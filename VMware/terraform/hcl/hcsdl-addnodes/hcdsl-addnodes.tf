
##############################################################
# Keys - CAMC (public/private) & optional User Key (public)
##############################################################
variable "allow_unverified_ssl" {
  description = "Communication with vsphere server with self signed certificate"
  default = "true"
}

##############################################################
# Define the vsphere provider
##############################################################
provider "vsphere" {
  allow_unverified_ssl = "${var.allow_unverified_ssl}"
  version = "~> 1.3" 
}

provider "camc" {
  version = "~> 0.1"
}

##############################################################
# Define pattern variables
##############################################################
##############################################################
# Vsphere data for provider
##############################################################
data "vsphere_datacenter" "vm_datacenter" {
  name = "${var.vm_datacenter}"
}
data "vsphere_datastore" "vm_datastore" {
  name = "${var.vm_root_disk_datastore}"
  datacenter_id = "${data.vsphere_datacenter.vm_datacenter.id}"
}
data "vsphere_resource_pool" "vm_resource_pool" {
  name = "${var.vm_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.vm_datacenter.id}"
}
data "vsphere_network" "vm_network" {
  name = "${var.vm_network_interface_label}"
  datacenter_id = "${data.vsphere_datacenter.vm_datacenter.id}"
}

data "vsphere_virtual_machine" "vm_template" {
  name = "${var.vm-image}"
  datacenter_id = "${data.vsphere_datacenter.vm_datacenter.id}"
}

##### Image Parameters variables #####

variable "vm_name_prefix" {
  description = "Prefix for vm names"
}


variable "node_label" {
  description = "Node label for compute VMs"
}




#########################################################
##### Resource : vm
#########################################################
variable "ssh_user" {
  description = "The user for ssh connection, which is default in template"
  default     = "root"
}

variable "ssh_user_password" {
  description = "The user password for ssh connection, which is default in template"
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



variable "monkey_mirror" {
  description = "Monkey Mirror IP or Hostname"
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


variable "vm_datacenter" {
  description = "Target vSphere datacenter for virtual machine creation"
}

variable "vm_domain" {
  description = "Domain Name of virtual machine"
}

variable "vm_number_of_vcpu" {
  description = "Number of virtual CPU for the virtual machine, which is required to be a positive Integer"
  default = "1"
}

variable "vm_memory" {
  description = "Memory assigned to the virtual machine in megabytes. This value is required to be an increment of 1024"
  default = "1024"
}


variable "vm_resource_pool" {
  description = "Target vSphere Resource Pool to host the virtual machine"
}

variable "vm_dns_servers" {
  type = "list"
  description = "DNS servers for the virtual network adapter"
}

variable "vm_network_interface_label" {
  description = "vSphere port group or network label for virtual machine's vNIC"
}

variable "vm_ipv4_gateway" {
  description = "IPv4 gateway for vNIC configuration"
}

variable "vm_start_ipv4_address" {
  description = "Start IPv4 address for vNIC configuration"
}

variable "vm_ipv4_prefix_length" {
  description = "IPv4 prefix length for vNIC configuration. The value must be a number between 8 and 32"
}

variable "vm_adapter_type" {
  description = "Network adapter type for vNIC Configuration"
  default = "vmxnet3"
}

variable "vm_root_disk_datastore" {
  description = "Data store or storage cluster name for target virtual machine's disks"
}

variable "vm_root_disk_type" {
  type = "string"
  description = "Type of template disk volume"
  default = "eager_zeroed"
}

variable "vm_root_disk_controller_type" {
  type = "string"
  description = "Type of template disk controller"
  default = "scsi"
}

variable "vm_root_disk_size" {
  description = "Size of template disk volume. Should be equal to template's disk size"
  default = "25"
}

variable "vm_datanode_disk_size" {
  description = "Datanode Data Disk Size"
  default = "100"
}


variable "vm-image" {
  description = "Operating system image id / template that should be used when creating the virtual image"
}

variable "public_nic_name" {
  description = "Name of the public network interface"
  default = "ens192"
}


variable "cloud_install_tar_file_name" {
  description = "Name of the tar file downloaded from the mirror, which contains the Cloud Installer code."
  default = "cloud_install.tar"
}

########
# Isolate IP address components:
locals {
  vm_ipv4_address_elements = "${split(".",var.vm_start_ipv4_address)}"
  vm_ipv4_address_base = "${format("%s.%s.%s",local.vm_ipv4_address_elements[0],local.vm_ipv4_address_elements[1],local.vm_ipv4_address_elements[2])}"
  vm_ipv4_address_start= "${local.vm_ipv4_address_elements[3] }"
}

###########################################################################################################################################################


# HDP Nodes
resource "vsphere_virtual_machine" "hdp-computenodes" {
	count  = "${var.num_compute_nodes}"
  name = "${var.vm_name_prefix}-${var.node_label}-cn-${ count.index }"
  num_cpus = "${var.vm_number_of_vcpu}"
  memory = "${var.vm_memory}"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-${var.node_label}-cn-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index }"
        ipv4_netmask = "${ var.vm_ipv4_prefix_length }"
      }
    ipv4_gateway = "${var.vm_ipv4_gateway}"
    }
  }

  network_interface {
    network_id = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${var.vm_adapter_type}"
  }

  disk {
    label = "${var.vm_name_prefix}0.vmdk"
    size = "${var.vm_root_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  }
  
  disk {
    label = "${var.vm_name_prefix}1.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }
  
  disk {
    label = "${var.vm_name_prefix}3.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "3"
  }
  
  disk {
    label = "${var.vm_name_prefix}4.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "4"
  }

  
  disk {
    label = "${var.vm_name_prefix}5.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "5"
  }
  
  disk {
    label = "${var.vm_name_prefix}6.vmdk"
    size = "${var.vm_datanode_disk_size}"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "6"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
  }


  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "chmod 700 /root/.ssh",
      "echo ${var.public_ssh_key} > /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
      "echo StrictHostKeyChecking no > /root/.ssh/config",
      "chmod 600 /root/.ssh/config",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }

}

resource "null_resource" "start_install" {

  depends_on = [ 
  	"vsphere_virtual_machine.hdp-computenodes"
  ]

  connection {
    host     = "${vsphere_virtual_machine.hdp-computenodes.0.clone.0.customize.0.network_interface.0.ipv4_address}"
    type     = "ssh"
    user     = "root"
    password = "${var.ssh_user_password}"
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

yum install -y expect

#passphrase=`cat /root/passphrase.fifo`
passphrase=`cat /root/passphrase`

eval `ssh-agent`
chmod 700 /opt/addSshKeyId.exp
/opt/addSshKeyId.exp $passphrase


yum install -y ksh rsync unzip  

mkdir -p /opt/cloud_install; 

cd /opt/cloud_install;

. /opt/monkey_cam_vars.txt;

wget http://$cam_monkeymirror/cloud_install/$cloud_install_tar_file_name

tar xf ./$cloud_install_tar_file_name

echo "Generate new global.properties"
perl -f cam_integration/01_gen_cam_addnodes_properties.pl

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
set -x
eval \`ssh-agent\`
/opt/addSshKeyId.exp $passphrase
cd /opt/cloud_install_${var.node_label}
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
nohup /opt/cloud_install_${var.node_label}/addNodes-${var.node_label}.sh >/opt/cloud_install_${var.node_label}/addNodes-${var.node_label}.log 2>&1 &
sleep 60"

EOF

    destination = "/opt/addnode.sh"

  }
  

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = [
      "echo ${var.private_ssh_key} | base64 -d > /root/.ssh/id_rsa",
      "chmod 600 /root/.ssh/id_rsa",
    
      "echo  export cam_ssh_user=${var.ssh_user} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ssh_user_password=${var.ssh_user_password} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_sudo_password=XXXXX >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_node_label=${var.node_label} >> /opt/monkey_cam_vars.txt",   
      "echo  export cam_vm_domain=${var.vm_domain} >> /opt/monkey_cam_vars.txt",      
      "echo  export cam_vm_dns_servers=${join(",",var.vm_dns_servers)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_vm_ipv4_prefix_length=${var.vm_ipv4_prefix_length} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_public_nic_name=${var.public_nic_name} >> /opt/monkey_cam_vars.txt",
      "echo  export cloud_install_tar_file_name=${var.cloud_install_tar_file_name} >> /opt/monkey_cam_vars.txt",
            
      "echo  export cam_monkeymirror=${var.monkey_mirror} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_driver_ip=${var.driver_ip} >> /opt/monkey_cam_vars.txt",    
         
      "echo  export cam_hdp_addnodes_ip=${join(",",vsphere_virtual_machine.hdp-computenodes.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_hdp_addnodes_name=${join(",",vsphere_virtual_machine.hdp-computenodes.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo ${var.ssh_key_passphrase} > /root/passphrase ",
      "chmod 600 /root/passphrase",

      "chmod 700 /opt/addnode.sh",
      "nohup /opt/addnode.sh &",
      
      "sleep 120"
    ]
  }
}
