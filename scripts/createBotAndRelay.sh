#!/bin/sh

# login
# az login 

export SUB_ID=$(az account show -o tsv --query id)
export LOCATION=""

export PROJECT_NAME=""

export RELAY_SUFFIX=${PROJECT_NAME}-"relay"
export APP_SUFFIX=${PROJECT_NAME}-"app"

export APP_RG_NAME=rg-$APP_SUFFIX
export RELAY_RG_NAME=rg-$RELAY_SUFFIX

# relay variables
export RELAY_NAMESPACE_NAME="rns-${PROJECT_NAME}"
export RELAY_HYCO_NAME="hc1"
export RELAY_POLICY_NAME="SharedAccessKey"

# app variables
export APP_SERVICE_PLAN_NAME="asp-${PROJECT_NAME}"
export APP_SERVICE_NAME="app-${PROJECT_NAME}"


# create app registration
export APP_PASSWORD=""
export APP_NAME="bot-${PROJECT_NAME}"
export APP_ID=$(az ad app create --display-name ${APP_NAME} --password ${APP_PASSWORD} --available-to-other-tenants --query appId -o tsv)

# create resource groups
echo "Creating the Relay Resource Group"
if echo ${RELAY_RG_NAME} > /dev/null 2>&1 && echo ${LOCATION} > /dev/null 2>&1; then
    if ! az group create --name ${RELAY_RG_NAME} --location ${LOCATION} -o table; then
        echo "ERROR: failed to create the resource group"
        exit 1
    fi
    echo "Created Resource Group: ${RELAY_RG_NAME} in ${LOCATION}"
fi

echo "Creating the App Resource Group"
if echo ${APP_RG_NAME} > /dev/null 2>&1 && echo ${LOCATION} > /dev/null 2>&1; then
    if ! az group create --name ${APP_RG_NAME} --location ${LOCATION} -o table; then
        echo "ERROR: failed to create the resource group"
        exit 1
    fi
    echo "Created Resource Group: ${APP_RG_NAME} in ${LOCATION}"
fi

# create relay
echo "Creating the Relay"
if echo ${RELAY_NAMESPACE_NAME} > /dev/null 2>&1 && echo ${SUB_ID} > /dev/null 2>&1; then
    if ! az relay namespace create --name ${RELAY_NAMESPACE_NAME} \
                            --resource-group ${RELAY_RG_NAME} \
                            --location ${LOCATION} \
                            --subscription ${SUB_ID} -o table; then
        echo "ERROR: failed to create the relay"
        exit 1
    fi
    echo "Created Relay Namespace: ${RELAY_NAMESPACE_NAME} in ${RELAY_RG_NAME}"
fi

# create relay hybrid connection
echo "Creating the hybrid connection"
if echo ${RELAY_HYCO_NAME} > /dev/null 2>&1; then
    if ! az relay hyco create --name ${RELAY_HYCO_NAME} \
                        --namespace-name ${RELAY_NAMESPACE_NAME} \
                        --resource-group ${RELAY_RG_NAME} \
                        --requires-client-authorization false \
                        --subscription ${SUB_ID} -o table; then
        echo "ERROR: failed to create the relay hybrid connection"  
        exit 1 
    fi 
    echo "Created Relay Hybrid Connection: ${RELAY_HYCO_NAME} in ${RELAY_NAMESPACE_NAME}"            
fi

# create authorization rule
echo "Creating authorization rule"
if echo ${RELAY_POLICY_NAME} > /dev/null 2>&1; then
    if ! az relay hyco authorization-rule create --hybrid-connection-name ${RELAY_HYCO_NAME} \
                                            --name ${RELAY_POLICY_NAME} \
                                            --namespace-name  ${RELAY_NAMESPACE_NAME} \
                                            --resource-group  ${RELAY_RG_NAME} \
                                            --rights Listen Send \
                                            --subscription ${SUB_ID} -o table; then
        echo "ERROR: failed to create the authorization rule relay hybrid connection"  
        exit 1 
    fi 
    echo "Created Authorization Rule ${RELAY_POLICY_NAME} for Relay Hybrid Connection ${RELAY_HYCO_NAME} in ${RELAY_NAMESPACE_NAME}"
fi

# create bot; update endpoint to relay namespace
echo "Creating the Bot Service"
if echo ${APP_ID} > /dev/null 2>&1 && echo ${APP_PASSWORD} > /dev/null 2>&1; then
    if ! az bot create --appid ${APP_ID} \
                --kind registration \
                --name ${APP_NAME} \
                --resource-group ${APP_RG_NAME} \
                --description "Sample Bot"  \
                --display-name  ${APP_NAME} \
                --echo true \
                --endpoint "https://${RELAY_NAMESPACE_NAME}.servicebus.windows.net/${RELAY_HYCO_NAME}/api/messages" \
                --lang Csharp \
                --location ${LOCATION} \
                --password ${APP_PASSWORD} \
                --sku F0 \
                --subscription ${SUB_ID} -o table; then
        echo "ERROR: failed to create the bot service"  
        exit 1 
    fi 
    echo "Created Bot Service: ${APP_NAME} in ${APP_RG_NAME}"            
fi


# create teams channel
echo "Creating the Bot Teams Channel"
if ! az bot msteams create --name ${APP_NAME} \
                      --resource-group ${APP_RG_NAME} \
                      --subscription ${SUB_ID} -o table; then
    echo "ERROR: failed to create the bot teams channel"  
    exit 1
fi 

echo "Created the Bot Teams Channel"

# create app service plan
echo "Creating the App Service Plan"
if echo ${APP_SERVICE_PLAN_NAME} > /dev/null 2>&1; then
    if ! az appservice plan create --name ${APP_SERVICE_PLAN_NAME} \
                            --resource-group ${APP_RG_NAME} \
                            --location ${LOCATION} \
                            --sku S1 \
                            --subscription ${SUB_ID} -o table; then
        echo "ERROR: failed to create the app service plan"  
        exit 1
    fi  
    echo "Created app service plan ${APP_SERVICE_PLAN_NAME} in ${APP_RG_NAME}"            
fi

# create web app using app service plan
echo "Creating the Webapp with App Service Plan"
if echo ${APP_SERVICE_NAME} > /dev/null 2>&1; then
    if ! az webapp create --name ${APP_SERVICE_NAME} \
                 --plan ${APP_SERVICE_PLAN_NAME} \
                 --resource-group ${APP_RG_NAME} \
                 --subscription ${SUB_ID} -o table; then
        echo "ERROR: failed to create the web app"  
        exit 1
    fi  
    echo "Created web app: ${APP_SERVICE_NAME} with app service plan ${APP_SERVICE_PLAN_NAME}"            
fi

az webapp config appsettings set \
            -g ${APP_RG_NAME} \
            -n ${APP_SERVICE_NAME} \
            --settings WEBSITE_NODE_DEFAULT_VERSION=10.14.1 MicrosoftAppId=${APP_ID} MicrosoftAppPassword=${APP_PASSWORD}

az webapp cors add \
            -g ${APP_RG_NAME}  \
            -n ${APP_SERVICE_NAME} \
            --allowed-origins https://botservice.hosting.portal.azure.net https://hosting.onecloud.azure-test.net/ \
            --subscription ${SUB_ID}

az webapp config set -g ${APP_RG_NAME} -n ${APP_SERVICE_NAME} --web-sockets-enabled true
