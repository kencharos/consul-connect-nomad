# https://learn.hashicorp.com/consul/developer-mesh/connect-envoy
# docker build -t consul-envoy .
# use with --init option
FROM consul:latest
FROM envoyproxy/envoy:v1.11.2
COPY --from=0 /bin/consul /bin/consul
ENTRYPOINT ["consul", "connect", "envoy"]
