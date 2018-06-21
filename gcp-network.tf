resource "google_compute_network" "rke-network" {
  name                    = "rke-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "rke-subnet" {
  name          = "rke-subnet"
  ip_cidr_range = "10.45.0.0/16"
  network       = "${google_compute_network.rke-network.name}"
  description   = "rke"
  region        = "asia-northeast1"
}
