#!/bin/bash

# Build and push all microservices to ECR
# Usage: ./scripts/build-and-push.sh [environment]

set -e

# Configuration
ENVIRONMENT=${1:-dev}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}
PROJECT_NAME="ecs-microservices"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting build and push process for environment: ${ENVIRONMENT}${NC}"
echo "AWS Account: ${AWS_ACCOUNT_ID}"
echo "Region: ${AWS_REGION}"
echo ""

# Authenticate Docker with ECR
echo -e "${YELLOW}Authenticating with ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to authenticate with ECR${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Authenticated with ECR${NC}"
echo ""

# Services to build
SERVICES=("users-service" "products-service" "orders-service" "payments-service" "notifications-service")

# Build and push each service
for SERVICE in "${SERVICES[@]}"; do
  echo -e "${YELLOW}Building ${SERVICE}...${NC}"

  # Build Docker image
  docker build -t ${SERVICE}:latest ./services/${SERVICE} \
    --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg VCS_REF=$(git rev-parse --short HEAD)

  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build ${SERVICE}${NC}"
    exit 1
  fi

  # Tag image
  ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}/${SERVICE}"
  docker tag ${SERVICE}:latest ${ECR_REPO}:latest
  docker tag ${SERVICE}:latest ${ECR_REPO}:$(git rev-parse --short HEAD)

  # Push to ECR
  echo -e "${YELLOW}Pushing ${SERVICE} to ECR...${NC}"
  docker push ${ECR_REPO}:latest
  docker push ${ECR_REPO}:$(git rev-parse --short HEAD)

  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to push ${SERVICE}${NC}"
    exit 1
  fi

  echo -e "${GREEN}✓ ${SERVICE} built and pushed successfully${NC}"
  echo ""
done

echo -e "${GREEN}All services built and pushed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Update ECS services to use new images"
echo "2. Monitor deployments in AWS Console or using: aws ecs describe-services --cluster ${PROJECT_NAME}-${ENVIRONMENT}-cluster --services [service-name]"
