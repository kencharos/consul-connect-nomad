Consul Connect, L7 traffic manager, nomad connect integration trying

+ [x] consul connect
+ [x] L7 traffic manager
+ [x] nomad integration

## pre requirements

+ linux machine or Vagrant.
+ consul 1.6
+ nomad 0.10

### build services

run `bulidimage.sh` in services.

### run consul

NOTICE: consul connect envoy proxy can run only host network.
see also https://learn.hashicorp.com/consul/developer-mesh/connect-envoy

```
# note. does not use vagrant share folder for data-dir.
consul agent --config-dir=consul/conf --data-dir=/tmp/consul/data &
```

## try consul connect basic

run services

```
docker run --rm --name service_a -e "SIDECAR_URL=http://localhost:9000" --network host -d service_a
docker run --rm --name service_b -d --network host  service_b
docker run --rm --name service_b_2 -e "PORT=3002" -e "APP_ID=2" -d --network host  service_b
```

service registration

```
curl -X PUT http://localhost:8500/v1/agent/service/register -d @service_a.json
curl -X PUT http://localhost:8500/v1/agent/service/register -d @service_b.json
curl -X PUT http://localhost:8500/v1/agent/service/register -d @service_b2.json
```

run sidecars. sidecar registerd as consul services as sidecar-proxy

```
docker run --init --rm -d --network host --name sidecar_a consul-envoy -sidecar-for service-a -admin-bind 0.0.0.0:19000 
docker run --init --rm -d --network host --name sidecar_b consul-envoy -sidecar-for service-b -admin-bind 0.0.0.0:19001 
docker run --init --rm -d --network host --name sidecar_b_2 consul-envoy -sidecar-for service-b_2 -admin-bind 0.0.0.0:19002
```

```
curl localhost:3000/hello_a
# ok
```


intention edit.

```
consul intention create -deny service-a service-b
curl localhost:3000/hello_a
# NG

consul intention delete service_a service_b

```

### memo

envoy proxy is TCP proxy in envoy.

```
{
    version_info: "00000001",
    listener: {
        name: "service_b:127.0.0.1:9000",
        address: {
            socket_address: {
            address: "127.0.0.1",
            port_value: 9000
        }
    },
    filter_chains: [
        {
            filters: [
            {
                name: "envoy.tcp_proxy",
                config: {
                    cluster: "service_b.default.dc1.internal.d0b3ab02-b74d-c383-cb72-96d738b8f10e.consul",
                    stat_prefix: "upstream_service_b_tcp"
                }
            }
            ]
        }
    ]
```

`service_b.default.dc1.internal.d0b3ab02-b74d-c383-cb72-96d738b8f10e.consul` is forward to target envoy 2100x port listener.
(if multi service same name, connection distributed each envoys.)
this listener has `envoy.ext_authz` filter that connect to consul. Then, check OK. forward to local app cluster

### custom envoy config

if config envoy log or tracing, and other, 
see  https://www.consul.io/docs/connect/proxies/envoy.html#advanced-configuration


## try L7 traffic manager.

### service-router

router adding http path base routing to sidecar envoy.

if access `/hello_b` in service_a, route to service_b in envoy

```
# change upstream in proxy
## port 9000 upstream to own sidecar envoy.
curl -X PUT http://localhost:8500/v1/agent/service/register -d @service_a_in_l7.json
```

```
# indicate service use http.
consul config write l7/service_default.hcl
consul config write l7/service_default2.hcl
consul config write l7/service_a_router.hcl

curl localhost:3000/hello_a
```

#### memo 
service-router creates envoy dynamic route config.

```
dynamic_route_configs: [
{
    version_info: "00000008",
    route_config: {
    name: "service_a",
    virtual_hosts: [
    {
        name: "service_a",
        domains: ["*"],
        routes: [
            {
                match: {
                    prefix: "/hello_b"
                },
                route: {
                    cluster: "service_b.default.dc1.internal.7f18c657-5cb0-a7e2-d079-50b9e88ce6c3.consul"
                }
            },
            {
                match: {
                    prefix: "/"
                },
                route: {
                    cluster: "service_a.default.dc1.internal.7f18c657-5cb0-a7e2-d079-50b9e88ce6c3.consul"
                }
            }
        ]
    }
],
```


### service splitter and resolver

resolver and splitter add customize routing rule to envoy's route config.

```
consul config write l7/service_b_resolver.hcl
consul config write l7/service_b_splitter.hcl

curl localhost:3000/hello_a
```

change splitter weight and conrig write.

#### memo

splitter add route config weighted_clusters

