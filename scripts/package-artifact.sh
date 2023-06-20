#!/usr/bin/env bash

#--------------------------------------------------------------------------------------
# package the ci azure devops artifact
#--------------------------------------------------------------------------------------
mkdir -p $SYSTEM_ARTIFACTSDIRECTORY/$ENV
cp -r $SYSTEM_DEFAULTWORKINGDIRECTORY/$TF_FOLDER $SYSTEM_ARTIFACTSDIRECTORY/$ENV
    