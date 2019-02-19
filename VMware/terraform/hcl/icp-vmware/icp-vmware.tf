
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

variable "sudo_user" {
  description = "Sudo User"
}

variable "sudo_password" {
  description = "Sudo Password"
}

variable "monkey_mirror" {
  description = "Monkey Mirror IP or Hostname"
}

variable "num_workers" {
  description = "Number of ICP worker nodes to create"
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


variable "time_server" {
  description = "Hostname or IPv4 for time server"
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


########
# Isolate IP address components:
locals {
  vm_ipv4_address_elements = "${split(".",var.vm_start_ipv4_address)}"
  vm_ipv4_address_base = "${format("%s.%s.%s",local.vm_ipv4_address_elements[0],local.vm_ipv4_address_elements[1],local.vm_ipv4_address_elements[2])}"
  vm_ipv4_address_start= "${local.vm_ipv4_address_elements[3] }"
}

###########################################################################################################################################################

# Driver 
resource "vsphere_virtual_machine" "driver" {
  name = "${var.vm_name_prefix}-drv"
#  folder = "${var.vm_folder}"
  num_cpus = "4"
  memory = "4096"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-drv"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${ local.vm_ipv4_address_start + 2 }"
        ipv4_netmask = "${ var.vm_ipv4_prefix_length }"
      }
    ipv4_gateway = "${var.vm_ipv4_gateway}"
    dns_server_list = "${var.vm_dns_servers}"
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

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -e 's/# %wheel/%wheel/' -e 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers",
      "sudo useradd ${var.sudo_user}",
      "sudo su -c 'echo ${var.sudo_password} | passwd ${var.sudo_user} --stdin'",
      "sudo usermod ${var.sudo_user} -g wheel"
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

yum install -y ksh rsync expect unzip 

perl -f cam_integration/01_gen_cam_install_properties.pl

. ./setenv

utils/01_prepare_driver.sh


. $MASTER_INSTALLER_HOME/utils/00_globalFunctions.sh
nodeList=`echo $cloud_hostpasswords|awk -v RS="," -v FS=":" '{s=sprintf("%s %s",s,$1);}END{print s}'`
for hostName in `echo $nodeList|sed 's/,/ /g'`
do
  if [ "$hostName" != "" ]
	then
    hostPwd=`get_root_password $hostName`
		ssh.exp $hostName $hostPwd "echo \`hostname\`.\`hostname -d\`>/etc/hostname;"
	fi
done

utils/01_prepare_all_nodes.sh

nohup icp_files/01_master_icp.sh &

EOF

    destination = "/opt/installation.sh"

  }
  
}




###########################################################################################################################################################

# IDM
resource "vsphere_virtual_machine" "idm" {
  count="1"
  name = "${var.vm_name_prefix}-idm-${ count.index }"
  num_cpus = "4"
  memory = "4096"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-idm-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + 3}"
        ipv4_netmask = "${ var.vm_ipv4_prefix_length }"
      }
    ipv4_gateway = "${var.vm_ipv4_gateway}"
    dns_server_list = [ "127.0.0.1" , "10.0.80.11" , "10.0.80.12" ]
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

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
  }


  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -e 's/# %wheel/%wheel/' -e 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers",
      "sudo useradd ${var.sudo_user}",
      "sudo su -c 'echo ${var.sudo_password} | passwd ${var.sudo_user} --stdin'",
      "sudo usermod ${var.sudo_user} -g wheel"
    ]
  }

}



###########################################################################################################################################################

# HAProxy
resource "vsphere_virtual_machine" "haproxy" {
  count="1"
  name = "${var.vm_name_prefix}-icphaproxy-${ count.index }"
  num_cpus = "4"
  memory = "4096"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-icphaproxy-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + 4 }"
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

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
  }


  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -e 's/# %wheel/%wheel/' -e 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers",
      "sudo useradd ${var.sudo_user}",
      "sudo su -c 'echo ${var.sudo_password} | passwd ${var.sudo_user} --stdin'",
      "sudo usermod ${var.sudo_user} -g wheel",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }

}


###########################################################################################################################################################