```
routes: [
{
    match: {
        prefix: "/"
    },
    route: {
        weighted_clusters: {
            clusters: [
                {
                    name: "v1.service_b.default.dc1.internal.7f18c657-5cb0-a7e2-d079-50b9e88ce6c3.consul",
                    weight: 8500
                },
                {
                    name: "v2.service_b.default.dc1.internal.7f18c657-5cb0-a7e2-d079-50b9e88ce6c3.consul",
                    weight: 1500
                }
            ],
            total_weight: 10000
        }
        }
    }
]
```

## mesh gateway 

https://www.consul.io/docs/connect/mesh_gateway.html

no trying here. but mesh gateway is public edge envoy-proxy (connect envoy proxy only use internal network, direct access cannot allow for mTLS.). config are almost same.


## nomad connect integration

run nomad server and client.
NOTE, for CNI use, nomad run as root permession, and consul command exsists in $PATH

```
sudo cp /usr/local/bin/consul /usr/bin/consul
sudo /usr/local/bin/nomad agent -config=nomad/conf &
```

according to https://www.nomadproject.io/guides/integrations/consul-connect/index.html

install CNI plugin and set network parameter

```
curl -L -o cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v0.8.1/cni-plugins-linux-amd64-v0.8.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz
```
set following　to /etc/sysctl.d/99-sysctl.conf
```
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
```

```
sudo sysctl -p
```

if continue from previous section, remove all service and stop all containers.

```
consul services deregister --id=service-a
consul services deregister --id=service-a-sidecar-proxy
consul services deregister --id=service-b
consul services deregister --id=service-b_2
consul services deregister --id=service-b-sidecar-proxy
consul services deregister --id=service-b_2-sidecar-proxy

docker stop service_a service_b service_b_2 sidecar_a sidecar_b sidecar_b_2
```

if docker image does not exisits in remote registory, 
export local image to tar.

```
docker save service_a > /tmp/service_a.tar
docker save service_b > /tmp/service_b.tar
# run localhost http server for artifact download
docker run -d \
    -v /tmp:/web \
    -p 8080:8080 \
    halverneus/static-file-server:latest
```

submit nomad job

```
nomad job run nomad/service_a.job
nomad job run nomad/service_b.job

curl localhost:3000/hello_a
```

envoy proxy that run by nomad use with L7 traffic manager.

### memo

in service_a container, enviroment variable `SIDECAR_URL` is `127.0.0.1:9901`. It means that nomad networking is able to connect with localhost between sidecar and app container by CNI.

these container running

```
CONTAINER ID        IMAGE                                      COMMAND                  CREATED             STATUS              PORTS                    NAMES
403c1ada41e4        service_a                                  "docker-entrypoint.s…"   8 minutes ago       Up 8 minutes                                 service-a-185fba06-769d-709b-424d-82fd7c2ae2ce
d790eab98035        envoyproxy/envoy:v1.11.2                   "/docker-entrypoint.…"   8 minutes ago       Up 8 minutes                                 connect-proxy-service-a-185fba06-769d-709b-424d-82fd7c2ae2ce
a80ca3324134        gcr.io/google_containers/pause-amd64:3.0   "/pause"                 8 minutes ago       Up 8 minutes                                 nomad_init_185fba06-769d-709b-424d-82fd7c2ae2ce
1977b3e0ba9d        service_b                                  "docker-entrypoint.s…"   14 minutes ago      Up 14 minutes                                service-b-8dd8a9f7-3a6a-9db8-323f-b96d8fbb886b
20e9c8aef0bf        envoyproxy/envoy:v1.11.2                   "/docker-entrypoint.…"   14 minutes ago      Up 14 minutes                                connect-proxy-service-b-8dd8a9f7-3a6a-9db8-323f-b96d8fbb886b
a2541ff0b97a        gcr.io/google_containers/pause-amd64:3.0   "/pause"                 14 minutes ago      Up 14 minutes                                nomad_init_8dd8a9f7-3a6a-9db8-323f-b96d8fbb886b
66ae489a2fa1        service_b                                  "docker-entrypoint.s…"   14 minutes ago      Up 14 minutes                                service-b-55a64c29-d565-1385-7f16-790166faea6a
4b47ebdbee03        envoyproxy/envoy:v1.11.2                   "/docker-entrypoint.…"   15 minutes ago      Up 15 minutes                                connect-proxy-service-b-55a64c29-d565-1385-7f16-790166faea6a
67d5e2aaf657        gcr.io/google_containers/pause-amd64:3.0   "/pause"                 15 minutes ago      Up 15 minutes                                nomad_init_55a64c29-d565-1385-7f16-790166faea6a
```
