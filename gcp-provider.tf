provider "google" {
  credentials = "${file("~/Downloads/nnao45-gcp-2a8c8d0f00ca.json")}"
  project     = "nnao45-gcp"
  region      = "asia-northeast1"
}
