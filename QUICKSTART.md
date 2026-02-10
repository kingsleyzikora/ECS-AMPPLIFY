# Quick Start Guide

This guide will get you up and running in under 30 minutes.

## Prerequisites

- AWS Account
- AWS CLI configured
- Terraform installed
- Docker installed

## Step-by-Step

### 1. Clone and Configure (5 minutes)

```bash
# Clone the repository
git clone <your-repo-url>
cd ecs-project

# Configure AWS CLI
aws configure

# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Setup Terraform Backend (2 minutes)

```bash
./scripts/setup-terraform-backend.sh
```

Update `terraform/main.tf` with the output from the script.

### 3. Request SSL Certificate (5 minutes)

```bash
# Request certificate
aws acm request-certificate \
  --domain-name yourdomain.com \
  --subject-alternative-names "*.yourdomain.com" \
  --validation-method DNS \
  --region us-east-1

# Get certificate ARN
aws acm list-certificates --region us-east-1
```

Add DNS validation records to your domain provider.

### 4. Configure Terraform Variables (3 minutes)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with:
- Your domain name
- Certificate ARN
- Desired configuration

### 5. Deploy Infrastructure (10 minutes)

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file=terraform.tfvars -out=tfplan

# Apply infrastructure
terraform apply tfplan
```

Save the outputs:
```bash
terraform output > ../terraform-outputs.txt
```

### 6. Build and Deploy Services (5 minutes)

```bash
cd ..

# Build and push Docker images
./scripts/build-and-push.sh dev

# Deploy services to ECS
./scripts/deploy-services.sh dev
```

### 7. Verify Deployment (2 minutes)

```bash
# Get ALB DNS name
ALB_DNS=$(cd terraform && terraform output -raw alb_dns_name)

# Test health endpoints
curl http://${ALB_DNS}/api/users-service/health
curl http://${ALB_DNS}/api/products-service/health
curl http://${ALB_DNS}/api/orders-service/health
curl http://${ALB_DNS}/api/payments-service/health
curl http://${ALB_DNS}/api/notifications-service/health
```

### 8. Configure DNS (2 minutes)

Create an A record pointing to your ALB:
```
Type: A (Alias)
Name: api.yourdomain.com
Value: [ALB DNS from step 7]
```

### 9. Deploy Frontend (Optional)

See [Frontend Deployment Guide](./DEPLOYMENT.md#frontend-deployment-on-aws-amplify)

## Quick Commands

**View logs:**
```bash
./scripts/logs.sh users-service dev
```

**Update a service:**
```bash
# Make changes to service code
./scripts/build-and-push.sh dev
./scripts/deploy-services.sh dev
```

**Check service status:**
```bash
aws ecs describe-services \
  --cluster ecs-microservices-dev-cluster \
  --services ecs-microservices-dev-users-service
```

## Next Steps

- [Full Deployment Guide](./DEPLOYMENT.md)
- [Setup CI/CD](./DEPLOYMENT.md#cicd-pipeline-setup)
- [Configure Monitoring](./DEPLOYMENT.md#monitoring-and-logging)

## Troubleshooting

If something goes wrong, check:

1. **CloudWatch Logs:**
   ```bash
   ./scripts/logs.sh users-service dev
   ```

2. **ECS Task Status:**
   ```bash
   aws ecs list-tasks --cluster ecs-microservices-dev-cluster
   ```

3. **Target Group Health:**
   ```bash
   aws elbv2 describe-target-health --target-group-arn [ARN]
   ```

For detailed troubleshooting, see [DEPLOYMENT.md](./DEPLOYMENT.md#troubleshooting)
