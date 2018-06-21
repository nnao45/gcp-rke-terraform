variable "gce_ssh_user" {}
variable "gce_ssh_pub_key_file" {}
variable "gce_ssh_secret_key_file" {}

variable "gce_region" {
  default = "asia-northeast1-c"
}

provider "google" {
  credentials = "${file("~/Downloads/nnao45-gcp-2a8c8d0f00ca.json")}"
  project     = "nnao45-gcp"
  region      = "asia-northeast1"
}
