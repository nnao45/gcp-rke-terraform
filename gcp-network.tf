resource "google_compute_network" "k8s-network" {
  name                    = "k8s-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "k8s-subnet" {
  name          = "k8s-subnet"
  ip_cidr_range = "10.45.0.0/16"
  network       = "${google_compute_network.k8s-network.name}"
  description   = "k8s"
  region        = "asia-northeast1"
}
