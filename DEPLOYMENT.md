# Deployment Guide

This comprehensive guide will walk you through deploying the ECS microservices architecture from scratch.

## Table of Contents

1. [Prerequisites Setup](#prerequisites-setup)
2. [AWS Account Configuration](#aws-account-configuration)
3. [SSL Certificate Setup](#ssl-certificate-setup)
4. [Terraform Backend Setup](#terraform-backend-setup)
5. [Infrastructure Deployment](#infrastructure-deployment)
6. [Building and Pushing Docker Images](#building-and-pushing-docker-images)
7. [CI/CD Pipeline Setup](#cicd-pipeline-setup)
8. [Frontend Deployment on AWS Amplify](#frontend-deployment-on-aws-amplify)
9. [DNS Configuration](#dns-configuration)
10. [Monitoring and Logging](#monitoring-and-logging)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites Setup

### 1. Install Required Tools

**AWS CLI:**
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

**Terraform:**
```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Linux
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify installation
terraform --version
```

**Docker:**
```bash
# macOS
brew install --cask docker

# Linux (Ubuntu)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Verify installation
docker --version
```

---

## AWS Account Configuration

### 1. Create IAM User for Deployment

1. Log into AWS Console
2. Navigate to **IAM → Users → Create User**
3. User name: `terraform-deploy`
4. Enable **Programmatic access**
5. Attach the following policies:
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonECS_FullAccess`
   - `AmazonVPCFullAccess`
   - `IAMFullAccess`
   - `AmazonS3FullAccess`
   - `CloudWatchLogsFullAccess`
   - `ElasticLoadBalancingFullAccess`

   **Or create a custom policy with least privilege:**

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ec2:*",
           "ecs:*",
           "ecr:*",
           "elasticloadbalancing:*",
           "logs:*",
           "iam:*",
           "s3:*",
           "application-autoscaling:*",
           "cloudwatch:*"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

6. Save the **Access Key ID** and **Secret Access Key**

### 2. Configure AWS CLI

```bash
aws configure
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

---

## SSL Certificate Setup

### Option 1: Request ACM Certificate (Recommended)

1. **Request Certificate:**
   ```bash
   aws acm request-certificate \
     --domain-name yourdomain.com \
     --subject-alternative-names "*.yourdomain.com" \
     --validation-method DNS \
     --region us-east-1
   ```

2. **Get Certificate ARN:**
   ```bash
   aws acm list-certificates --region us-east-1
   ```

3. **Validate Certificate:**
   - Go to AWS Console → Certificate Manager
   - Click on the certificate
   - Add the CNAME records to your DNS provider
   - Wait for validation (usually 5-30 minutes)

4. **Copy the Certificate ARN** (you'll need it for Terraform)

### Option 2: Import Existing Certificate

```bash
aws acm import-certificate \
  --certificate fileb://certificate.pem \
  --private-key fileb://private-key.pem \
  --certificate-chain fileb://certificate-chain.pem \
  --region us-east-1
```

---

## Terraform Backend Setup

Terraform state must be stored in S3 for production deployments.

### 1. Create S3 Bucket for Terraform State

```bash
# Set variables
export PROJECT_NAME="ecs-microservices"
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create S3 bucket
aws s3api create-bucket \
  --bucket ${PROJECT_NAME}-terraform-state-${AWS_ACCOUNT_ID} \
  --region ${AWS_REGION}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ${PROJECT_NAME}-terraform-state-${AWS_ACCOUNT_ID} \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket ${PROJECT_NAME}-terraform-state-${AWS_ACCOUNT_ID} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket ${PROJECT_NAME}-terraform-state-${AWS_ACCOUNT_ID} \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### 2. Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name ${PROJECT_NAME}-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ${AWS_REGION}
```

### 3. Update Terraform Backend Configuration

Edit `terraform/main.tf` and update the backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "ecs-microservices-terraform-state-123456789012"  # Replace with your bucket name
    key            = "ecs-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ecs-microservices-terraform-lock"
    encrypt        = true
  }
}
```

---

## Infrastructure Deployment

### 1. Configure Terraform Variables

Create `terraform/terraform.tfvars`:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "ecs-microservices"
environment  = "dev"  # or "staging" or "prod"

# Network Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Domain and SSL
domain_name     = "yourdomain.com"  # Replace with your domain
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxx"  # Replace with your cert ARN

# ECS Configuration
container_insights_enabled = true
desired_count              = 2
cpu                        = "256"
memory                     = "512"
```

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

Expected output:
```
Initializing the backend...
Successfully configured the backend "s3"!
Terraform has been successfully initialized!
```

### 3. Validate Configuration

```bash
terraform validate
```

### 4. Plan Infrastructure Changes

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan

# Review the plan carefully
# Expected resources: ~80-100 resources to be created
```

### 5. Apply Infrastructure

```bash
terraform apply tfplan

# This will take 10-15 minutes
```

### 6. Save Outputs

```bash
terraform output > ../terraform-outputs.txt

# Important outputs:
# - ALB DNS name
# - ECR repository URLs
# - ECS cluster name
```

---

## Building and Pushing Docker Images

### 1. Authenticate Docker with ECR

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
```

### 2. Build and Push Each Service

**Script to automate building all services:**

Create `scripts/build-and-push.sh`:

```bash
#!/bin/bash

set -e

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
PROJECT_NAME="ecs-microservices"

SERVICES=("users-service" "products-service" "orders-service" "payments-service" "notifications-service")

for SERVICE in "${SERVICES[@]}"; do
  echo "Building $SERVICE..."

  # Build Docker image
  docker build -t ${SERVICE}:latest ./services/${SERVICE}

  # Tag image
  docker tag ${SERVICE}:latest \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}/${SERVICE}:latest

  # Push to ECR
  docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}/${SERVICE}:latest

  echo "✓ $SERVICE pushed successfully"
done

echo "All services built and pushed!"
```

Make it executable and run:

```bash
chmod +x scripts/build-and-push.sh
./scripts/build-and-push.sh
```

### 3. Update ECS Services

After pushing images, force new deployment:

```bash
CLUSTER_NAME="ecs-microservices-dev-cluster"

for SERVICE in users-service products-service orders-service payments-service notifications-service; do
  aws ecs update-service \
    --cluster ${CLUSTER_NAME} \
    --service ecs-microservices-dev-${SERVICE} \
    --force-new-deployment \
    --region us-east-1
done
```

### 4. Verify Deployments

```bash
# Check service status
aws ecs describe-services \
  --cluster ${CLUSTER_NAME} \
  --services ecs-microservices-dev-users-service \
  --query 'services[0].deployments' \
  --region us-east-1

# Check running tasks
aws ecs list-tasks \
  --cluster ${CLUSTER_NAME} \
  --region us-east-1
```

---

## CI/CD Pipeline Setup

### 1. Configure GitHub Secrets

Go to your GitHub repository → **Settings → Secrets and variables → Actions**

Add the following secrets:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_ACCOUNT_ID`: Your AWS account ID
- `AWS_REGION`: `us-east-1` (or your region)

### 2. Enable GitHub Actions

The workflows are already configured in `.github/workflows/`:

- **build-test.yml**: Runs on every PR (builds and tests services)
- **terraform-plan.yml**: Runs on PRs that modify Terraform files
- **terraform-apply.yml**: Applies Terraform changes on main branch
- **deploy-service.yml**: Deploys services to ECS on code changes

### 3. Test CI/CD Pipeline

```bash
# Make a small change to a service
echo "// Test change" >> services/users-service/src/index.js

# Commit and push
git add .
git commit -m "test: CI/CD pipeline"
git push origin main

# Monitor the workflow in GitHub Actions tab
```

### 4. Manual Service Deployment

You can also trigger manual deployments:

1. Go to **Actions** tab in GitHub
2. Select **Deploy Microservice to ECS**
3. Click **Run workflow**
4. Choose service and environment
5. Click **Run workflow**

---

## Frontend Deployment on AWS Amplify

### 1. Connect Repository to Amplify

```bash
# Navigate to AWS Amplify Console
# Or use AWS CLI

aws amplify create-app \
  --name ecs-microservices-frontend \
  --repository https://github.com/yourusername/ecs-project \
  --access-token ${GITHUB_TOKEN} \
  --region us-east-1
```

### 2. Configure Build Settings

AWS Amplify will automatically detect the `amplify.yml` file in the frontend directory.

Ensure your `amplify.yml` is correctly configured:

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - cd frontend
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: frontend/.next
    files:
      - '**/*'
  cache:
    paths:
      - frontend/node_modules/**/*
      - frontend/.next/cache/**/*
```

### 3. Set Environment Variables in Amplify

In Amplify Console → **Environment variables**:

```
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
```

Or via CLI:

```bash
APP_ID=$(aws amplify list-apps --query 'apps[0].appId' --output text)

aws amplify update-app \
  --app-id ${APP_ID} \
  --environment-variables NEXT_PUBLIC_API_URL=https://api.yourdomain.com
```

### 4. Configure Custom Domain (Optional)

```bash
aws amplify create-domain-association \
  --app-id ${APP_ID} \
  --domain-name yourdomain.com \
  --sub-domain-settings prefix=www,branchName=main
```

### 5. Trigger Deployment

```bash
aws amplify start-deployment \
  --app-id ${APP_ID} \
  --branch-name main
```

---

## DNS Configuration

### 1. Configure DNS for Backend API

Create an **A Record** (Alias) in your DNS provider:

```
Type: A (Alias)
Name: api.yourdomain.com
Value: [ALB DNS Name from Terraform output]
```

**Route53 Example:**

```bash
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name yourdomain.com \
  --query 'HostedZones[0].Id' \
  --output text)

ALB_DNS_NAME=$(cd terraform && terraform output -raw alb_dns_name)
ALB_ZONE_ID=$(cd terraform && terraform output -raw alb_zone_id)

cat > route53-change.json <<EOF
{
  "Changes": [{
    "Action": "CREATE",
    "ResourceRecordSet": {
      "Name": "api.yourdomain.com",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "${ALB_ZONE_ID}",
        "DNSName": "${ALB_DNS_NAME}",
        "EvaluateTargetHealth": true
      }
    }
  }]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id ${HOSTED_ZONE_ID} \
  --change-batch file://route53-change.json
```

### 2. Verify DNS Resolution

```bash
# Wait a few minutes for DNS propagation
nslookup api.yourdomain.com

# Test HTTPS endpoint
curl -I https://api.yourdomain.com/api/users-service/health
```

---

## Monitoring and Logging

### 1. Access CloudWatch Logs

```bash
# List log groups
aws logs describe-log-groups \
  --log-group-name-prefix "/ecs/ecs-microservices"

# Tail logs for a specific service
aws logs tail /ecs/ecs-microservices-dev/users-service --follow
```

**Via AWS Console:**
- CloudWatch → Log groups → `/ecs/ecs-microservices-dev/[service-name]`

### 2. Enable Container Insights

Already enabled in Terraform. View metrics:

```bash
# Via AWS Console
# CloudWatch → Container Insights → ECS Clusters
```

### 3. Set Up CloudWatch Alarms

**High CPU Usage Alarm:**

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name ecs-microservices-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=ClusterName,Value=ecs-microservices-dev-cluster
```

### 4. Access ECS Exec (SSH into containers)

```bash
# Enable ECS Exec (already enabled in Terraform)

# Find task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster ecs-microservices-dev-cluster \
  --service-name ecs-microservices-dev-users-service \
  --query 'taskArns[0]' \
  --output text)

# Execute command in container
aws ecs execute-command \
  --cluster ecs-microservices-dev-cluster \
  --task ${TASK_ARN} \
  --container users-service \
  --interactive \
  --command "/bin/sh"
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Service Fails to Start

**Check logs:**
```bash
aws logs tail /ecs/ecs-microservices-dev/users-service --follow
```

**Common causes:**
- Port mismatch in task definition
- Missing environment variables
- Image not found in ECR
- Insufficient memory/CPU

**Solution:**
```bash
# Update task definition and redeploy
aws ecs update-service \
  --cluster ecs-microservices-dev-cluster \
  --service ecs-microservices-dev-users-service \
  --force-new-deployment
```

#### 2. Health Check Failures

**Check target group health:**
```bash
aws elbv2 describe-target-health \
  --target-group-arn [TARGET_GROUP_ARN]
```

**Solution:**
- Verify health check path is correct (`/health`)
- Ensure service is listening on correct port
- Check security group rules

#### 3. "No Space Left on Device"

**Solution:**
```bash
# Increase Fargate task ephemeral storage (in terraform/ecs.tf)
ephemeralStorage = {
  sizeInGiB = 30  # Default is 20
}
```

#### 4. Terraform State Lock

**Error:** "Error locking state"

**Solution:**
```bash
# Find lock ID in error message
aws dynamodb delete-item \
  --table-name ecs-microservices-terraform-lock \
  --key '{"LockID":{"S":"ecs-microservices-terraform-state/terraform.tfstate"}}'
```

#### 5. SSL Certificate Not Working

**Check certificate:**
```bash
aws acm describe-certificate \
  --certificate-arn [CERT_ARN] \
  --region us-east-1
```

**Solution:**
- Verify certificate is validated
- Check certificate is in same region as ALB (us-east-1)
- Verify domain name matches ALB listener

#### 6. Cannot Pull Image from ECR

**Solution:**
```bash
# Check ECR repository
aws ecr describe-repositories

# Re-authenticate
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

# Verify IAM permissions for ECS execution role
```

---

## Cleanup

To avoid ongoing AWS charges, destroy resources when done:

```bash
# Delete ECS services first
cd terraform
terraform destroy -target=aws_ecs_service.services -auto-approve

# Wait for services to be deleted, then destroy everything
terraform destroy -var-file=terraform.tfvars -auto-approve

# Delete S3 state bucket
aws s3 rb s3://ecs-microservices-terraform-state-${AWS_ACCOUNT_ID} --force

# Delete DynamoDB table
aws dynamodb delete-table --table-name ecs-microservices-terraform-lock
```

---

## Additional Resources

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Amplify Documentation](https://docs.amplify.aws/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

## Support

For issues and questions:
- Open an issue in the GitHub repository
- Check the [Troubleshooting](#troubleshooting) section
- Review AWS CloudWatch logs

---

**Last Updated:** 2026-02-07
