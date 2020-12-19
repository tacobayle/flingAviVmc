resource "vsphere_tag" "ansible_group_opencart" {
  name             = "opencart"
  category_id      = vsphere_tag_category.ansible_group_opencart.id
}

data "template_file" "opencart_userdata" {
  count            = var.opencart["count"]
  template = file("${path.module}/userdata/opencart.userdata")
  vars = {
    pubkey       = file(var.publicKeyFile)
    opencartDownloadUrl = var.opencart["opencartDownloadUrl"]
    domainName = var.avi_gslb["domain"]
  }
}

resource "vsphere_virtual_machine" "opencart" {
  count            = var.opencart["count"]
  name             = "opencart-${count.index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folderApp.path

  network_interface {
                      network_id = data.vsphere_network.networkBackend.id
  }


  num_cpus = var.opencart["cpu"]
  memory = var.opencart["memory"]
  wait_for_guest_net_timeout = var.opencart["wait_for_guest_net_timeout"]
  #wait_for_guest_net_routable = var.opencart["wait_for_guest_net_routable"]
  guest_id = "guestid-opencart-${count.index}"

  disk {
    size             = var.opencart["disk"]
    label            = "opencart-${count.index}.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.files[1].id
  }

  tags = [
        vsphere_tag.ansible_group_opencart.id,
  ]

  vapp {
    properties = {
     hostname    = "opencart-${count.index}"
     public-keys = file(var.publicKeyFile)
     user-data   = base64encode(data.template_file.opencart_userdata[count.index].rendered)
   }
 }

}
