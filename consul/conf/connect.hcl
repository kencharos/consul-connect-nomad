server = true
bootstrap_expect = 1
ports {
    http = 8500
    grpc = 8502
}
addresses {
  http = "0.0.0.0"
}
# set VMs ip
bind_addr = "192.168.33.10"
client_addr = "0.0.0.0"
# set VMs ip
start_join=["192.168.33.10"]
ui = true
connect {
  enabled = true
}
node_name = "server"

