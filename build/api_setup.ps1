# NOTE: Validating credentials.json and testing the gcloud command

# Check if the file "credentials.json" exists
if (-Not (Test-Path "./credentials.json")) {
    Write-Error "The file './credentials.json' does not exist."
    exit 1
}

# Activate the service account using the credentials.json file
gcloud auth activate-service-account --key-file="./credentials.json"

# Extract the project_id using PowerShell's ConvertFrom-Json cmdlet
$credentials = Get-Content "./credentials.json" | ConvertFrom-Json
$project_id = $credentials.project_id

# NOTE: Enabling APIs needed for the build
gcloud config set project $project_id
gcloud services enable compute.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable storage.googleapis.com

# Create Firestore database
gcloud firestore databases create --location=us-central1 --type=firestore-native > $null 2> $null
