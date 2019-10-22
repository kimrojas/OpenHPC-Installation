## OpenHPC RESPOSITORY ##
yum -y install http://build.openhpc.community/OpenHPC:/1.3/CentOS_7/x86_64/ohpc-release-1.3-1.el7.x86_64.rpm | tee OHPC_repo.o

## BASIC PACKAGE ## 
yum -y install ohpc-base ohpc-warewulf | tee base_pack.o

## SET TIME SERVER ##
systemctl enable ntpd.service
echo "server ph.pool.ntp.org" >> /etc/ntp.conf 
systemctl restart ntpd

## INSTALL SLURM SERVER ## 
yum -y install ohpc-slurm-server | tee slurm_server_install.o
perl -pi -e "s/ControlMachine=\S+/ControlMachine=master/" /etc/slurm/slurm.conf

## DEFINE INTERNAL INTERFACE (of master) ## 
perl -pi -e "s/device = eth1/device = eno1/" /etc/warewulf/provision.conf

## ENABLE tftp SERVICE ##
perl -pi -e "s/^\s+disable\s+= yes/ disable = no/" /etc/xinetd.d/tftp

## DEFINE INTERNAL NETWORK IP (of master) ##
ifconfig eno1 192.168.5.1 netmask 255.255.255.0 up

## RESTART AND ENABLE SERVICES
systemctl restart xinetd
systemctl enable mariadb.service 
systemctl restart mariadb
systemctl enable httpd.service
systemctl restart httpd
systemctl enable dhcpd.service


## DEFINE IMAGE FOR COMPUTE NODE ##
export CHROOT=/opt/ohpc/admin/images/centos7
wwmkchroot centos-7 $CHROOT | tee def_img.o

## INSTALL OpenHPC FOR COMPUTE NODE ##
yum -y --installroot=$CHROOT install ohpc-base-compute | tee OHPC_node_install.o

## COPY resolv.conf TO COMPUTE NODE ##
cp -p /etc/resolv.conf $CHROOT/etc/resolv.conf

## INSTALL SLURM CLIENT TO COMPUTE NODE AND MASTER ##
yum -y --installroot=$CHROOT install ohpc-slurm-client | tee slurm_client_node.o
yum -y install ohpc-slurm-client | tee slurm_client_master.o

## ADD MASTER NODE TO COMPUTE NODE ##
echo 'master  192.168.5.1' >> $CHROOT/etc/hosts

## INSTALL NTP FOR COMPUTE NODE ##
yum -y --installroot=$CHROOT install ntp | tee ntp_node.o

## INSTALL KERNEL FOR COMPUTE NODE ##
yum -y --installroot=$CHROOT install kernel | tee kernel_node.o

## INSTALL LMOD FOR COMPUTE NODE AND MASTER ##
yum -y --installroot=$CHROOT install lmod-ohpc | tee lmod_node.o
yum -y install lmod-ohpc | tee lmod_master.o

## CREATE BASIC VALUES FOR OpenHPC ##
wwinit database | tee basic_database.o
wwinit ssh_keys | tee basic_ssh_keys.o

## CREATE NFS CLIENT ##
# by mount /home and /opt/ohpc/pub from master node
echo "192.168.5.1:/home /home nfs nfsvers=3,nodev,nosuid,noatime 0 0" >> $CHROOT/etc/fstab 
echo "192.168.5.1:/opt/ohpc/pub /opt/ohpc/pub nfs nfsvers=3,nodev,noatime 0 0" >> $CHROOT/etc/fstab
echo "192.168.5.1:/share /share nfs nfsvers=3,nodev,nosuid,noatime 0 0" >> $CHROOT/etc/fstab 

## CREATE NFS SERVER ##
echo "/home *(rw,no_subtree_check,fsid=10,no_root_squash)" >> /etc/exports
echo "/opt/ohpc/pub *(ro,no_subtree_check,fsid=11)" >> /etc/exports
exportfs -a
systemctl restart nfs-server
systemctl enable nfs-server

## DEFINE KERNEL SETTINGS FOR COMPUTE NODE ##
chroot $CHROOT systemctl enable ntpd
echo "server 192.168.5.1" >> $CHROOT/etc/ntp.conf

## UPDATE SLURM CONFIGURATION ## (update for multiple types of computers)
### MASTER
perl -pi -e "s/ClusterName=\S+/ClusterName=HPCL/"  /etc/slurm/slurm.conf
perl -pi -e "s/ControlMachine=\S+/ControlMachine=master/" /etc/slurm/slurm.conf

perl -pi -e "s/^NodeName=\S+/NodeName=c[1-2]/" /etc/slurm/slurm.conf
perl -pi -e "s/^PartitionName=normal Nodes=\S+/PartitionName=normal Nodes=c[1-2]/" /etc/slurm/slurm.conf
perl -pi -e "s/Sockets=\S+/Sockets=1/" /etc/slurm/slurm.conf 
perl -pi -e "s/CoresPerSocket=\S+/CoresPerSocket=4/" /etc/slurm/slurm.conf
perl -pi -e "s/ThreadsPerCore=\S+/ThreadsPerCore=1/" /etc/slurm/slurm.conf

### NODE
perl -pi -e "s/ClusterName=\S+/ClusterName=HPCL/"  $CHROOT/etc/slurm/slurm.conf
perl -pi -e "s/ControlMachine=\S+/ControlMachine=master/" $CHROOT/etc/slurm/slurm.conf

