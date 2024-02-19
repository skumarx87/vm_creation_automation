
resource "libvirt_volume" "centos7" {
  name = "centos-stable"
  #source = "http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  source = "./CentOS-7-x86_64-GenericCloud.qcow2"
}

resource "libvirt_volume" "centos" {
  name = "centos${count.index}"
  base_volume_id = "${libvirt_volume.centos7.id}"
  count = 4
}

data "template_file" "user_data" {
  template = file("${path.module}/config/cloud_init.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name = "centos${count.index}.iso"
  #local_hostname = "centos${count.index}"
  count = 4
  user_data = "${data.template_file.user_data.rendered}"
}

resource "libvirt_domain" "centos" {
  name = "centos${count.index}"
  disk {
       volume_id = "${element(libvirt_volume.centos.*.id, count.index)}"
  }
  count = 4
  network_interface {
    network_name = "default"
    wait_for_lease = "true"
  }
  cloudinit = "${element(libvirt_cloudinit_disk.commoninit.*.id, count.index)}"
}
output "ip" {
value = "${libvirt_domain.centos[*].network_interface.0.addresses.0}"
}
