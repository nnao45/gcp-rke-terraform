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
      "sudo sh -c 'echo 1 > /proc/sys/net/bridge/bridge-nf-call-ip6tables'",
      "sudo sh -c 'echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables'",
      "sudo sh -c 'echo 1 > /proc/sys/net/bridge/bridge-nf-call-arptables'",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-ip6tables = 1 >> /etc/ufw/sysctl.conf'",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-iptables = 1 >> /etc/ufw/sysctl.conf'",
      "sudo sh -c 'echo net/bridge/bridge-nf-call-arptables = 1 >> /etc/ufw/sysctl.conf'",
      "sudo apt-get -y update",
      "sudo apt-get -y install vim git curl docker.io apt-transport-https",
      "sudo usermod -a -G docker nnao45",
      "sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "sudo touch /etc/apt/sources.list.d/kubernetes.list",
      "sudo sh -c 'echo deb http://apt.kubernetes.io/ kubernetes-xenial main > /etc/apt/sources.list.d/kubernetes.list '",
      "sudo apt-get -y update",
      "sudo apt-get install -y kubelet kubeadm kubectl",
      "sudo kubeadm init --pod-network-cidr=192.168.0.0/16",
      "mkdir -p ~/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config",
      "sudo chown ${var.gce_ssh_user}:${var.gce_ssh_user} ~/.kube/config",
      "sudo kubectl apply -f https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml",
      "sudo kubectl taint nodes --all node-role.kubernetes.io/master-",
      "sudo wget https://raw.githubusercontent.com/nnao45/gcp-rke-terraform/master/kubernetes-dashboard.yaml -P /etc/kubernetes/manifests/",
      "sudo kubectl apply -f /etc/kubernetes/manifests/kubernetes-dashboard.yaml",
      "sudo wget https://raw.githubusercontent.com/nnao45/gcp-rke-terraform/master/kubernetest-dashboard-service.yaml -P /etc/kubernetes/manifests/",
      "sudo kubectl create -f /etc/kubernetes/manifests/kubernetes-dashboard-service.yaml",
    ]
  }

  boot_disk {
    initialize_params {
      size  = "50"
      image = "ubuntu-os-cloud/ubuntu-1604-lts"
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
