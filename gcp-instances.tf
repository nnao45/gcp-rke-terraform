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
      "sudo setenforce 0",
      "sudo sysctl -w net.bridge.bridge-nf-call-iptables=1",
      "sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1",
      "sudo sysctl -w net.bridge.bridge-nf-call-arptables=1",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-ip6tables = 1 >> /etc/sysctl.conf'",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-iptables = 1 >> /etc/sysctl.conf'",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-arptables = 1 >> /etc/sysctl.conf'",
      "sudo sed -i 's/enforcing/permissive/g' /etc/selinux/config",
      "sudo systemctl stop firewalld",
      "sudo systemctl disable firewalld",
      "sudo sh -c 'echo [kubernetes] >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo name=Kubernetes >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo enabled=1 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo gpgcheck=1 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo repo_gpgcheck=1 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo yum install -y docker wget ebtables kubeadm kubectl kubelet kubernetes-cni",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo systemctl enable kubelet",
      "sudo systemctl start kubelet",
      "sudo mkdir /var/log/kubelet",
      "sudo sh -c 'sed -i \"s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g\" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf'",
      "sudo sh -c 'sed -i \"s/10.96.0.10/10.45.0.2/g\" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf'",
      "sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --service-cidr=10.45.0.0/16 --apiserver-advertise-address=10.45.0.2 | tee ~/kubeadm-output",
      "sudo mkdir -p ~/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config",
      "sudo chown nnao45:nnao45 ~/.kube/config",
      "export KUBECONFIG=~/admin.conf",
      "wget https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml",
      "sed -i \"s@10.96.232.136@10.45.0.2@\" calico.yaml",
      "sudo kubectl -f calico.yaml",
      "sudo kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/calicoctl.yaml",
    ]

    #"sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo",
    #"yum install -y --setopt=obsoletes=0 docker-ce-17.03.2.ce-1.el7.centos",
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
      "sudo setenforce 0",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-ip6tables = 1 >> /etc/sysctl.conf'",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-iptables = 1 >> /etc/sysctl.conf'",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-arptables = 1 >> /etc/sysctl.conf'",
      "sudo sed -i 's/enforcing/permissive/g' /etc/selinux/config",
      "sudo systemctl stop firewalld",
      "sudo systemctl disable firewalld",
      "sudo sh -c 'echo [kubernetes] >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo name=Kubernetes >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo enabled=1 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo gpgcheck=1 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo repo_gpgcheck=1 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo yum install -y docker ebtables kubeadm kubectl kubelet kubernetes-cni",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo mkdir /var/log/kubelet",
      "sudo systemctl enable kubelet",
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
      "sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1",
      "sudo sysctl -w net.bridge.bridge-nf-call-iptables=1",
      "sudo sysctl -w net.bridge.bridge-nf-call-arptables=1",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-ip6tables = 1 >> /etc/sysctl.conf'",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-iptables = 1 >> /etc/sysctl.conf'",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-arptables = 1 >> /etc/sysctl.conf'",
      "sudo setenforce 0",
      "sudo sed -i 's/enforcing/permissive/g' /etc/selinux/config",
      "sudo systemctl stop firewalld",
      "sudo systemctl disable firewalld",
      "sudo sh -c 'echo [kubernetes] >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo name=Kubernetes >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo enabled=1 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo gpgcheck=1 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo repo_gpgcheck=1 >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo sh -c 'echo gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg >> /etc/yum.repos.d/kubernetes.repo'",
      "sudo yum install -y docker ebtables kubeadm kubectl kubelet kubernetes-cni",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo mkdir /var/log/kubelet",
      "sudo systemctl enable kubelet",
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
