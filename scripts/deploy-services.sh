#!/bin/bash

# Deploy or update ECS services
# Usage: ./scripts/deploy-services.sh [environment]

set -e

# Configuration
ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
PROJECT_NAME="ecs-microservices"
CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cluster"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Deploying services to ECS cluster: ${CLUSTER_NAME}${NC}"
echo ""

# Services to deploy
SERVICES=("users-service" "products-service" "orders-service" "payments-service" "notifications-service")

# Update each service
for SERVICE in "${SERVICES[@]}"; do
  SERVICE_NAME="${PROJECT_NAME}-${ENVIRONMENT}-${SERVICE}"

  echo -e "${YELLOW}Updating ${SERVICE_NAME}...${NC}"

  aws ecs update-service \
    --cluster ${CLUSTER_NAME} \
    --service ${SERVICE_NAME} \
    --force-new-deployment \
    --region ${AWS_REGION} \
    --query 'service.serviceName' \
    --output text

  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to update ${SERVICE_NAME}${NC}"
    exit 1
  fi

  echo -e "${GREEN}✓ ${SERVICE_NAME} deployment started${NC}"
  echo ""
done

echo -e "${GREEN}All services deployment triggered!${NC}"
echo ""
echo "Monitor deployment status:"
for SERVICE in "${SERVICES[@]}"; do
  echo "  aws ecs describe-services --cluster ${CLUSTER_NAME} --services ${PROJECT_NAME}-${ENVIRONMENT}-${SERVICE} --query 'services[0].deployments'"
done
