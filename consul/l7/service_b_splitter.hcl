
kind = "service-splitter"
name = "service-b"
splits = [
  {
    weight         = 85
    service_subset = "v1"
  },
  {
    weight         = 15
    service_subset = "v2"
  },
]