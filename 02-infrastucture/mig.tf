
# Managed Instance Group 
resource "google_compute_instance_template" "flask_template" {
  name        = "flask-template"
  machine_type = "e2-micro"

  tags = ["allow-flask", "allow-ssh"] 

  disk {
    auto_delete  = true
    boot         = true
    source_image = data.google_compute_image.flask_packer_image.self_link
  }

  network_interface {
    network    = google_compute_network.flask_vpc.id
    subnetwork = google_compute_subnetwork.flask_subnet.id
  }

service_account {
        email  = local.service_account_email
        scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager"  {
  name               = "flask-instance-group"
  base_instance_name = "flask-instance"
  target_size        = 2
  zone               = "us-central1-a"
  
  version {
    instance_template = google_compute_instance_template.flask_template.self_link
  }
  named_port {
    name = "http"
    port = 8000
  }

  # Auto-healing policies for health checks
  auto_healing_policies {
    health_check      = google_compute_health_check.http_health_check.self_link
    initial_delay_sec = 300 # Time (in seconds) to wait before starting auto-healing
  }
}
# Define the regional health check referenced above
resource "google_compute_health_check" "http_health_check" {
  name               = "http-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 2

  http_health_check {
    request_path = "/gtg"
    port         = 8000
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "flask-autoscaler"
  target = google_compute_instance_group_manager.instance_group_manager.self_link
  zone   = "us-central1-a"
  
  autoscaling_policy {
    max_replicas      = 4  # Maximum number of instances
    min_replicas      = 2  # Minimum number of instances

    cpu_utilization {
      target = 0.6  # Target CPU utilization (60%)
    }

    cooldown_period = 60  # Cooldown period in seconds (1 minute)
  }
}

# Variable to specify the Packer-built image name
variable "flask_image_name" {
  description = "Name of the Packer-built image to use in the instance template"
  type        = string
  default     = "flask-packer-image-20241230153129"
}

# Reference the existing Packer-built image
data "google_compute_image" "flask_packer_image" {
  name    = var.flask_image_name
  project = local.credentials.project_id
}

