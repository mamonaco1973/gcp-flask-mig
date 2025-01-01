# Second phase - build GCP infrastructure

# Check if the file "./credentials.json" exists
if (-Not (Test-Path "./credentials.json")) {
    Write-Error "ERROR: The file './credentials.json' does not exist."
    exit 1
}

Write-Host "NOTE: Phase 2 Building GCP Infrastructure"

# Extract the project_id using jq
$project_id = (Get-Content "./credentials.json" | ConvertFrom-Json).project_id

gcloud auth activate-service-account --key-file="./credentials.json" > $null 2> $null
$env:GOOGLE_APPLICATION_CREDENTIALS = "../credentials.json"

gcloud config set project $project_id

$LATEST_IMAGE = gcloud compute images list `
    --filter="name~'^flask-packer-image' AND family=flask-images" `
    --sort-by="~creationTimestamp" `
    --limit=1 `
    --format="value(name)"

# Check if LATEST_IMAGE is empty
if (-Not $LATEST_IMAGE) {
    Write-Error "ERROR: No latest image found for 'flask-packer-image' in family 'flask-images'."
    exit 1
}

$CURRENT_IMAGE = gcloud compute instance-templates describe flask-template `
    --format="get(properties.disks[0].initializeParams.sourceImage)" 2> $null | ForEach-Object {
        ($_ -split '/')[ -1 ]
    }

# Conditional block if CURRENT_IMAGE is not empty and not equal to LATEST_IMAGE
if ($CURRENT_IMAGE -and ($CURRENT_IMAGE -ne $LATEST_IMAGE)) {
    Write-Host "NOTE: Updating resources as CURRENT_IMAGE ($CURRENT_IMAGE) is different from LATEST_IMAGE ($LATEST_IMAGE)."
    gcloud compute backend-services remove-backend flask-backend-service `
        --global `
        --instance-group flask-instance-group `
        --instance-group-zone us-central1-a 

    gcloud compute instance-groups managed delete flask-instance-group `
        --zone us-central1-a `
        -q 
}

Set-Location "02-infrastructure"

terraform init
terraform apply -var="flask_image_name=$LATEST_IMAGE" -auto-approve

Set-Location ".."
