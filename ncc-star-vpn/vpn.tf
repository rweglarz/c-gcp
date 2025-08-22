module "vpns" {
  source   = "../modules/vpc_2_vpc_vpn"
  for_each = toset(local.regions)

  region = each.key
  name   = "${var.name}-${each.key}"

  vpc_a_id   = google_compute_network.fw.id
  vpc_b_id   = google_compute_network.center.id
  vpc_a_name = "fw"
  vpc_b_name = "ncc"
  vpc_a_asn  = 64521
  vpc_b_asn  = 64522
  peering_cidrs = local.region_to_vpn[each.key].peering
  advertised_ip_ranges_a = ["0.0.0.0/0"]
}
