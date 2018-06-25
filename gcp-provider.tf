variable "gce_ssh_user" {}

variable "gce_ssh_pub_key_file" {}

variable "gce_ssh_secret_key_file" {}

variable "gce_region" {
  default = "asia-northeast1-c"
}

provider "google" {
  credentials = "${file("~/Downloads/nnao45-gcp-21c7bd4d3907.json")}"
  project     = "nnao45-gcp"
  region      = "asia-northeast1"
}
