resource "google_compute_network" "myhouse" {
  name = "myhouse"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "rke" {
  name          = "rke"
  ip_cidr_range = "10.45.0.0/16"
  network       = "${google_compute_network.myhouse.name}"
  description   = "rke"
  region        = "asia-northeast1"
}
