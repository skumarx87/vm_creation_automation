import subprocess
import json
import sys

print(sys.argv[1:])
super_user = sys.argv[1]
'''
env = sys.argv[2]
host_domain_prefix = sys.argv[3]
masters_prefix = sys.argv[4]
workers_prefix = sys.argv[5]
master_ips = sys.argv[6]
worker_ips = sys.argv[7]
'''
def getProcessOutput(cmd):
    process = subprocess.Popen(
        cmd,
        shell=True,
        stdout=subprocess.PIPE)
    process.wait()
    data, err = process.communicate()
    if process.returncode == 0:
        return data.decode('utf-8')
    else:
        print("Error:", err)
    return ""
x=getProcessOutput("terraform output -json")
all1 = json.loads(x)
file1 = open("/tmp/khosts", "w") 
all_ips = []
for y in all1['kmaster']['value']:
    all_ips.append(y)
    out="{} ".format(y)+' '.join(all1['kmaster']['value'][y])+"\n"
    print(out)
    file1.write(out)

for y in all1['kworker']['value']:
    all_ips.append(y)
    out="{} ".format(y)+' '.join(all1['kworker']['value'][y])+"\n"
    file1.write(out)

file1.close()
for ip in all_ips:
    print("Running commands in host: {}".format(ip))
    cmd="scp -o StrictHostKeyChecking=no /tmp/khosts {}@{}:/tmp/".format(super_user,ip)
    y=getProcessOutput(cmd)
    cmd1 = "ssh -o StrictHostKeyChecking=no {}@{} -C \"cat /tmp/khosts|sudo tee -a /etc/hosts\"".format(super_user,ip)
    print(cmd1)
    z = getProcessOutput(cmd1)
    print(z)

file1.close()
#print(json.loads(x)['kworker'])

#for domain in getProcessOutput("terraform output -json").splitlines():
#    cmd = "whmapi1 domainuserdata domain " + domain
#    print(json.loads(getProcessOutput(cmd))['kworker'])
