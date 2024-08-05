resource "google_compute_network" "linux" {
  name                    = "${var.name}-linux"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "linux" {
  name          = "${var.name}-linux-s"
  ip_cidr_range = cidrsubnet("172.30.0.0/23", 4, 1)
  network       = google_compute_network.linux.id
}



resource "google_compute_firewall" "linux-i" {
  name      = "${var.name}-linux-i"
  network   = google_compute_network.linux.id
  direction = "INGRESS"
  source_ranges = concat(
    ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"],
    [for r in var.mgmt_ips : "${r.cidr}"]
  )
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "linux-i-esp" {
  name      = "${var.name}-linux-i-ipsec"
  network   = google_compute_network.linux.id
  direction = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "esp"
  }
}
resource "google_compute_firewall" "linux-i-ike" {
  name      = "${var.name}-linux-i-ike"
  network   = google_compute_network.linux.id
  direction = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }
}



locals {
  private_ip = {
    linux0 = cidrhost(google_compute_subnetwork.linux.ip_cidr_range, 8)
    linux1 = cidrhost(google_compute_subnetwork.linux.ip_cidr_range, 9)
  }
  linux_init_p = {
    linux0 = {
      local_ip  = local.private_ip.linux0
      local_id  = google_compute_address.linux[0].address
      peer_ip   = google_compute_forwarding_rule.ext.ip_address
      vpn_psk   = var.vpn_psk
      lo_ips = [
        "10.1.1.1/25",
        "10.1.1.3/25",
      ]
    }
    linux1 = {
      local_ip  = local.private_ip.linux1
      local_id  = google_compute_address.linux[1].address
      peer_ip   = google_compute_forwarding_rule.ext.ip_address
      vpn_psk   = var.vpn_psk
      lo_ips = [
        "10.1.1.2/25",
        "10.1.1.3/25",
      ]
    }
  }
}

data "cloudinit_config" "linux" {
  count = 2

  gzip          = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = yamlencode({
      write_files = [
        {
          path    = "/etc/swanctl/swanctl.conf"
          content = templatefile("${path.module}/init/swanctl.conf.tfpl", count.index==0 ? local.linux_init_p.linux0 : local.linux_init_p.linux1)
        },
        {
          path    = "/etc/cloud/cloud.cfg.d/99-custom-networking.cfg"
          content = "network: {config: disabled}"
        },
        {
          path    = "/etc/systemd/network/xfrm101.netdev"
          content = <<-EOT
            [NetDev]
            Name=xfrm101
            Kind=xfrm

            [Xfrm]
            InterfaceId=101
            EOT
        },
        {
          path    = "/etc/systemd/network/xfrm101.network"
          content = <<-EOT
            [Match]
            Name=lo

            [Network]
            Xfrm=xfrm101
            EOT
        },
        {
          path    = "/etc/systemd/network/xfrm101-route.network"
          content = <<-EOT
            [Match]
            Name=xfrm101

            [Route]
            Destination=${google_compute_instance.srv0.network_interface[0].network_ip}/32
            Scope=link

            [Route]
            Destination=${google_compute_instance.srv1.network_interface[0].network_ip}/32
            Scope=link
            EOT
        },
        {
          path = "/etc/netplan/90-local.yaml"
          content = yamlencode({
            network = {
              version = 2
              ethernets = {
                eth0 = {
                  dhcp4 = "yes"
                }
              }
              bridges = {
                db0 = {
                  dhcp4      = "no"
                  dhcp6      = "no"
                  accept-ra  = "no"
                  interfaces = []
                  addresses  = count.index==0 ? local.linux_init_p.linux0.lo_ips : local.linux_init_p.linux1.lo_ips
                }
              }
            }
          })
        },
      ]
      runcmd = [
        "netplan apply",
        "swanctl --load-all",
      ]
      packages = [
        "fping",
        "net-tools",
        "strongswan",
        "strongswan-swanctl",
      ]
    })
  }
}

resource "google_compute_address" "linux" {
  count = 2

  name   = "${var.name}-vpn-peer-${count.index}"
  region = var.region
}

resource "random_id" "linux" {
  keepers = {
    ci = data.cloudinit_config.linux[0].id
  }
  byte_length = 3
}


resource "google_compute_instance" "linux" {
  count = 2

  name         = "${var.name}-vpn-peer-${random_id.linux.hex}-${count.index}"
  machine_type = var.srv_type
  zone         = var.zones[count.index]

  metadata = {
    user-data = data.cloudinit_config.linux[count.index].rendered
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.linux.id
    network_ip = count.index==0 ? local.private_ip.linux0 : local.private_ip.linux1
    access_config {
      nat_ip = google_compute_address.linux[count.index].address
    }
  }
}
