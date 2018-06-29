#!/bin/bash

sudo mkdir -p /etc/cni/net.d
sudo tee /etc/cni/net.d/10-calico.conf <<EOF > /dev/null
{
    "name": "calico-k8s-network",
    "type": "calico",
    "etcd_authority": "10.45.0.2:2379",
    "log_level": "info",
    "ipam": {
        "type": "calico-ipam"
    }
}
EOF
sudo tee /etc/systemd/system/rktlet.service <<EOF > /dev/null
[Unit]
Description=rktlet: The rkt implementation of a Kubernetes Container Runtime
Documentation=https://github.com/kubernetes-incubator/rktlet/tree/master/docs

[Service]
ExecStart=/usr/local/bin/rktlet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
sudo swapoff -a
sudo yum install -y etcd docker kubernetes-node curl vim wget
sudo yum install -y jq
sudo mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf.old
sudo sh -c 'echo ETCD_NAME=default >> /etc/etcd/etcd.conf'
sudo sh -c 'echo ETCD_DATA_DIR=/var/lib/etcd/default.etcd >> /etc/etcd/etcd.conf'
sudo sh -c 'echo ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379 >> /etc/etcd/etcd.conf'
sudo sh -c 'echo ETCD_ADVERTISE_CLIENT_URLS=http://10.45.0.3:2379 >> /etc/etcd/etcd.conf'
sudo mv /etc/hosts /etc/hosts.old
sudo sh -c 'echo k8s-master 10.45.0.2 >> /etc/hosts'
sudo sh -c 'echo k8s-node1 10.45.0.3 >> /etc/hosts'
sudo sh -c 'echo k8s-node2 10.45.0.4 >> /etc/hosts'
sudo systemctl enable etcd
sudo systemctl start etcd
wget https://github.com/rkt/rkt/releases/download/v1.30.0/rkt-v1.30.0.tar.gz
tar xzvf rkt-v1.30.0.tar.gz
sudo mv rkt-v1.30.0/rkt /usr/local/bin/rkt
wget https://github.com/kubernetes-incubator/rktlet/releases/download/v0.1.0/rktlet-v0.1.0.tar.gz
tar xzvf rktlet-v0.1.0.tar.gz
sudo mv rktlet-v0.1.0/rktlet /usr/local/bin/rktlet
sudo systemctl enable rktlet
sudo systemctl start rktlet
sudo mv /etc/kubernetes/config /etc/kubernetes/config.old
sudo mv /etc/kubernetes/kubelet /etc/kubernetes/kubelet.old
sudo mv /etc/kubernetes/proxy /etc/kubernetes/proxy.old
sudo sh -c 'echo KUBE_LOGTOSTDERR=--logtostderr=true  >> /etc/kubernetes/config'
sudo sh -c 'echo KUBE_LOG_LEVEL=--v=0  >> /etc/kubernetes/config'
sudo sh -c 'echo KUBE_ALLOW_PRIV=--allow-privileged=false  >> /etc/kubernetes/config'
sudo sh -c 'echo KUBE_MASTER=--master=http://10.45.0.2:8080  >> /etc/kubernetes/config'
sudo sh -c 'echo KUBELET_ADDRESS=--address=0.0.0.0  >> /etc/kubernetes/kubelet'
sudo sh -c 'echo KUBELET_HOSTNAME=  >> /etc/kubernetes/kubelet'
sudo sh -c 'echo KUBELET_API_SERVER=--api-servers=http://10.45.0.2:8080  >> /etc/kubernetes/kubelet'
sudo sh -c 'echo KUBELET_ARGS=--network-plugin=cni --network-plugin-dir=/etc/cni/net.d  --cgroup-driver=systemd --container-runtime=remote --container-runtime-endpoint=/var/run/rktlet.sock --image-service-endpoint=/var/run/rktlet.sock>> /etc/kubernetes/kubelet'
sudo sh -c 'echo KUBE_PROXY_ARGS=--proxy-mode=iptables  >> /etc/kubernetes/proxy'
sudo systemctl enable kube-proxy
sudo systemctl enable kubelet
sudo systemctl start kube-proxy
sudo systemctl start kubelet
sudo mkdir -p /var/run/calico
sudo mkdir -p /var/log/calico
sudo mkdir -p /opt/bin
sudo mkdir -p /etc/rkt/net.d
sudo wget -N -P /var/lib/rkt/ https://github.com/rkt/rkt/releases/download/v1.30.0/stage1-fly-1.30.0-linux-amd64.aci
sudo /usr/local/bin/rkt run --stage1-path=/var/lib/rkt/stage1-fly-1.30.0-linux-amd64.aci \
  --set-env=ETCD_ENDPOINTS=http://10.45.0.2:2379 \
  --set-env=IP=autodetect \
  --insecure-options=image \
  --volume=birdctl,kind=host,source=/var/run/calico,readOnly=false \
  --mount=volume=birdctl,target=/var/run/calico \
  --volume=mods,kind=host,source=/lib/modules,readOnly=false  \
  --mount=volume=mods,target=/lib/modules \
  --volume=logs,kind=host,source=/var/log/calico,readOnly=false \
  --mount=volume=logs,target=/var/log/calico \
  --net=host \
  quay.io/calico/node:v2.6.10 &
sudo wget -O /usr/local/bin/calicoctl https://github.com/projectcalico/calicoctl/releases/download/v1.6.4/calicoctl
sudo chmod +x /usr/local/bin/calicoctl
sudo wget -N -P /etc/rkt/net.d https://github.com/projectcalico/cni-plugin/releases/download/v1.11.6/calico
sudo wget -N -P /etc/rkt/net.d https://github.com/projectcalico/cni-plugin/releases/download/v1.11.6/calico-ipam
sudo chmod +x /etc/rkt/net.d/calico /etc/rkt/net.d/calico-ipam



#"sudo sh -c 'echo OPTIONS= >> /etc/sysconfig/docker'
#"sudo sh -c 'echo DOCKER_CERT_PATH=/etc/docker >> /etc/sysconfig/docker'
#"sudo sh -c 'echo DOCKER_STORAGE_PATH=\"-s overlay\" >> /etc/sysconfig/docker-storage'
#"sudo systemctl enable docker
#"sudo systemctl start docker