kind = "service-router"
name = "service_a"
routes = [
  {
    match {
      http {
        path_prefix = "/hello_b"
      }
    }
    destination {
      service = "service_b"
    }
  },
  # NOTE: a default catch-all will send unmatched traffic to "service_a"
]