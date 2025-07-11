output "tunnels" {
  value = {
    "${var.vpc_a_name}--to--${var.vpc_b_name}" = toset([
        google_compute_vpn_tunnel.a_b[0].self_link,
        google_compute_vpn_tunnel.a_b[1].self_link,
    ])
    "${var.vpc_b_name}--to--${var.vpc_a_name}" = toset([
        google_compute_vpn_tunnel.b_a[0].self_link,
        google_compute_vpn_tunnel.b_a[1].self_link,
    ])
  }  
}
