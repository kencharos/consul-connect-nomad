kind = "service-router"
name = "service-a"
routes = [
  {
    match {
      http {
        path_prefix = "/hello_b"
      }
    }
    destination {
      service = "service-b"
    }
  },
  # NOTE: a default catch-all will send unmatched traffic to "service-a"
]