perl -pi -e "s/^NodeName=\S+/NodeName=c[1-2]/" $CHROOT/etc/slurm/slurm.conf
perl -pi -e "s/^PartitionName=normal Nodes=\S+/PartitionName=normal Nodes=c[1-2]/" $CHROOT/etc/slurm/slurm.conf
perl -pi -e "s/Sockets=\S+/Sockets=1/" $CHROOT/etc/slurm/slurm.conf 
perl -pi -e "s/CoresPerSocket=\S+/CoresPerSocket=4/" $CHROOT/etc/slurm/slurm.conf
perl -pi -e "s/ThreadsPerCore=\S+/ThreadsPerCore=1/" $CHROOT/etc/slurm/slurm.conf

## ENABLE MUNGE
systemctl enable munge
systemctl enable slurmctld
systemctl start munge
systemctl start slurmctld
chroot $CHROOT systemctl enable slurmctld

## DEFINE MEMLOCK
perl -pi -e 's/# End of file/\* soft memlock unlimited\n$&/s' /etc/security/limits.conf
perl -pi -e 's/# End of file/\* hard memlock unlimited\n$&/s' /etc/security/limits.conf
perl -pi -e 's/# End of file/\* soft memlock unlimited\n$&/s' $CHROOT/etc/security/limits.conf 
perl -pi -e 's/# End of file/\* hard memlock unlimited\n$&/s' $CHROOT/etc/security/limits.conf

## DEFIN RSYSLOG FOR COMPUTE NODE BY POINT TO MASTER NODE
perl -pi -e "s/\\#\\\$ModLoad imudp/\\\$ModLoad imudp/" /etc/rsyslog.conf
perl -pi -e "s/\\#\\\$UDPServerRun 514/\\\$UDPServerRun 514/" /etc/rsyslog.conf 
systemctl restart rsyslog
echo "*.* @192.168.5.1:514" >> $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^\*\.info/\\#\*\.info/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^authpriv/\\#authpriv/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^mail/\\#mail/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^cron/\\#cron/" $CHROOT/etc/rsyslog.conf
perl -pi -e "s/^uucp/\\#uucp/" $CHROOT/etc/rsyslog.conf

## INSTALL GANGLIA
yum -y install ohpc-ganglia
yum -y --installroot=$CHROOT install ganglia-gmond-ohpc
cp /opt/ohpc/pub/examples/ganglia/gmond.conf /etc/ganglia/gmond.conf 
perl -pi -e "s/<sms>/master/" /etc/ganglia/gmond.conf
cp /etc/ganglia/gmond.conf $CHROOT/etc/ganglia/gmond.conf 
echo "gridname MySite.." >> /etc/ganglia/gmetad.conf
systemctl enable gmond 
systemctl enable gmetad 
systemctl start gmond
systemctl start gmetad
chroot $CHROOT systemctl enable gmond 
systemctl try-restart httpd

## INSTALL CLUSTERSHELL
yum -y install clustershell-ohpc
cd /etc/clustershell/groups.d
mv local.cfg local.cfg.orig
echo "adm: master" > local.cfg
echo "compute: c[1-2]" >> local.cfg
echo "all: @adm,@compute" >> local.cfg

## IMPORT FILE USING OpenHPC
wwsh file import /etc/passwd 
wwsh file import /etc/group
wwsh file import /etc/shadow
wwsh file import /etc/slurm/slurm.conf
wwsh file import /etc/munge/munge.key
wwsh file list

## DEFINE BOOTSTRAP IMAGE
export WW_CONF=/etc/warewulf/bootstrap.conf 
echo "drivers += updates/kernel/" >> $WW_CONF 
echo "drivers += overlay" >> $WW_CONF

## SETUP BOOTSTRAP IMAGE
wwbootstrap `uname -r`

## CREATE VIRTUAL NODE FILE SYSTEM (VNFS) IMAGE
wwvnfs --chroot $CHROOT

## DEFINE GATEWAY
echo "GATEWAYDEV=eno1" > /tmp/network.$$
wwsh -y file import /tmp/network.$$ --name network
wwsh -y file set network --path /etc/sysconfig/network --mode=0644 --uid=0 
wwsh file list

## REGISTER NODES
wwsh -y node new c1 --ipaddr=192.168.5.51 --hwaddr=70:4d:7b:a0:f8:56 -D eno1
wwsh -y node new c2 --ipaddr=192.168.5.52 --hwaddr=70:4d:7b:a0:fa:48 -D eno1np4s0
wwsh node list

## DEFINE VNFS FOR NODES
wwsh -y provision set "c1" --vnfs=centos7 --bootstrap=`uname -r` --files=dynamic_hosts,passwd,group,shadow,slurm.conf,munge.key,network
wwsh -y provision set "c2" --vnfs=centos7 --bootstrap=`uname -r` --files=dynamic_hosts,passwd,group,shadow,slurm.conf,munge.key,network
wwsh provision list

## RESTART GANGLIA
systemctl restart gmond 
systemctl restart gmetad 
systemctl restart dhcpd 
wwsh pxe update

## Sync all file to compute node
wwsh file resync

## COMPUTE NODE INSTALLATION ( BOOT VIA PXE) 
# Check run time by:
pdsh -w c[1-2] uptime

## RESOURCE MANAGER SETUP
systemctl restart munge
systemctl restart slurmctld
pdsh -w c[1-2] systemctl restart slurmd

## TEST MUNGE
munge -n | unmunge
munge -n | ssh c1 unmunge
munge -n | ssh c2 unmunge

## TEST SLURM
systemctl status slurmctld
ssh c1 systemctl status slurmd
ssh c2 systemctl status slurmd

## TEST RESOURCES
scontrol show nodes