# ICP Boot
resource "vsphere_virtual_machine" "icpboot" {
  count="1"
  name = "${var.vm_name_prefix}-icpboot-${ count.index }"
#  folder = "${var.vm_folder}"
  num_cpus = "8"
  memory = "16384"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-icpboot-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 5 + count.index }"
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
    size = "300"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
  }


  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -e 's/# %wheel/%wheel/' -e 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers",
      "sudo useradd ${var.sudo_user}",
      "sudo su -c 'echo ${var.sudo_password} | passwd ${var.sudo_user} --stdin'",
      "sudo usermod ${var.sudo_user} -g wheel",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "pvcreate /dev/sdb",
      "vgextend vg_node1 /dev/sdb",
      "lvextend /dev/vg_node1/lv_root /dev/sdb",
      "resize2fs /dev/mapper/vg_node1-lv_root",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }
}







###########################################################################################################################################################

# ICP Master
resource "vsphere_virtual_machine" "icpmaster" {
  count="3"
  name = "${var.vm_name_prefix}-icpmaster-${ count.index }"
#  folder = "${var.vm_folder}"
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
        host_name = "${var.vm_name_prefix}-icpmaster-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 6 + count.index }"
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
    size = "300"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
  }


  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -e 's/# %wheel/%wheel/' -e 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers",
      "sudo useradd ${var.sudo_user}",
      "sudo su -c 'echo ${var.sudo_password} | passwd ${var.sudo_user} --stdin'",
      "sudo usermod ${var.sudo_user} -g wheel",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf",
      "pvcreate /dev/sdb",
      "vgextend vg_node1 /dev/sdb",
      "lvextend /dev/vg_node1/lv_root /dev/sdb",
      "resize2fs /dev/mapper/vg_node1-lv_root"
    ]
  }
}



###########################################################################################################################################################

# ICP Workers
resource "vsphere_virtual_machine" "icpworker" {
  count="${var.num_workers}"
  name = "${var.vm_name_prefix}-icpworker-${ count.index }"
#  folder = "${var.vm_folder}"
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
        host_name = "${var.vm_name_prefix}-icpworker-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 9 + count.index }"
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
    size = "300"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
  }


  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -e 's/# %wheel/%wheel/' -e 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers",
      "sudo useradd ${var.sudo_user}",
      "sudo su -c 'echo ${var.sudo_password} | passwd ${var.sudo_user} --stdin'",
      "sudo usermod ${var.sudo_user} -g wheel",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf",
      "pvcreate /dev/sdb",
      "vgextend vg_node1 /dev/sdb",
      "lvextend /dev/vg_node1/lv_root /dev/sdb",
      "resize2fs /dev/mapper/vg_node1-lv_root"
    ]
  }
}

###########################################################################################################################################################

# ICP Proxy
resource "vsphere_virtual_machine" "icpproxy" {
  count="1"
  name = "${var.vm_name_prefix}-icpproxy-${ count.index }"
#  folder = "${var.vm_folder}"
  num_cpus = "8"
  memory = "16384"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-icpproxy-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 9 + var.num_workers + count.index }"
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
    size = "300"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  disk {
    label = "${var.vm_name_prefix}2.vmdk"
    size = "700"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "2"
  }

  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
  }


  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -e 's/# %wheel/%wheel/' -e 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers",
      "sudo useradd ${var.sudo_user}",
      "sudo su -c 'echo ${var.sudo_password} | passwd ${var.sudo_user} --stdin'",
      "sudo usermod ${var.sudo_user} -g wheel",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf",
      "pvcreate /dev/sdb",
      "vgextend vg_node1 /dev/sdb",
      "lvextend /dev/vg_node1/lv_root /dev/sdb",
      "resize2fs /dev/mapper/vg_node1-lv_root"
    ]
  }
}

############################################################################################################################################################

# ICP NFS Server
resource "vsphere_virtual_machine" "icpnfs" {
	count  = "1"
  name = "${var.vm_name_prefix}-icpnfs-${ count.index }"
  num_cpus = "8"
  memory = "16384"
  resource_pool_id = "${data.vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
  guest_id = "${data.vsphere_virtual_machine.vm_template.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.vm_template.id}"
    customize {
      linux_options {
        domain = "${var.vm_domain}"
        host_name = "${var.vm_name_prefix}-icpnfs-${ count.index }"
      }
      network_interface {
        ipv4_address = "${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + count.index + 10 + var.num_workers }"
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
    size = "1000"
    keep_on_remove = "false"
    datastore_id = "${data.vsphere_datastore.vm_datastore.id}"
    unit_number = "1"
  }
  
  
  connection {
    type = "ssh"
    user     = "${var.ssh_user}"
    password = "${var.ssh_user_password}"
  }


  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -e 's/# %wheel/%wheel/' -e 's/Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers",
      "sudo useradd ${var.sudo_user}",
      "sudo su -c 'echo ${var.sudo_password} | passwd ${var.sudo_user} --stdin'",
      "sudo usermod ${var.sudo_user} -g wheel",
      "systemctl disable NetworkManager",
      "systemctl stop NetworkManager",
      "echo nameserver ${var.vm_dns_servers[0]} > /etc/resolv.conf"
    ]
  }

}



