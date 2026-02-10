#!/bin/bash

# Tail logs from CloudWatch for a specific service
# Usage: ./scripts/logs.sh <service-name> [environment]

set -e

SERVICE=${1}
ENVIRONMENT=${2:-dev}
PROJECT_NAME="ecs-microservices"
LOG_GROUP="/ecs/${PROJECT_NAME}-${ENVIRONMENT}/${SERVICE}"

if [ -z "$SERVICE" ]; then
  echo "Usage: $0 <service-name> [environment]"
  echo ""
  echo "Available services:"
  echo "  - users-service"
  echo "  - products-service"
  echo "  - orders-service"
  echo "  - payments-service"
  echo "  - notifications-service"
  echo ""
  echo "Example: $0 users-service dev"
  exit 1
fi

echo "Tailing logs from: ${LOG_GROUP}"
echo "Press Ctrl+C to stop"
echo ""

aws logs tail ${LOG_GROUP} --follow --format short
