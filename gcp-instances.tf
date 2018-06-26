resource "google_compute_instance" "k8s-master" {
  name         = "k8s-master"
  machine_type = "n1-standard-2"
  zone         = "asia-northeast1-c"
  description  = "k8s-master"
  tags         = ["k8s-master", "k8s"]

  depends_on = ["google_compute_firewall.k8s-firewall"]

  // Dockerのインストール & ubuntuユーザーをdockerグループに追加
  provisioner "remote-exec" {
    connection {
      user        = "${var.gce_ssh_user}"
      private_key = "${file(var.gce_ssh_secret_key_file)}"
    }

    inline = [
      "sudo swapoff -a",
      "sudo yum install -y etcd docker kubernetes-master curl vim wget",
      "sudo yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm",
      "sudo yum install -y jq",
      "sudo mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf.old",
      "sudo sh -c 'echo ETCD_NAME=default >> /etc/etcd/etcd.conf'",
      "sudo sh -c 'echo ETCD_DATA_DIR=/var/lib/etcd/default.etcd >> /etc/etcd/etcd.conf'",
      "sudo sh -c 'echo ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379 >> /etc/etcd/etcd.conf'",
      "sudo sh -c 'echo ETCD_ADVERTISE_CLIENT_URLS=http://10.45.0.2:2379 >> /etc/etcd/etcd.conf'",
      "sudo mv /etc/hosts /etc/hosts.old",
      "sudo sh -c 'echo k8s-master 10.45.0.2 >> /etc/hosts'",
      "sudo sh -c 'echo k8s-node1 10.45.0.3 >> /etc/hosts'",
      "sudo sh -c 'echo k8s-node2 10.45.0.4 >> /etc/hosts'",
      "sudo systemctl enable etcd",
      "sudo systemctl start etcd",
      "sudo sh -c 'echo OPTIONS= >> /etc/sysconfig/docker'",
      "sudo sh -c 'echo DOCKER_CERT_PATH=/etc/docker >> /etc/sysconfig/docker'",
      "sudo sh -c 'echo DOCKER_STORAGE_PATH=\"-s overlay\" >> /etc/sysconfig/docker-storage'",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo mkdir -p /opt/calico/bin",
      "sudo wget https://github.com/projectcalico/calico-containers/releases/download/v0.19.0/calicoctl -P /opt/calico/bin",
      "sudo chmod +x /opt/calico/bin/calicoctl",
      "sudo sh -c 'echo PATH=$PATH:$HOME/bin:/opt/calico/bin' >> ~/.bash_profile",
      "sudo ETCD_AUTHORITY=127.0.0.1:2379 /opt/calico/bin/calicoctl node --ip=10.45.0.2",
      "/opt/calico/bin/calicoctl pool add 172.16.0.0/16",
      "/opt/calico/bin/calicoctl pool remove 192.168.0.0/16",
      "sudo mv /etc/kubernetes/apiserver /etc/kubernetes/apiserver.old",
      "sudo sh -c 'echo KUBE_API_ADDRESS=--insecure-bind-address=0.0.0.0  >> /etc/kubernetes/apiserver'",
      "sudo sh -c 'echo KUBE_ETCD_SERVERS=--etcd-servers=http://127.0.0.1:2379  >> /etc/kubernetes/apiserver'",
      "sudo sh -c 'echo KUBE_SERVICE_ADDRESSES=--service-cluster-ip-range=10.0.100.0/24  >> /etc/kubernetes/apiserver'",
      "sudo sh -c 'echo KUBE_ADMISSION_CONTROL=  >> /etc/kubernetes/apiserver'",
      "sudo sh -c 'echo KUBE_API_ARGS=  >> /etc/kubernetes/apiserver'",
      "sudo systemctl enable kube-apiserver",
      "sudo systemctl enable kube-controller-manager",
      "sudo systemctl enable kube-scheduler",
      "sudo systemctl start kube-apiserver",
      "sudo systemctl start kube-controller-manager",
      "sudo systemctl start kube-scheduler",
    ]
  }

  boot_disk {
    initialize_params {
      size  = "50"
      image = "centos-7-v20180611"
    }
  }

  metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  network_interface {
    access_config {
      //Ephemeral IP
    }

    subnetwork = "${google_compute_subnetwork.k8s-subnet.name}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro", "bigquery", "monitoring"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }
}

