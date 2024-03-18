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

echo "[TASK 1] Seeting up passwordless authentication for master"
#su - hadoop <<EOF
#echo $PWD
#ssh-keygen -t rsa -q -f "/home/hadoop/.ssh/id_rsa" -N ""
#chmod 0700 /home/hadoop/.ssh
#echo "/home/hadoop"
#sshpass -p "hadoop" ssh -o StrictHostKeyChecking=no hadoop@172.16.16.103 cat /home/hadoop/.ssh/id_rsa.pub| tee -a /home/hadoop/.ssh/authorized_keys
#chmod 600 /home/hadoop/.ssh/authorized_keys
#yum install -y sshpass
#apt install -qq -y sshpass >/dev/null 2>&1
#sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.example.com:/joincluster.sh /joincluster.sh 2>/dev/null
#bash /joincluster.sh >/dev/null 2>&1
#EOF

mkdir /home/$hadoop_user/.ssh/
chmod 700 /home/$hadoop_user/.ssh/
for x in `seq $no_of_master_ip`
do
	master_ip=${@:x:1}
sshpass -p "$hadoop_user_password" ssh -o StrictHostKeyChecking=no $hadoop_user@$master_ip cat /home/$hadoop_user/.ssh/id_rsa.pub| tee -a /home/$hadoop_user/.ssh/authorized_keys
done
chmod 600 /home/$hadoop_user/.ssh/authorized_keys
chown -R $hadoop_user:$hadoop_user /home/$hadoop_user/.ssh

echo "[TASK 2] setting ssh key within localhost"

su - $hadoop_user <<EOF
ssh-keygen -t rsa -q -f "/home/$hadoop_user/.ssh/id_rsa" -N ""
chmod 0700 /home/$hadoop_user/.ssh
sshpass -p "$hadoop_user_password" ssh-copy-id -o StrictHostKeyChecking=no -i /home/$hadoop_user/.ssh/id_rsa.pub localhost
#cat /home/$hadoop_user/.ssh/id_rsa.pub
#ip a
EOF

