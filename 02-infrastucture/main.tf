provider "google" {
    project     =  local.credentials.project_id 
    credentials =  file("../credentials.json")
}

# Read and decode the credentials.json file
locals {
    credentials = jsondecode(file("../credentials.json"))
    service_account_email = local.credentials.client_email
}