resource "google_compute_instance" "k8s-node1" {
  name         = "k8s-node1"
  machine_type = "n1-standard-1"
  zone         = "asia-northeast1-c"
  description  = "k8s-node"
  tags         = ["k8s-node", "k8s"]

  depends_on = ["google_compute_firewall.k8s-firewall", "google_compute_instance.k8s-master"]

  // Dockerのインストール & ubuntuユーザーをdockerグループに追加
  provisioner "remote-exec" {
    connection {
      user        = "${var.gce_ssh_user}"
      private_key = "${file(var.gce_ssh_secret_key_file)}"
    }

    script = "make-caliconf.sh"

    inline = [
      "sudo swapoff -a",
      "sudo yum install -y etcd docker kubernetes-node curl vim wget",
      "sudo yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm",
      "sudo yum install -y jq",
      "sudo mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf.old",
      "sudo sh -c 'echo ETCD_NAME=default >> /etc/etcd/etcd.conf'",
      "sudo sh -c 'echo ETCD_DATA_DIR=/var/lib/etcd/default.etcd >> /etc/etcd/etcd.conf'",
      "sudo sh -c 'echo ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379 >> /etc/etcd/etcd.conf'",
      "sudo sh -c 'echo ETCD_ADVERTISE_CLIENT_URLS=http://10.45.0.3:2379 >> /etc/etcd/etcd.conf'",
      "sudo mv /etc/hosts /etc/hosts.old",
      "sudo sh -c 'echo k8s-master 10.45.0.2 >> /etc/hosts'",
      "sudo sh -c 'echo k8s-node1 10.45.0.3 >> /etc/hosts'",
      "sudo sh -c 'echo k8s-node2 10.45.0.4 >> /etc/hosts'",
      "sudo systemctl enable etcd",
      "sudo systemctl start etcd",
      "sudo sh -c 'echo OPTIONS= >> /etc/sysconfig/docker'",
      "sudo sh -c 'echo DOCKER_CERT_PATH=/etc/docker >> /etc/sysconfig/docker'",
      "sudo sh -c 'echo DOCKER_STORAGE_PATH=\"-s overlay\" >> /etc/sysconfig/docker-storage'",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo mkdir -p /opt/calico/bin",
      "sudo wget https://github.com/projectcalico/calico-containers/releases/download/v0.19.0/calicoctl -P /opt/calico/bin",
      "sudo chmod +x /opt/calico/bin/calicoctl",
      "sudo sh -c 'echo PATH=$PATH:$HOME/bin:/opt/calico/bin' >> ~/.bash_profile",
      "sudo ETCD_AUTHORITY=10.45.0.2:2379 /opt/calico/bin/calicoctl node --ip=10.45.0.3",
      "sudo mv /etc/kubernetes/config /etc/kubernetes/config.old",
      "sudo mv /etc/kubernetes/kubelet /etc/kubernetes/kubelet.old",
      "sudo mv /etc/kubernetes/proxy /etc/kubernetes/proxy.old",
      "sudo sh -c 'echo KUBE_LOGTOSTDERR=--logtostderr=true  >> /etc/kubernetes/config'",
      "sudo sh -c 'echo KUBE_LOG_LEVEL=--v=0  >> /etc/kubernetes/config'",
      "sudo sh -c 'echo KUBE_ALLOW_PRIV=--allow-privileged=false  >> /etc/kubernetes/config'",
      "sudo sh -c 'echo KUBE_MASTER=--master=http://10.45.0.2:8080  >> /etc/kubernetes/config'",
      "sudo sh -c 'echo KUBELET_ADDRESS=--address=0.0.0.0  >> /etc/kubernetes/kubelet'",
      "sudo sh -c 'echo KUBELET_HOSTNAME=  >> /etc/kubernetes/kubelet'",
      "sudo sh -c 'echo KUBELET_API_SERVER=--api-servers=http://10.45.0.2:8080  >> /etc/kubernetes/kubelet'",
      "sudo sh -c 'echo KUBELET_ARGS=--network-plugin=cni --network-plugin-dir=/etc/cni/net.d  >> /etc/kubernetes/kubelet'",
      "sudo sh -c 'echo KUBE_PROXY_ARGS=--proxy-mode=iptables  >> /etc/kubernetes/proxy'",
      "sudo mkdir -p /etc/cni/net.d",

      #"sudo sh -c 'echo '{\"name\": \"calico-k8s-network\", \"type\": \"calico\", \"etcd_authority\": \"10.45.0.2:2379\", \"log_level\": \"info\", \"ipam\": {\"type\": \"calico-ipam\"}}' >> /etc/cni/net.d/10-calico.conf'",
      "sudo wget https://github.com/projectcalico/calico-cni/releases/download/v1.3.0/calico -P /opt/calico/bin",

      "sudo sh -c 'chmod +x /opt/calico/bin/calico'",
      "sudo systemctl enable kube-proxy",
      "sudo systemctl enable kubelet",
      "sudo systemctl start kube-proxy",
      "sudo systemctl start kubelet",
    ]
  }

  boot_disk {
    initialize_params {
      size  = "50"
      image = "centos-7-v20180611"
    }
  }

  metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  network_interface {
    access_config {
      //Ephemeral IP
    }

    subnetwork = "${google_compute_subnetwork.k8s-subnet.name}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro", "bigquery", "monitoring"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }
}

