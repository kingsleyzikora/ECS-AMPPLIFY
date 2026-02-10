#!/bin/bash

# Setup Terraform backend (S3 + DynamoDB)
# Usage: ./scripts/setup-terraform-backend.sh

set -e

# Configuration
PROJECT_NAME="ecs-microservices"
AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="${PROJECT_NAME}-terraform-state-${AWS_ACCOUNT_ID}"
TABLE_NAME="${PROJECT_NAME}-terraform-lock"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Setting up Terraform backend...${NC}"
echo "Bucket: ${BUCKET_NAME}"
echo "Table: ${TABLE_NAME}"
echo "Region: ${AWS_REGION}"
echo ""

# Create S3 bucket
echo -e "${YELLOW}Creating S3 bucket...${NC}"
if aws s3api head-bucket --bucket ${BUCKET_NAME} 2>/dev/null; then
  echo -e "${YELLOW}Bucket already exists${NC}"
else
  aws s3api create-bucket \
    --bucket ${BUCKET_NAME} \
    --region ${AWS_REGION}

  echo -e "${GREEN}✓ S3 bucket created${NC}"
fi

# Enable versioning
echo -e "${YELLOW}Enabling versioning...${NC}"
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

echo -e "${GREEN}✓ Versioning enabled${NC}"

# Enable encryption
echo -e "${YELLOW}Enabling encryption...${NC}"
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo -e "${GREEN}✓ Encryption enabled${NC}"

# Block public access
echo -e "${YELLOW}Blocking public access...${NC}"
aws s3api put-public-access-block \
  --bucket ${BUCKET_NAME} \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo -e "${GREEN}✓ Public access blocked${NC}"

# Create DynamoDB table
echo -e "${YELLOW}Creating DynamoDB table...${NC}"
if aws dynamodb describe-table --table-name ${TABLE_NAME} --region ${AWS_REGION} 2>/dev/null; then
  echo -e "${YELLOW}Table already exists${NC}"
else
  aws dynamodb create-table \
    --table-name ${TABLE_NAME} \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ${AWS_REGION}

  echo -e "${GREEN}✓ DynamoDB table created${NC}"
fi

echo ""
echo -e "${GREEN}Terraform backend setup complete!${NC}"
echo ""
echo "Update your terraform/main.tf with:"
echo ""
echo "terraform {"
echo "  backend \"s3\" {"
echo "    bucket         = \"${BUCKET_NAME}\""
echo "    key            = \"ecs-project/terraform.tfstate\""
echo "    region         = \"${AWS_REGION}\""
echo "    dynamodb_table = \"${TABLE_NAME}\""
echo "    encrypt        = true"
echo "  }"
echo "}"
