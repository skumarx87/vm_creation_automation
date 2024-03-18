###### base Image ########
resource "libvirt_volume" "centos7" {
  name = "${local.env}-centos-stable"
  #source = "http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  source = "./CentOS-7-x86_64-GenericCloud.qcow2"
}

####### Worker configurations #########

resource "libvirt_volume" "kworkercentos" {
  #name = "${local.env}-kworkercentos${count.index}"
  name ="${local.env}-${local.workers_prefix}${count.index}"
  size = "${local.kworker_disk_size}"
  base_volume_id = "${libvirt_volume.centos7.id}"
  count = "${local.kworker_count}"
}

resource "libvirt_cloudinit_disk" "kworkercommoninit" {
  #name = "${local.env}-kworkercentos${count.index}.iso"
  name = "${local.env}-${local.workers_prefix}${count.index}.iso"
  #local_hostname = "kworkercentos${count.index}"
  count = "${local.kworker_count}"
  #user_data = "${data.template_file.worker_user_data.rendered}"
  #user_data = templatefile("${path.module}/config/worker_cloud_init.cfg",{ hostname = "worker",inc = count.index})
  user_data = templatefile("${path.module}/config/worker_cloud_init.cfg",{ hostname = "${local.env}-${local.workers_prefix}${count.index}.${local.host_domain_prefix}",super_user = "${local.super_user}",private_key = "${file(local.super_user_private_key)}" })


}

output "test" {
value = join(" ","${libvirt_domain.kubecluster_kmaster[*].network_interface.0.addresses.0}")
#value = tostring("${libvirt_domain.kubecluster_kmaster[*].network_interface.0.addresses.0}")
}

resource "libvirt_domain" "kubecluster_kworker" {
  depends_on = [libvirt_domain.kubecluster_kmaster]
  name = "${local.env}-${local.workers_prefix}${count.index}"
  memory = "${local.kworker_memory}"
  vcpu = "${local.kworker_cpu}"
  disk {
       volume_id = "${element(libvirt_volume.kworkercentos.*.id, count.index)}"
  }
  count = "${local.kworker_count}"
  network_interface {
    network_name = "default"
    hostname = "${local.env}-${local.workers_prefix}${count.index}.${local.host_domain_prefix}"
    wait_for_lease = "true"
  }
  cloudinit = "${element(libvirt_cloudinit_disk.kworkercommoninit.*.id, count.index)}"

  connection {
      type     = "ssh"
      user     = "ansible"
      private_key = file("/root/.ssh/id_rsa")
      #host = aws_instance.web.public_ip
      host = self.network_interface.0.addresses.0
	}

provisioner "file" {
	source      = "scripts/bootstrap.sh"
	destination = "/tmp/bootstrap.sh"
}

provisioner "file" {
        source      = "scripts/bootstrap_sworker.sh"
        destination = "/tmp/bootstrap_sworker.sh"
}

provisioner "remote-exec" {
	inline = [	
	"chmod +x /tmp/bootstrap.sh",
	"chmod +x /tmp/bootstrap_sworker.sh",
	"sudo /tmp/bootstrap.sh ${local.local_hadoop_user} ${local.local_hadoop_user_password}",
	"sudo /tmp/bootstrap_sworker.sh ${join(" ",libvirt_domain.kubecluster_kmaster[*].network_interface.0.addresses.0)} ${local.local_hadoop_user} ${local.local_hadoop_user_password}"
	#"sudo /tmp/bootstrap_sworker.sh ${libvirt_domain.kubecluster_kmaster[0].network_interface.0.addresses.0}"
	]
}


}


output "kworker" {
value  = tomap({
#for key,ip in libvirt_domain.kubecluster_kworker : libvirt_domain.kubecluster_kworker[key].name => ip.network_interface.0.addresses.0
#for key,ip in libvirt_domain.kubecluster_kworker : ip.network_interface.0.hostname => ip.network_interface.0.addresses.0
for key,ip in libvirt_domain.kubecluster_kworker : ip.network_interface.0.addresses.0 => [ ip.network_interface.0.hostname,libvirt_domain.kubecluster_kworker[key].name ]
})
}

################## Master configuration #########################

resource "libvirt_volume" "kmastercentos" {
  #name = "kmastercentos${count.index}"
  name = "${local.env}-${local.masters_prefix}${count.index}"
  size = "${local.kmaster_disk_size}"
  base_volume_id = "${libvirt_volume.centos7.id}"
  count = "${local.kmaster_count}"
}

resource "libvirt_cloudinit_disk" "kmastercommoninit" {
  #name = "kmastercentos${count.index}.iso"
  name = "${local.env}-${local.masters_prefix}${count.index}.iso"
  count = "${local.kmaster_count}" 
  #user_data = "${data.template_file.master_user_data.rendered}"
  user_data = templatefile("${path.module}/config/master_cloud_init.cfg",{ hostname = "${local.env}-${local.masters_prefix}${count.index}.${local.host_domain_prefix}",super_user = "${local.super_user}",private_key = "${file(local.super_user_private_key)}" })
}

resource "libvirt_domain" "kubecluster_kmaster" {

  memory = "${local.kmaster_memory}"
  vcpu = "${local.kmaster_cpu}"

  name = "${local.env}-${local.masters_prefix}${count.index}"
  disk {
       volume_id = "${element(libvirt_volume.kmastercentos.*.id, count.index)}"
  }
  count = "${local.kmaster_count}"
  network_interface {
    network_name = "default"
    hostname = "${local.env}-${local.masters_prefix}${count.index}.${local.host_domain_prefix}"
    wait_for_lease = "true"
  }
  cloudinit = "${element(libvirt_cloudinit_disk.kmastercommoninit.*.id, count.index)}"

  connection {
      type     = "ssh"
      user     = "ansible"
      private_key = file("/root/.ssh/id_rsa")
      #host = aws_instance.web.public_ip
      host = self.network_interface.0.addresses.0
        }

provisioner "file" {
        source      = "scripts/bootstrap.sh"
        destination = "/tmp/bootstrap.sh"
}

provisioner "file" {
        source      = "scripts/bootstrap_smaster.sh"
        destination = "/tmp/bootstrap_smaster.sh"
}

provisioner "remote-exec" {
        inline = [
        "chmod +x /tmp/bootstrap.sh",
        "chmod +x /tmp/bootstrap_smaster.sh",
        "sudo /tmp/bootstrap.sh ${local.local_hadoop_user} ${local.local_hadoop_user_password}",
        "sudo /tmp/bootstrap_smaster.sh ${local.local_hadoop_user} ${local.local_hadoop_user_password}"
        ]
}

}

output "kmaster" {
value  = tomap({
#for key,ip in libvirt_domain.kubecluster_kmaster : ip.network_interface.0.hostname => ip.network_interface.0.addresses.0
for key,ip in libvirt_domain.kubecluster_kmaster : ip.network_interface.0.addresses.0 => [ ip.network_interface.0.hostname,libvirt_domain.kubecluster_kmaster[key].name ]
})
}

/*
###### Null resource for updating Host file #####

resource "null_resource" "update_host" {
	depends_on = [libvirt_domain.kubecluster_kworker]
	provisioner "local-exec" {
	command = "python3 scripts/update_host.py ${local.super_user} ${local.env} ${local.host_domain_prefix} ${local.masters_prefix} ${local.workers_prefix} ${join(",",libvirt_domain.kubecluster_kmaster[*].network_interface.0.addresses.0)} ${join(",",libvirt_domain.kubecluster_kworker[*].network_interface.0.addresses.0)}"	

	}
}

*/
