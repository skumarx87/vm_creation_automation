#!/bin/bash

if [ "$#" -lt 3 ]
then
         echo "Error useage ./$(basename $0) master_ip hadoop_user hadoop_user_password"
         exit 5
else :
        total_arg="$#"
        no_of_master_ip=`expr $total_arg - 2`
        hadoop_user_index=`expr $no_of_master_ip + 1`
        hadoop_user_password_index=`expr $hadoop_user_index + 1`
        hadoop_user=${@:hadoop_user_index:1}
        hadoop_user_password=${@:hadoop_user_password_index:1}
        echo "Haoop_user $hadoop_user"
        echo "Haoop_password $hadoop_user_password"
fi

for x in `seq $no_of_master_ip`
do
        echo "master Ip is ${@:x:1} "
done


echo "[TASK 1] setting up ansible for hadoop user"

su - hadoop <<EOF
echo "$PWD"

cd /usr/bigdata/softwares
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p /usr/bigdata/Miniconda3
export PATH=/usr/bigdata/Miniconda3/bin:\$PATH
echo PATH=/usr/bigdata/Miniconda3/bin:\$PATH >>~/.bash_profile
echo export LANG=\"en_US.UTF-8\" >>~/.bash_profile
/usr/bigdata/Miniconda3/bin/conda create -n ansible -y
source activate ansible
pip install ansible
EOF

echo "[TASK 2] setting ssh key"

su - hadoop <<EOF
ssh-keygen -t rsa -q -f "/home/hadoop/.ssh/id_rsa" -N ""
chmod 0700 /home/hadoop/.ssh
sshpass -p "hadoop123456" ssh-copy-id -o StrictHostKeyChecking=no -i /home/hadoop/.ssh/id_rsa.pub localhost
#cat /home/hadoop/.ssh/id_rsa.pub
#ip a
EOF

echo "[TASK 3] Creating ansible host file"

su - hadoop <<EOF1
mkdir -p /usr/bigdata/ansibleProjects/files/
mkdir -p /usr/bigdata/data/data_dir
cat >>/usr/bigdata/ansibleProjects/files/hosts<<EOF2
###################
[default]
sparkmaster.example.com

[buildserver]
sparkmaster.example.com

[nameNode]
sparkmaster.example.com

[dataNode]
sworker1.example.com
sworker2.example.com

[hiveNode]
sparkmaster.example.com
########################
EOF2
EOF1

echo "[TASK 4] Creating ansible.cfg file"

su - hadoop <<EOF1
cat >>/usr/bigdata/ansibleProjects/files/ansible.cfg<<EOF2
[defaults]
inventory         = hosts
host_key_checking = False
###############################
EOF2
EOF1
echo export LANG=\"en_US.UTF-8\" >>~/.bash_profile
