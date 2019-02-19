#!/bin/perl

$s=0;

while (<>) {
	if (/"name": "/) {
		if (/(access_key|secret_key|private_ssh_key|ssh_key_passphrase|idm_admin_password|idm_ldapsearch_password|idm_directory_manager_password|ssh|key)/) {
			$s=1;
#			print $_;
			$prop = $1;
		}
		else {
			$s=0;
		}
	}
	if ( ($s==1) && /"default": "/) {
#		print $_;
		$s=0;
		s/\n//;
		$val=$_;
		print "|",$prop,"|",$val,"\n";
	}
	if (/}/) {
		$s=0;
	}
}

