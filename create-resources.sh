###########################################################
# Configuration
###########################################################

AZ_WEBAPP_NAME=guestbook-${RANDOM}
AZ_RESOURCE_GROUP="${AZ_WEBAPP_NAME}-rg"
AZ_DATABASE_SERVER="${AZ_WEBAPP_NAME}-postgres"
AZ_DATABASE_NAME="${AZ_WEBAPP_NAME}-db"
AZ_LOCATION=southcentralus
AZ_POSTGRESQL_USERNAME=demouser
AZ_POSTGRESQL_PASSWORD=demo@POSTGRES12

###########################################################

echo "Creating resource group..."

az group create \
    --name $AZ_RESOURCE_GROUP \
    --location $AZ_LOCATION

echo "Create a PostgreSQL server"

az postgres server create \
    --resource-group $AZ_RESOURCE_GROUP \
    --name $AZ_DATABASE_SERVER \
    --location $AZ_LOCATION \
    --sku-name B_Gen5_1 \
    --storage-size 5120 \
    --admin-user $AZ_POSTGRESQL_USERNAME \
    --admin-password $AZ_POSTGRESQL_PASSWORD \
    --version 11

# OPTIONAL IF YOU WANT TO CREATE A FIREWALL EXCEPTION FOR YOUR OWN IP ADDRESS
# echo "Create a firewall exception for your own IP address"

# az postgres server firewall-rule create \
#     --resource-group $AZ_RESOURCE_GROUP \
#     --name $AZ_DATABASE_NAME-database-allow-local-ip \
#     --server $AZ_DATABASE_SERVER \
#     --start-ip-address $AZ_LOCAL_IP_ADDRESS \
#     --end-ip-address $AZ_LOCAL_IP_ADDRESS \
#     | jq

echo "Create a database in PostgreSQL"

az postgres db create \
    --resource-group $AZ_RESOURCE_GROUP \
    --name $AZ_DATABASE_NAME \
    --server-name $AZ_DATABASE_SERVER

echo "Allow Azure-hosted services to access the postgres server"

az postgres server firewall-rule create \
    --resource-group $AZ_RESOURCE_GROUP \
    --server-name $AZ_DATABASE_SERVER \
    --name AllowAllWindowsAzureIps \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0

echo "Create a Linux App Service plan"

az appservice plan create \
    --name "${AZ_WEBAPP_NAME}-plan" \
    --is-linux \
    --sku FREE \
    --location $AZ_LOCATION \
    --resource-group $AZ_RESOURCE_GROUP

echo "Create a web app"

az webapp create \
    --plan "${AZ_WEBAPP_NAME}-plan" \
    --resource-group $AZ_RESOURCE_GROUP \
    --name ${AZ_WEBAPP_NAME} \
    --runtime "JAVA|11-java11"

echo "Set the database url in the web configuration"

DB_URL="jdbc:postgresql://${AZ_DATABASE_SERVER}.postgres.database.azure.com:5432/${AZ_DATABASE_NAME}?user=${AZ_POSTGRESQL_USERNAME}@${AZ_DATABASE_SERVER}&password=${AZ_POSTGRESQL_PASSWORD}&sslmode=require"

az webapp config appsettings set \
    --resource-group $AZ_RESOURCE_GROUP \
    --name ${AZ_WEBAPP_NAME} \
    --settings "DATABASE_URL=${DB_URL}"

echo "All Azure resources created"
