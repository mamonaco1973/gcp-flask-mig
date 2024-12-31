# Static Global IP Address
resource "google_compute_global_address" "lb_ip" {
  name = "flask-lb-ip"
}

# resource "google_compute_health_check" "http_health_check" {
#   name = "http-health-check"
#   check_interval_sec = 10
#   timeout_sec = 5
#   healthy_threshold = 2
#   unhealthy_threshold = 2
#   http_health_check {
#     port = 8000
#     request_path = "/gtg"
#   }
# }

# Backend Service
resource "google_compute_backend_service" "backend_service" {
  name             = "flask-backend-service"
  protocol         = "HTTP"
  port_name        = "http" # This must match the named port in the instance group
  health_checks    = [google_compute_health_check.http_health_check.self_link]
  timeout_sec      = 10
  load_balancing_scheme = "EXTERNAL"

  backend {
    group           = google_compute_instance_group_manager.instance_group_manager.instance_group
    balancing_mode  = "UTILIZATION"
  }

  depends_on = [google_compute_health_check.http_health_check]
}

# URL Map
resource "google_compute_url_map" "url_map" {
  name            = "flask-alb"
  default_service = google_compute_backend_service.backend_service.self_link
}

# Target HTTP Proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "flask-http-proxy"
  url_map = google_compute_url_map.url_map.id
}

# Forwarding Rule
resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "flask-http-forwarding-rule"
  ip_address            = google_compute_global_address.lb_ip.address
  target                = google_compute_target_http_proxy.http_proxy.self_link
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
}
