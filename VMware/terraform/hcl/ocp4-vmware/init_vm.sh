cloud_mirror_server=$1
dns_server=$2
puclic_key=$3
			
#
# Set up ssh key
#			
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo ${puclic_key} > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo StrictHostKeyChecking no > /root/.ssh/config
chmod 600 /root/.ssh/config

#
# Set up initial DNS config
#			
echo nameserver ${dns_server} > /etc/resolv.conf
      			
			
#
# Set up YUM config to point to local mirror
#		
hostSubstStr="s/https?:\/\/[^\/]+/http:\/\/${cloud_mirror_server}/"
subscription-manager config --rhsm.auto_enable_yum_plugins=0
subscription-manager config --rhsm.manage_repos=0
sed -i -r 's/enabled[ \t]*=[ \t]*1/enabled = 0/' /etc/yum/pluginconf.d/rhnplugin.conf
sed -i -r 's/enabled[ \t]*=[ \t]*1/enabled = 0/' /etc/yum/pluginconf.d/subscription-manager.conf
softlayerYumFiles="/etc/pki/rpm-gpg/RPM-GPG-KEY* /etc/pki/entitlement/* /etc/rhsm/ca/* /etc/rhsm/* /etc/yum.repos.d/redhat.repo /etc/yum.repos.d/redhat-rhui.repo"
## Backup current yum config files, before removing them
if [ ! -e /root/YUM-BKP.tar ]; then zip -r /root/YUM-BKP.zip ${softlayerYumFiles} /etc/yum.repos.d/*;fi
## Remove stuff from Softlayer and /etc/yum.repos.d...
rm -rf ${softlayerYumFiles} /etc/yum.repos.d/*
yum clean all
rm -rf /var/cache/yum
rm -f /etc/yum.repos.d/redhat_monkey.repo
cp /tmp/redhat_monkey.repo /etc/yum.repos.d/redhat_monkey.repo
			
sed -r -i -e ${hostSubstStr} \
            -e 's/^mirror/#mirror/'\
            -e 's/^metalink/#metalink/' \
            -e 's/^#baseurl/baseurl/' \
            -e 's/gpgcheck = 1/gpgcheck = 0/' \
            -e 's/enabled = 0/enabled = 1/' \
            -e 's/sslverify = 1/sslverify = 0/' \
					  -e 's/sslclientcert[^$]*//' \
					  -e 's/sslverify[^$]*//' \
					  -e 's/sslclientkey[^$]*//' \
					  -e 's/gpgkey[^$]*//' \
					  -e 's/sslcacert[^$]*//' \
					  -e 's/^\[rhel/\[monkey-rhel/' \
          /etc/yum.repos.d/redhat_monkey.repo 
yum repolist all


#
# To be revised, possibly removed...
#
systemctl disable NetworkManager
systemctl stop NetworkManager

yum update -y