resource "google_compute_instance" "k8s-node2" {
  name         = "k8s-node2"
  machine_type = "n1-standard-1"
  zone         = "asia-northeast1-c"
  description  = "k8s-node"
  tags         = ["k8s-node", "k8s"]

  depends_on = ["google_compute_firewall.k8s-firewall", "google_compute_instance.k8s-master", "google_compute_instance.k8s-node1"]

  // Dockerのインストール & ubuntuユーザーをdockerグループに追加
  provisioner "remote-exec" {
    connection {
      user        = "${var.gce_ssh_user}"
      private_key = "${file(var.gce_ssh_secret_key_file)}"
    }

    script = "make-caliconf.sh"

    inline = [
      "sudo swapoff -a",
      "sudo yum install -y etcd docker kubernetes-node curl vim wget",
      "sudo yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm",
      "sudo yum install -y jq",
      "sudo mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf.old",
      "sudo sh -c 'echo ETCD_NAME=default >> /etc/etcd/etcd.conf'",
      "sudo sh -c 'echo ETCD_DATA_DIR=/var/lib/etcd/default.etcd >> /etc/etcd/etcd.conf'",
      "sudo sh -c 'echo ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379 >> /etc/etcd/etcd.conf'",
      "sudo sh -c 'echo ETCD_ADVERTISE_CLIENT_URLS=http://10.45.0.4:2379 >> /etc/etcd/etcd.conf'",
      "sudo mv /etc/hosts /etc/hosts.old",
      "sudo sh -c 'echo k8s-master 10.45.0.2 >> /etc/hosts'",
      "sudo sh -c 'echo k8s-node1 10.45.0.3 >> /etc/hosts'",
      "sudo sh -c 'echo k8s-node2 10.45.0.4 >> /etc/hosts'",
      "sudo systemctl enable etcd",
      "sudo systemctl start etcd",
      "sudo sh -c 'echo OPTIONS= >> /etc/sysconfig/docker'",
      "sudo sh -c 'echo DOCKER_CERT_PATH=/etc/docker >> /etc/sysconfig/docker'",
      "sudo sh -c 'echo DOCKER_STORAGE_PATH=\"-s overlay\" >> /etc/sysconfig/docker-storage'",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo mkdir -p /opt/calico/bin",
      "sudo wget https://github.com/projectcalico/calico-containers/releases/download/v0.19.0/calicoctl -P /opt/calico/bin",
      "sudo chmod +x /opt/calico/bin/calicoctl",
      "sudo sh -c 'echo PATH=$PATH:$HOME/bin:/opt/calico/bin' >> ~/.bash_profile",
      "sudo ETCD_AUTHORITY=10.45.0.2:2379 /opt/calico/bin/calicoctl node --ip=10.45.0.4",
      "sudo mv /etc/kubernetes/config /etc/kubernetes/config.old",
      "sudo mv /etc/kubernetes/kubelet /etc/kubernetes/kubelet.old",
      "sudo mv /etc/kubernetes/proxy /etc/kubernetes/proxy.old",
      "sudo sh -c 'echo KUBE_LOGTOSTDERR=--logtostderr=true  >> /etc/kubernetes/config'",
      "sudo sh -c 'echo KUBE_LOG_LEVEL=--v=0  >> /etc/kubernetes/config'",
      "sudo sh -c 'echo KUBE_ALLOW_PRIV=--allow-privileged=false  >> /etc/kubernetes/config'",
      "sudo sh -c 'echo KUBE_MASTER=--master=http://10.45.0.2:8080  >> /etc/kubernetes/config'",
      "sudo sh -c 'echo KUBELET_ADDRESS=--address=0.0.0.0  >> /etc/kubernetes/kubelet'",
      "sudo sh -c 'echo KUBELET_HOSTNAME=  >> /etc/kubernetes/kubelet'",
      "sudo sh -c 'echo KUBELET_API_SERVER=--api-servers=http://10.45.0.2:8080  >> /etc/kubernetes/kubelet'",
      "sudo sh -c 'echo KUBELET_ARGS=--network-plugin=cni --network-plugin-dir=/etc/cni/net.d  >> /etc/kubernetes/kubelet'",
      "sudo sh -c 'echo KUBE_PROXY_ARGS=--proxy-mode=iptables  >> /etc/kubernetes/proxy'",
      "sudo mkdir -p /etc/cni/net.d",

      #"sudo sh -c 'echo '{\"name\": \"calico-k8s-network\", \"type\": \"calico\", \"etcd_authority\": \"10.45.0.2:2379\", \"log_level\": \"info\", \"ipam\": {\"type\": \"calico-ipam\"}}' >> /etc/cni/net.d/10-calico.conf'",
      "sudo wget https://github.com/projectcalico/calico-cni/releases/download/v1.3.0/calico -P /opt/calico/bin",

      "sudo sh -c 'chmod +x /opt/calico/bin/calico'",
      "sudo systemctl enable kube-proxy",
      "sudo systemctl enable kubelet",
      "sudo systemctl start kube-proxy",
      "sudo systemctl start kubelet",
    ]
  }

  boot_disk {
    initialize_params {
      size  = "50"
      image = "centos-7-v20180611"
    }
  }

  metadata {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  network_interface {
    access_config {
      //Ephemeral IP
    }

    subnetwork = "${google_compute_subnetwork.k8s-subnet.name}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro", "bigquery", "monitoring"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }
}
