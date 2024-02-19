#!/bin/bash

echo "$@"
echo "$#"

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
