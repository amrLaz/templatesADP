#!/usr/bin/env bash

# Define variables
terraformFolder=$TF_FOLDER
environment=$ENV
azureServiceConnectionName=$AZURE_SERVICE_CONNECTION_NAME

# Create the deployment plan file
planFile="$BUILD_ARTIFACTSTAGINGDIRECTORY/${environment}_plan.txt"
echo "=================================" >> "$planFile"
echo "  Plan de déploiement" >> "$planFile"
echo "=================================" >> "$planFile"
echo >> "$planFile"
echo "Liste de fichiers" >> "$planFile"
ls "$terraformFolder" | awk '{print "  " $1}' >> "$planFile"
echo >> "$planFile"
echo "$azureServiceConnectionName" >> "$planFile"
echo >> "$planFile"
echo "=================================" >> "$planFile"
echo "  Modifications" >> "$planFile"
echo "=================================" >> "$planFile"
jq '.resource_changes[] | { RessourceName_before: .change.before.name, RessourceName_after: .change.after.name, Type: .name, Action: .change.actions }' "$BUILD_ARTIFACTSTAGINGDIRECTORY/${environment}tfplan.json" | while read -r line; do
  echo "$line" | sed 's/^{ //g; s/ }$//g; s/":"/": "/g; s/", "/\n    /g' >> "$planFile"
done
