variable "gce_ssh_user" {}
variable "gce_ssh_pub_key_file" {}

variable "gce_region" {
  default = "n1-standard-1"
}

provider "google" {
  credentials = "${file("~/Downloads/nnao45-gcp-2a8c8d0f00ca.json")}"
  project     = "nnao45-gcp"
  region      = "asia-northeast1"
}
