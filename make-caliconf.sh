#!/bin/bash

sudo tee /etc/cni/net.d/10-calico.conf <<EOF > /dev/null
{
    "name": "calico-k8s-network",
    "type": "calico",
    "etcd_authority": "192.168.100.10:2379",
    "log_level": "info",
    "ipam": {
        "type": "calico-ipam"
    }
}
EOF