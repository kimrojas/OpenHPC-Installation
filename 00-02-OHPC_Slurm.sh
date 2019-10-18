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
perl -pi -e "s/device = eth1/device = eno01/" /etc/warewulf/provision.conf

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
wwmkchroot centos-7 $CHROOT

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
# perl -pi -e "s/^NodeName=(\S+)/NodeName=c[1-2]/" /etc/slurm/slurm.conf
# perl -pi -e "s/^PartitionName=normal Nodes=(\S+)/PartitionName=normal Nodes=c[1-2]/" /etc/slurm/slurm.conf
# perl -pi -e "s/^Sockets=(\S+)/Sockets=1/" /etc/slurm/slurm.conf
# perl -pi -e "s/^CoresPerSocket=(\S+)/CoresPerSocket=4/" /etc/slurm/slurm.conf
# perl -pi -e "s/^ThreadsPerCore=(\S+)/ThreadsPerCore=1/" /etc/slurm/slurm.conf


