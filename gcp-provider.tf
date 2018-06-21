# GCEをデプロイ。
provider "google" {
  credentials = "${file("~/Downloads/nnao45-gcp-8348f76d3f40.json")}"
  project     = "nnao45-gcp"
  region      = "asia-northeast1"
}
