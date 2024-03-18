#!/bin/bash

if [ "$#" -ne 2 ]
then
         echo "Error useage ./$(basename $0) master_ip hadoop_user hadoop_user_password"
         exit 5
else :
        hadoop_user=$1
        hadoop_user_password=$2
        echo "Haoop_user $hadoop_user"
        echo "Haoop_password $hadoop_user_password"
fi

for x in `seq $no_of_master_ip`
do
        echo "master Ip is ${@:x:1} "
done

echo "[TASK 2] setting ssh key"

su - $hadoop_user <<EOF
ssh-keygen -t rsa -q -f "/home/$hadoop_user/.ssh/id_rsa" -N ""
chmod 0700 /home/$hadoop_user/.ssh
sshpass -p "$hadoop_user_password" ssh-copy-id -o StrictHostKeyChecking=no -i /home/$hadoop_user/.ssh/id_rsa.pub localhost
#cat /home/hadoop/.ssh/id_rsa.pub
#ip a
EOF

