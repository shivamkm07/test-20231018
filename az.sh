RESOURCE_GROUP="my-container-apps"
LOCATION="canadacentral"
CONTAINERAPPS_ENVIRONMENT="my-environment"
az group create --name $RESOURCE_GROUP --location $LOCATION
az containerapp env create --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP --location "$LOCATION"
az containerapp env dapr-component set --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP --dapr-component-name configuration --yaml configuration.yaml 
IDENTITY_ID=$(az identity show -n "robin-reliable" --resource-group "darkknight-production" --query id | tr -d \")
az containerapp create   --name myapp   --resource-group $RESOURCE_GROUP   --user-assigned $IDENTITY_ID --environment $CONTAINERAPPS_ENVIRONMENT   --image shivamkm07/myapp:dev   --min-replicas 1   --max-replicas 1   --enable-dapr   --dapr-app-id myapp   --dapr-app-port 80 --dapr-app-protocol grpc
