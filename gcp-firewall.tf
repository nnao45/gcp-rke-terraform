resource "google_compute_firewall" "rancher-firewall" {
  name    = "rancher-firewall"
  network = "${google_compute_network.rancher-network.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "6443", "2379-2380", "10250-10256", "30000-32767"]
  }

  allow {
    protocol = "udp"
    ports    = ["8472"]
  }

  target_tags = ["${google_compute_instance.rancher-master.tags}"]
}
