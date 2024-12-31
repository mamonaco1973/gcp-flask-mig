#!/bin/bash

# Second phase - build GCP infrastructure

# Check if the file "./credentials.json" exists
if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi

echo "NOTE: Phase 2 Building GCP Infrastructure"

# Extract the project_id using jq
project_id=$(jq -r '.project_id' "./credentials.json")

gcloud auth activate-service-account --key-file="./credentials.json" > /dev/null 2> /dev/null
export GOOGLE_APPLICATION_CREDENTIALS="../credentials.json"

gcloud config set project $project_id

LATEST_IMAGE=$(gcloud compute images list \
  --filter="name~'^flask-packer-image' AND family=flask-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")

# Check if LATEST_IMAGE is empty
if [[ -z "$LATEST_IMAGE" ]]; then
  echo "ERROR: No latest image found for 'flask-packer-image' in family 'flask-images'."
  exit 1
fi

CURRENT_IMAGE=$(gcloud compute instance-templates describe flask-template --format="get(properties.disks[0].initializeParams.sourceImage)" 2> /dev/null | awk -F'/' '{print $NF}')

# Conditional block if CURRENT_IMAGE is not empty and not equal to LATEST_IMAGE
if [[ -n "$CURRENT_IMAGE" && "$CURRENT_IMAGE" != "$LATEST_IMAGE" ]]; then
  echo "NOTE: Updating resources as CURRENT_IMAGE ($CURRENT_IMAGE) is different from LATEST_IMAGE ($LATEST_IMAGE)."
  gcloud compute backend-services remove-backend flask-backend-service --global --instance-group flask-instance-group --instance-group-zone us-central1-a 
  gcloud compute instance-groups managed delete flask-instance-group --zone us-central1-a -q 
fi

cd 02-infrastucture/

terraform init
terraform apply -var="flask_image_name=$LATEST_IMAGE" -auto-approve

cd ..
