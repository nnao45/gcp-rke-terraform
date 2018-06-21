resource "google_compute_instance" "rancher-master" {
  name         = "rancher-master"
  machine_type = "n1-standard-1"
  zone         = "asia-northeast1-c"
  description  = "rancher-master"
  tags         = ["rancher-master", "rancher"]

  // Dockerのインストール & ubuntuユーザーをdockerグループに追加
  provisioner "remote-exec" {
    connection {
      user        = "${var.gce_ssh_user}"
      private_key = "${file(var.gce_ssh_secret_key_file)}"
    }

    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install vim git curl",
      "curl releases.rancher.com/install-docker/1.12.sh | bash",
      "sudo usermod -a -G docker nnao45",
    ]
  }

  boot_disk {
    initialize_params {
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

    subnetwork = "${google_compute_subnetwork.rancher-subnet.name}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro", "bigquery", "monitoring"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }
}
