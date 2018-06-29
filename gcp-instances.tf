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

    script = "./build-master.sh"
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

    script = "build-node1.sh"
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

    script = "build-node2.sh"
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
