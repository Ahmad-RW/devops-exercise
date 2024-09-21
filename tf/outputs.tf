output "fw_vpce" {
  value = tolist(element(module.network_firewall.status, 1).sync_states)[0].attachment[0].endpoint_id
}