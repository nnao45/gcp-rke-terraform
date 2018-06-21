resource "google_compute_firewall" "rke-firewall" {
  name    = "rke-firewall"
  network = "${google_compute_network.rke-network.name}"

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

  target_tags = ["${google_compute_instance.rke-master.tags}"]
}
