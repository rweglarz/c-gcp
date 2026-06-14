resource "google_compute_address" "sdgw_pub" {
  for_each = toset(["sdgw1", "sdgw2"])
  name     = "${var.name}-${each.key}-pub"
}

locals {
  sdgw_configs = {
    sdgw1 = {
      local_ip                = local.sdgw_ips.sdgw1
      local_id                = google_compute_address.sdgw_pub["sdgw1"].address
      peer_ip                 = google_compute_ha_vpn_gateway.remote.vpn_interfaces[0].ip_address
      if_id                   = 101
      bgp_source_ip           = local.tunnel_ips.sdgw1.sdgw_ip
      peer_bgp_ip             = local.tunnel_ips.sdgw1.router_ip
      local_asn               = local.asn.sdgw1
      peer_remote_asn         = local.asn.remote_router
      peer_local_ip_primary   = local.vpn_router_ips.primary
      peer_local_ip_redundant = local.vpn_router_ips.redundant
      peer_local_asn          = local.asn.vpn_router
    }
    sdgw2 = {
      local_ip                = local.sdgw_ips.sdgw2
      local_id                = google_compute_address.sdgw_pub["sdgw2"].address
      peer_ip                 = google_compute_ha_vpn_gateway.remote.vpn_interfaces[1].ip_address
      if_id                   = 102
      bgp_source_ip           = local.tunnel_ips.sdgw2.sdgw_ip
      peer_bgp_ip             = local.tunnel_ips.sdgw2.router_ip
      local_asn               = local.asn.sdgw2
      peer_remote_asn         = local.asn.remote_router
      peer_local_ip_primary   = local.vpn_router_ips.primary
      peer_local_ip_redundant = local.vpn_router_ips.redundant
      peer_local_asn          = local.asn.vpn_router
    }
  }
}

data "cloudinit_config" "sdgw" {
  for_each      = local.sdgw_configs
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          path = "/etc/bird/bird.conf"
          content = templatefile("${path.module}/init/bird.conf.tfpl", {
            router_id               = each.value.local_ip
            local_asn               = each.value.local_asn
            bgp_source_ip           = each.value.bgp_source_ip
            peer_bgp_ip             = each.value.peer_bgp_ip
            peer_remote_asn         = each.value.peer_remote_asn
            local_ip                = each.value.local_ip
            peer_local_ip_primary   = each.value.peer_local_ip_primary
            peer_local_ip_redundant = each.value.peer_local_ip_redundant
            peer_local_asn          = each.value.peer_local_asn
          })
        },
        {
          path = "/etc/swanctl/swanctl.conf"
          content = templatefile("${path.module}/init/swanctl.conf.tfpl", {
            local_ip = each.value.local_ip
            peer_ip  = each.value.peer_ip
            local_id = each.value.local_id
            if_id    = each.value.if_id
            vpn_psk  = random_id.vpn_psk.hex
          })
        },
        {
          path        = "/var/lib/cloud/scripts/per-once/bird.sh"
          content     = file("${path.module}/init/bird.sh")
          permissions = "0744"
        },
        {
          path        = "/var/lib/cloud/scripts/per-boot/vpn.sh"
          content     = templatefile("${path.module}/init/vpn.sh.tfpl", {
            bgp_source_ip = each.value.bgp_source_ip
            if_id         = each.value.if_id
            peer_bgp_ip   = each.value.peer_bgp_ip
          })
          permissions = "0744"
        }
      ]
      runcmd = [
        "systemctl mask google-shutdown-scripts.service",
        "sysctl -w net.ipv4.ip_forward=1",
        "echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf",
        "/var/lib/cloud/scripts/per-boot/vpn.sh",
        "swanctl --load-all",
      ]
      packages = [
        "bird2",
        "fping",
        "net-tools",
        "strongswan-charon",
        "strongswan-swanctl",
      ]
    })
  }
}

resource "google_compute_instance" "sdgw" {
  for_each     = local.sdgw_configs
  name         = "${var.name}-${each.key}"
  machine_type = var.srv_machine_type
  zone         = var.zone

  can_ip_forward            = true
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpn.id
    network_ip = each.value.local_ip
    
    # Associate the allocated static external public IP
    access_config {
      nat_ip = google_compute_address.sdgw_pub[each.key].address
    }
  }

  service_account {
    email  = google_service_account.sdgw_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    user-data = data.cloudinit_config.sdgw[each.key].rendered
  }

  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image
    ]
  }
}
