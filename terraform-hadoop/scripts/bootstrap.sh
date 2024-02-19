#!/bin/bash

## !IMPORTANT ##
#
## This script is tested only in the generic/ubuntu2004 Vagrant box
## If you use a different version of Ubuntu or a different Ubuntu Vagrant box test this again
#

if [ "$#" -ne 2 ]
then
         echo "Error useage ./$(basename $0) master_ip hadoop_user hadoop_user_password"
         exit 5
else :
        #total_arg="$#"
        #no_of_master_ip=`expr $total_arg - 2`
        #hadoop_user_index=`expr $no_of_master_ip + 1`
        #hadoop_user_password_index=`expr $hadoop_user_index + 1`
        hadoop_user=$1
        hadoop_user_password=$2
        echo "Haoop_user $hadoop_user"
        echo "Haoop_password $hadoop_user_password"
fi


echo "[TASK 1] install epel-release"

cd /etc/yum.repos.d/
#sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
#sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

#yum install -y  epel-release
echo "[TASK 2] install sshpass rpm"
yum install -y https://dl.fedoraproject.org/pub/archive/epel/8.5.2022-05-10/Everything/x86_64/Packages/s/sshpass-1.06-9.el8.x86_64.rpm

echo "[TASK 3] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[TASK 4] Set root password"
echo -e "kubeadmin123\nkubeadmin123" | passwd root >/dev/null 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc
useradd $hadoop_user 
echo -e "$hadoop_user_password\n$hadoop_user_password" | passwd $hadoop_user >/dev/null 2>&1

#echo "[TASK 5] Update /etc/hosts file"
#cat >>/etc/hosts<<EOF
#172.16.16.103   sparkmaster.example.com     sparkmaster
#172.16.16.104   sworker1.example.com    sworker1
#172.16.16.105   sworker2.example.com    sworker2
#EOF

echo "[TASK 6] Installing Java"

yum -y install git-core net-tools wget lsof
yum install -y java-1.8.0-openjdk.x86_64 java-1.8.0-openjdk-devel
mkdir -p  /usr/bigdata /usr/bigdata/softwares
#mkdir -p /usr/bigdata/data/{name_dir,data_dir,hive}
chown -R $hadoop_user:$hadoop_user /usr/bigdata

