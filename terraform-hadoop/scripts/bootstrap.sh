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

echo "[TASK 5] Installing Java"

yum -y install git-core net-tools wget lsof nc psmisc
yum install -y java-1.8.0-openjdk.x86_64 java-1.8.0-openjdk-devel
mkdir -p  /usr/bigdata /usr/bigdata/softwares
#mkdir -p /usr/bigdata/data/{name_dir,data_dir,hive}
chown -R $hadoop_user:$hadoop_user /usr/bigdata

echo "[TASK 6] setting up ansible for hadoop user"

su - $hadoop_user <<EOF
echo "$PWD"

cd /usr/bigdata/softwares
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p /usr/bigdata/Miniconda3
echo export ANSIBLE_CONFIG=/usr/bigdata/ansibleProjects/files >>~/.bash_profile
export PATH=/usr/bigdata/Miniconda3/bin:\$PATH
echo PATH=/usr/bigdata/Miniconda3/bin:\$PATH >>~/.bash_profile
echo export LANG=\"en_US.UTF-8\" >>~/.bash_profile
/usr/bigdata/Miniconda3/bin/conda create -n ansible -y
source activate ansible
pip install ansible
EOF


echo "[TASK 7] Creating ansible host file"

su - $hadoop_user <<EOF1
mkdir -p /usr/bigdata/ansibleProjects/files/
mkdir -p /usr/bigdata/data/data_dir
cat >>/usr/bigdata/ansibleProjects/files/hosts<<EOF2

###################
###################
[default]
dev1-kworker0.tanu.com

[buildserver]
dev1-kworker0.tanu.com

[nameNode]
dev1-kmaster1.tanu.com
dev1-kmaster0.tanu.com

[dataNode]
dev1-kmaster1.tanu.com
dev1-kworker0.tanu.com

[hiveNode]
dev1-kmaster1.tanu.com

[hueNode]
dev1-kmaster1.tanu.com

[hiveserver2Node]
dev1-kmaster1.tanu.com


[hivemetastoreNode]
dev1-kworker0.tanu.com
dev1-kmaster1.tanu.com

[sparkMaster]
dev1-kmaster1.tanu.com
dev1-kmaster0.tanu.com


[sparkWorker]
dev1-kmaster1.tanu.com
dev1-kworker0.tanu.com

[zookeeperNode]
dev1-kmaster0.tanu.com zookeeper_id=1       #hostname command returns "zoo1"
dev1-kmaster1.tanu.com zookeeper_id=2       #hostname command returns "zoo2"
dev1-kworker0.tanu.com zookeeper_id=3       #hostname command returns "zoo3"

[journalNode]
dev1-kmaster1.tanu.com
dev1-kmaster0.tanu.com
dev1-kworker0.tanu.com

EOF2
EOF1

echo "[TASK 8] Creating ansible.cfg file"

su - $hadoop_user <<EOF1
cat >>/usr/bigdata/ansibleProjects/files/ansible.cfg<<EOF2
[defaults]
inventory         = hosts
host_key_checking = False
###############################
EOF2
EOF1
echo export LANG=\"en_US.UTF-8\" >>~/.bash_profile
