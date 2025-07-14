# main.tf

# ----------- PROVIDER -----------
provider "google" {
  credentials = file("credentials.json")
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# ----------- VARIABLES -----------
variable "project_id" {
  default = "kcgcp-terraform"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

# ----------- VPC PERSONALIZADA -----------
resource "google_compute_network" "vpc_terraform" {
  name                    = "vpc-terraform"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_terraform" {
  name          = "subnet-terraform"
  ip_cidr_range = "10.20.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc_terraform.id
}

# ----------- BUCKET -----------
resource "google_storage_bucket" "bucket_terraform" {
  name     = "bucket-${var.project_id}"
  location = var.region
  force_destroy = true
}

# ----------- VM ENLAZADA A VPC -----------
resource "google_compute_instance" "vm_terraform" {
  name         = "vm-terraform"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_terraform.name
    subnetwork = google_compute_subnetwork.subnet_terraform.name
    access_config {} # asigna IP pública
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>Servidor desplegado con Terraform</h1>" > /var/www/html/index.html
  EOF

  tags = ["http-server"]
}

# ----------- FIREWALL RULES -----------
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-terraform"
  network = google_compute_network.vpc_terraform.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}