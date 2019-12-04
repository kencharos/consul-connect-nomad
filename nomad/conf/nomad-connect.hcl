#datacenter = "{{ nomad_datacenter }}"
bind_addr = "0.0.0.0"
data_dir = "/tmp/nomad/data"
server {
  enabled = true
  bootstrap_expect = 1
}
client {
  enabled = true
  node_class = "test"
}
consul {
  address             = "127.0.0.1:8500"
  server_service_name = "nomad"
  client_service_name = "nomad-client"
  auto_advertise      = true
  server_auto_join    = true
  client_auto_join    = true
}