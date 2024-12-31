resource "google_project_iam_member" "flask_firestore_access" {
    project     =  local.credentials.project_id 
    role        = "roles/datastore.user"
    member      = "serviceAccount:${local.service_account_email}"
}