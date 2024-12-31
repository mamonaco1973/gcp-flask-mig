# Create a custom VPC
resource "google_compute_network" "flask_vpc" {
    name                    = "flask-vpc"
    auto_create_subnetworks = false
}

# Create a custom subnet in the VPC
resource "google_compute_subnetwork" "flask_subnet" {
    name          = "flask-subnet"
    ip_cidr_range = "10.0.0.0/24"
    region        = "us-central1"
    network       = google_compute_network.flask_vpc.id
}

# Firewall rule to allow HTTP (port 80) traffic
resource "google_compute_firewall" "allow_http" {
    name    = "allow-http"
    network = google_compute_network.flask_vpc.id

    allow {
        protocol = "tcp"
        ports    = ["80"]
    }

    source_ranges = ["0.0.0.0/0"] # Allow traffic from any IP
}

# Firewall rule to allow Flask (port 8000) traffic only for tagged instances
resource "google_compute_firewall" "allow_flask" {
    name    = "allow-flask"
    network = google_compute_network.flask_vpc.id

    allow {
        protocol = "tcp"
        ports    = ["8000"]
    }

    source_ranges = ["0.0.0.0/0"] # Allow traffic from any IP
    target_tags   = ["allow-flask"]
}

# Firewall rule to allow SSH (port 22) traffic only for tagged instances
resource "google_compute_firewall" "allow_ssh" {
    name    = "allow-ssh"
    network = google_compute_network.flask_vpc.id

    allow {
        protocol = "tcp"
        ports    = ["22"]
    }

    source_ranges = ["0.0.0.0/0"] # Allow traffic from any IP
    target_tags   = ["allow-ssh"]
}

resource "google_compute_firewall" "allow_firestore" {
  name    = "allow-firestore"
  network = google_compute_network.flask_vpc.id
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  destination_ranges = ["0.0.0.0/0"]
}

resource "google_compute_router" "flask_router" {
  name    = "flask-router"
  network = google_compute_network.flask_vpc.id
  region  = "us-central1"
}

resource "google_compute_router_nat" "flask_nat" {
  name                       = "flask-nat"
  router                     = google_compute_router.flask_router.name
  region                     = "us-central1"
  nat_ip_allocate_option     = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
