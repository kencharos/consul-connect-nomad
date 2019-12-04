#!/bin/sh

docker build -t service_a:latest service_a
docker build -t service_b:latest service_b
docker build -t consul-envoy consul-envoy
