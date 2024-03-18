locals {
env = terraform.workspace

kmaster_count = 2 
kmaster_cpu = 1
kmaster_memory = 2048
kmaster_disk_size = 12884901888 #12gb 

kworker_count = 1 
kworker_cpu = 1
kworker_memory = 5000
kworker_disk_size = 12884901888 #12gb 

super_user = "ansible"
super_user_private_key = "/root/.ssh/id_rsa.pub"
local_hadoop_user = "hadoop"
local_hadoop_user_password = "hadoop123456"
host_domain_prefix = "tanu.com"
workers_prefix = "kworker"
masters_prefix = "kmaster"
}
