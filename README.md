# ECS Microservices Project

A complete microservices architecture deployed on AWS ECS with Terraform, featuring 5 backend services and a Next.js frontend hosted on AWS Amplify.

## Architecture Overview

### Backend Services (ECS on Fargate)
- **Users Service** (Port 3001): User management and authentication
- **Products Service** (Port 3002): Product catalog management
- **Orders Service** (Port 3003): Order processing and management
- **Payments Service** (Port 3004): Payment processing integration
- **Notifications Service** (Port 3005): Email and SMS notifications

### Frontend
- **Next.js Application**: Hosted on AWS Amplify with automatic deployments

### Infrastructure
- **VPC**: Multi-AZ setup with public and private subnets
- **ECS Cluster**: Fargate-based container orchestration
- **Application Load Balancer**: SSL/TLS termination and traffic routing
- **ECR**: Container image registry
- **CloudWatch**: Logging and monitoring with Container Insights
- **Auto Scaling**: CPU and memory-based scaling policies

## Project Structure

```
ecs-project/
├── services/                    # Backend microservices
│   ├── users-service/
│   ├── products-service/
│   ├── orders-service/
│   ├── payments-service/
│   └── notifications-service/
├── frontend/                    # Next.js frontend application
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                 # Provider and backend configuration
│   ├── variables.tf            # Input variables
│   ├── vpc.tf                  # VPC and networking resources
│   ├── security-groups.tf      # Security group definitions
│   ├── alb.tf                  # Application Load Balancer
│   ├── ecs.tf                  # ECS cluster and services
│   ├── ecr.tf                  # ECR repositories
│   ├── iam.tf                  # IAM roles and policies
│   └── outputs.tf              # Output values
└── .github/                     # CI/CD workflows
    └── workflows/
        ├── deploy-service.yml
        ├── terraform-plan.yml
        ├── terraform-apply.yml
        └── build-test.yml
```

## Prerequisites

Before you begin, ensure you have the following installed and configured:

- [AWS CLI](https://aws.amazon.com/cli/) (v2.x or later)
- [Terraform](https://www.terraform.io/downloads.html) (v1.0 or later)
- [Docker](https://docs.docker.com/get-docker/) (for local testing)
- [Node.js](https://nodejs.org/) (v18 or later)
- [Git](https://git-scm.com/)
- AWS Account with appropriate permissions
- Domain name for SSL certificate (optional but recommended)

## Quick Start

See the [Deployment Guide](./DEPLOYMENT.md) for detailed step-by-step instructions.

## License

MIT License - see LICENSE file for details
