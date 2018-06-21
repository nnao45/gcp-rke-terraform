resource "google_compute_network" "rancher-network" {
  name                    = "rancher-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "rancher-subnet" {
  name          = "rancher-subnet"
  ip_cidr_range = "10.45.0.0/16"
  network       = "${google_compute_network.rancher-network.name}"
  description   = "rancher"
  region        = "asia-northeast1"
}
