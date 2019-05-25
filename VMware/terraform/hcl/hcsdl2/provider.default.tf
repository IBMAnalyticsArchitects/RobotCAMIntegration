##############################################################
# Define the vsphere provider
##############################################################

provider "vsphere" {
  allow_unverified_ssl = "${var.allow_unverified_ssl}"
  version = "~> 1.3" 
}