resource "null_resource" "start_install" {

  
  
  depends_on = [ 
  	"vsphere_virtual_machine.driver",  
  	"vsphere_virtual_machine.idm",   
  	"vsphere_virtual_machine.icpboot",  
  	"vsphere_virtual_machine.icpmaster",  
  	"vsphere_virtual_machine.icpworker",  
  	"vsphere_virtual_machine.icpproxy",  
  	"vsphere_virtual_machine.icpnfs"
  ]

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host     = "${vsphere_virtual_machine.driver.0.clone.0.customize.0.network_interface.0.ipv4_address}"
    type     = "ssh"
    user     = "root"
    password = "${var.ssh_user_password}"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = [
    
      "echo  export cam_ssh_user=${var.ssh_user} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_ssh_user_password=${var.ssh_user_password} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_sudo_user=${var.sudo_user} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_sudo_password=${var.sudo_password} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_vm_domain=${var.vm_domain} >> /opt/monkey_cam_vars.txt",      
      "echo  export cam_vm_dns_servers=${join(",",var.vm_dns_servers)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_vm_ipv4_prefix_length=${var.vm_ipv4_prefix_length} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_time_server=${var.time_server} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_cluster_name=${var.cluster_name} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_public_nic_name=${var.public_nic_name} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cloud_install_tar_file_name=${var.cloud_install_tar_file_name} >> /opt/monkey_cam_vars.txt",
      

      # For the SL VMs used so far, /dev/xvdb is defined as swap. Removing it for now...
      "echo  export cam_icp_nfs_data_devices=/disk2@/dev/sdb >> /opt/monkey_cam_vars.txt",

      "echo  export cam_icp_docker_device=/dev/sdc >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_monkeymirror=${var.monkey_mirror} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_driver_ip=${join(",",vsphere_virtual_machine.driver.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_driver_name=${join(",",vsphere_virtual_machine.driver.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_icpboot_ip=${join(",",vsphere_virtual_machine.icpboot.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpboot_name=${join(",",vsphere_virtual_machine.icpboot.*.name)} >> /opt/monkey_cam_vars.txt",    
      
      "echo  export cam_icpmasters_ip=${join(",",vsphere_virtual_machine.icpmaster.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpmasters_name=${join(",",vsphere_virtual_machine.icpmaster.*.name)} >> /opt/monkey_cam_vars.txt",    
      
      "echo  export cam_icpworkers_ip=${join(",",vsphere_virtual_machine.icpworker.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpworkers_name=${join(",",vsphere_virtual_machine.icpworker.*.name)} >> /opt/monkey_cam_vars.txt", 
      
      "echo  export cam_icpproxies_ip=${join(",",vsphere_virtual_machine.icpproxy.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpproxies_name=${join(",",vsphere_virtual_machine.icpproxy.*.name)} >> /opt/monkey_cam_vars.txt", 
    
      "echo  export cam_icpnfs_ip=${join(",",vsphere_virtual_machine.icpnfs.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icpnfs_name=${join(",",vsphere_virtual_machine.icpnfs.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_idm_ip=${join(",",vsphere_virtual_machine.idm.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_idm_name=${join(",",vsphere_virtual_machine.idm.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_icp_haproxy_ip=${join(",",vsphere_virtual_machine.haproxy.*.clone.0.customize.0.network_interface.0.ipv4_address)} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_haproxy_name=${join(",",vsphere_virtual_machine.haproxy.*.name)} >> /opt/monkey_cam_vars.txt",
    
      "echo  export cam_icp_network_cidr=${var.icp_network_cidr} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_service_cluster_ip_range=${var.icp_service_cluster_ip_range} >> /opt/monkey_cam_vars.txt",
      
      "echo  export cam_icp_cluster_vip=${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start} >> /opt/monkey_cam_vars.txt",
      "echo  export cam_icp_proxy_vip=${local.vm_ipv4_address_base }.${local.vm_ipv4_address_start + 1} >> /opt/monkey_cam_vars.txt",

      "chmod 755 /opt/installation.sh",
      "nohup /opt/installation.sh &",
      "sleep 60"
    ]
  }
  
  
}
