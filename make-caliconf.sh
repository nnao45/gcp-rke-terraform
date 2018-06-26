#!/bin/bash

cat >/etc/cni/net.d/10-calico.conf <<EOF
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