resource "google_compute_instance" "myhouse" {
  name         = "rke"
  machine_type = "n1-standard-1"
  zone         = "asia-northeast1-c"
  description  = "rke"
  tags         = ["myhouse", "rke"]

  boot_disk {
    initialize_params {
        image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    access_config {
       //Ephemeral IP
    }
  
    subnetwork = "${google_compute_subnetwork.rke.name}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro", "bigquery", "monitoring"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }
}
