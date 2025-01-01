# Managed Instance Group

# Instance Template
# Defines the configuration for VM instances in the managed instance group.
resource "google_compute_instance_template" "flask_template" {
  name         = "flask-template"                       # Unique name for the instance template.
  machine_type = "e2-micro"                             # Specifies the machine type for the instances.

  # Tags for network firewall rules
  tags = ["allow-flask", "allow-ssh"]                   # Tags used to apply firewall rules.

  # Disk configuration
  disk {
    auto_delete  = true                                 # Automatically deletes the disk when the instance is deleted.
    boot         = true                                 # Marks this disk as the boot disk.
    source_image = data.google_compute_image.flask_packer_image.self_link 
                                                        # Source image for the boot disk.
  }

  # Network configuration
  network_interface {
    network    = google_compute_network.flask_vpc.id       # Specifies the custom VPC network.
    subnetwork = google_compute_subnetwork.flask_subnet.id # Specifies the custom subnet within the VPC.
  }

  # Service account configuration
  service_account {
    email  = local.service_account_email                # Service account used by the instances.
    scopes = ["https://www.googleapis.com/auth/cloud-platform"] 
                                                        # Scopes granted to the service account.
  }
}

# Instance Group Manager
# Manages a group of identical instances based on the instance template.
resource "google_compute_instance_group_manager" "instance_group_manager" {
  name               = "flask-instance-group"           # Unique name for the instance group manager.
  base_instance_name = "flask-instance"                 # Prefix for instance names in the group.
  target_size        = 2                                # Desired number of instances in the group.
  zone               = "us-central1-a"                  # Zone where the instances will be created.

  # Specifies the version and template for the instances.
  version {
    instance_template = google_compute_instance_template.flask_template.self_link
  }

  # Named port for the instance group
  named_port {
    name = "http"                                      # Name of the port.
    port = 8000                                        # Port number for HTTP traffic.
  }

  # Auto-healing policies
  # Configures health checks and initial delay before auto-healing.
  auto_healing_policies {
    health_check      = google_compute_health_check.http_health_check.self_link 
                                                        # Health check resource reference.
    initial_delay_sec = 300                             # Wait time before starting auto-healing.
  }
}

# Health Check
# Monitors the health of instances in the group and triggers auto-healing if necessary.
resource "google_compute_health_check" "http_health_check" {
  name                = "http-health-check"             # Unique name for the health check.
  check_interval_sec  = 5                               # Time between health check attempts.
  timeout_sec         = 5                               # Time to wait for a health check response.
  healthy_threshold   = 2                               # Number of consecutive successes to mark as healthy.
  unhealthy_threshold = 2                               # Number of consecutive failures to mark as unhealthy.

  # HTTP-specific health check configuration
  http_health_check {
    request_path = "/gtg"                               # Path to request for the health check.
    port         = 8000                                 # Port to use for the health check.
  }
}

# Autoscaler
# Configures autoscaling for the instance group to ensure optimal resource usage.
resource "google_compute_autoscaler" "autoscaler" {
  name   = "flask-autoscaler"                          # Unique name for the autoscaler.
  target = google_compute_instance_group_manager.instance_group_manager.self_link 
                                                       # Target instance group to scale.
  zone   = "us-central1-a"                             # Zone where the autoscaler operates.

  # Autoscaling policy
  autoscaling_policy {
    max_replicas      = 4                               # Maximum number of instances.
    min_replicas      = 2                               # Minimum number of instances.

    # CPU utilization-based scaling
    cpu_utilization {
      target = 0.6                                      # Target CPU utilization (60%).
    }

    cooldown_period = 60                                # Cooldown period between scaling actions.
  }
}

# Variable for Image Name
# Allows dynamic specification of the Packer-built image name.
variable "flask_image_name" {
  description = "Name of the Packer-built image to use in the instance template" # Description of the variable.
  type        = string                     # Specifies that the variable is of string type.
}

# Data Resource for Packer-Built Image
# Fetches details of the specified Packer-built image.
data "google_compute_image" "flask_packer_image" {
  name    = var.flask_image_name          # Name of the image to fetch.
  project = local.credentials.project_id  # Project where the image is located.
}
