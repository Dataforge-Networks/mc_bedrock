terraform {
  required_providers {
      libvirt = {
          source = "dmacvicar/libvirt"
      }
  }
}

provider "libvirt" {
    uri = "qemu+ssh://wfisher@server1/system"
}

resource "libvirt_volume" "fedora34-server" {
    name = "fedora34-server-image"
    pool = "default"
    source = "./Fedora-Cloud-Base-34-1.2.x86_64.qcow2"
    format = "qcow2" 
}

resource "libvirt_volume" "fedora_resized" {
    name = "disk"
    base_volume_id = libvirt_volume.fedora34-server.id
    pool = "default"
    size = 10000000000
}

data "template_file" "user_data" {
    template = file("${path.module}/cloud_init.cfg")
}

data "template_file" "network_config" {
    template = file("${path.module}/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit" {
    name = "commoninit.iso"
    user_data = data.template_file.user_data.rendered
    network_config = data.template_file.network_config.rendered
}

resource "libvirt_domain" "mc-bedrock" {
    name = "mc-bedrock"
    memory = "2048"
    vcpu = "1"

    cloudinit = libvirt_cloudinit_disk.commoninit.id

    network_interface {
      bridge = "br0"
    }

    disk {
        volume_id = "${libvirt_volume.fedora_resized.id}"
    }

    console {
        type = "pty"
        target_type = "serial"
        target_port = "0"
    }

    graphics {
        type = "spice"
        listen_type = "address"
        autoport = true
    }
}