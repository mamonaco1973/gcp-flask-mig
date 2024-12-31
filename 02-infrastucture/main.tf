provider "google" {
    project     =  local.credentials.project_id 
    credentials =  file("../credentials.json")
}

# Read and decode the credentials.json file
locals {
    credentials = jsondecode(file("../credentials.json"))
    service_account_email = local.credentials.client_email
}


# Data block to fetch existing Firestore database
data "google_firestore_database" "default" {
  name = "(default)"
  project = local.credentials.project_id 
}

resource "google_firestore_database" "default" {
  count      = data.google_firestore_database.default.id == "" ? 1 : 0
  name       = "(default)"
  location_id = "us-central-a"
  type       = "NATIVE" # Firestore in Native mode; use "DATASTORE_MODE" for Datastore mode
}