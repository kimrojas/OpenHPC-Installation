# Automation script for cluster 

# Master
# Hostname: master
# eno1: private(internal) network 192.168.5.1 (255.255.255.0)
# eno2: public network 10.2.100.200
# note: network need to be adapted to system in question

# Compute1
# Hostname: c1
# enp4s0: private network 192.168.5.51 MAC 70:4d:7b:a0:f8:56

# Compute2
# Hostname: c2
# enp4s0: private network 192.168.5.52 MAC 70:4d:7b:a0:fa:48

## ADD MASTER HOST ##
echo '192.168.5.1 master' >> /etc/hosts
hostnamectl set-hostnname master

## DISABLE FIREWALL ##
systemctl disable firewalld
systemctl stop firewalld

## DISABLE SELINUX ##
echo '''
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted ''' > /etc/selinux/config

## REBOOT ##
reboot
