#!/bin/sh

export CSPROJ_NAME=""
export RG_NAME=""
export APP_SERVICE_NAME""
export ZIPFILE_NAME=""

# prepare code for deployment
az bot prepare-deploy --lang Csharp --code-dir "." --proj-file-path ${CSPROJ_NAME}

# create zip file
zip -r ${ZIPFILE_NAME} *

# deploy source code to webapp
az webapp deployment source config-zip --resource-group ${RG_NAME} --name ${APP_SERVICE_NAME} --src ${ZIPFILE_NAME}