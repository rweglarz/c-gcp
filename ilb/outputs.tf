output mgmt_nat {
  value = google_compute_address.cloud_nat.address 
}
output jump_host {
  value = google_compute_address.jumphost.address 
}

output "fw_private_vpc_id" {
  value = { for k,v in google_compute_network.private: k=> v.id }
}
