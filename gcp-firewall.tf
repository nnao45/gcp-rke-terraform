resource "google_compute_firewall" "k8s-firewall" {
  name    = "k8s-firewall"
  network = "${google_compute_network.k8s-network.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "ipip"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "179", "443", "6443", "8080", "2379-2380", "10053-10055", "10250-10256", "30000-32767"]
  }

  allow {
    protocol = "udp"
    ports    = ["8472"]
  }

  #target_tags = ["${google_compute_instance.k8s-master.tags}"]
  target_tags = ["k8s"]
}
