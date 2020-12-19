resource "vsphere_tag" "ansible_group_jump" {
  name             = "jump"
  category_id      = vsphere_tag_category.ansible_group_jump.id
}

data "template_file" "jumpbox_userdata" {
  template = file("${path.module}/userdata/jump.userdata")
  vars = {
    pubkey        = file(var.publicKeyFile)
    avisdkVersion = var.jump["avisdkVersion"]
    ansibleVersion = var.ansible["version"]
    vsphere_user  = var.vmc_vsphere_user
    vsphere_password = var.vmc_vsphere_password
    vsphere_server = var.vmc_vsphere_server
    username = var.jump["username"]
    privateKey = var.privateKeyFile
  }
}

resource "vsphere_virtual_machine" "jump" {
  name             = var.jump["name"]
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folderController.path
  network_interface {
                      network_id = data.vsphere_network.networkMgmt.id
  }

  num_cpus = var.jump["cpu"]
  memory = var.jump["memory"]
  wait_for_guest_net_timeout = var.jump["wait_for_guest_net_timeout"]
  guest_id = "guestid-jump"

  disk {
    size             = var.jump["disk"]
    label            = "jump.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.files[1].id
  }

  tags = [
        vsphere_tag.ansible_group_jump.id,
  ]

  vapp {
    properties = {
     hostname    = "jump"
     public-keys = file(var.publicKeyFile)
     user-data   = base64encode(data.template_file.jumpbox_userdata.rendered)
    }
  }
}
