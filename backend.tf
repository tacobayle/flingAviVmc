

resource "vsphere_tag" "ansible_group_backend" {
  name             = "backend"
  category_id      = vsphere_tag_category.ansible_group_backend.id
}


data "template_file" "backend_userdata" {
  count = var.backend["count"]
  template = file("${path.module}/userdata/backend.userdata")
  vars = {
    pubkey       = file(var.publicKeyFile)
  }
}

resource "vsphere_virtual_machine" "backend" {
  count            = var.backend["count"]
  name             = "backend-${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folderApp.path

  network_interface {
                      network_id = data.vsphere_network.networkBackend.id
  }

  num_cpus = var.backend["cpu"]
  memory = var.backend["memory"]
  #wait_for_guest_net_timeout = var.backend["wait_for_guest_net_timeout"]
  wait_for_guest_net_routable = var.backend["wait_for_guest_net_routable"]
  guest_id = "guestid-backend-${count.index}"

  disk {
    size             = var.backend["disk"]
    label            = "backend-${count.index}.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.files[1].id
  }

  tags = [
        vsphere_tag.ansible_group_backend.id,
  ]

  vapp {
    properties = {
     hostname    = "backend-${count.index}"
     public-keys = file(var.publicKeyFile)
     user-data   = base64encode(data.template_file.backend_userdata[count.index].rendered)
   }
 }

}
