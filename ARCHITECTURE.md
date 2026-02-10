# Architecture Overview

This document provides a detailed overview of the ECS microservices architecture.

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          Internet                                │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                ┌───────▼────────┐
                │  Route 53 DNS  │
                └───────┬────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
┌───────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐
│              │ │            │ │            │
│ AWS Amplify  │ │    ACM     │ │   ALB      │
│  (Frontend)  │ │ (SSL Cert) │ │ (HTTPS)    │
│              │ │            │ │            │
└──────────────┘ └────────────┘ └─────┬──────┘
                                       │
                        ┌──────────────┴───────────────┐
                        │    Target Groups             │
                        │  (Health Checks, Routing)    │
                        └──────────────┬───────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────┐
        │                              │                          │
        │          ECS Cluster (Fargate)                         │
        │                                                         │
        │  ┌──────────┬──────────┬──────────┬──────────┬──────┐ │
        │  │  Users   │ Products │  Orders  │ Payments │ Notif││ │
        │  │ Service  │ Service  │ Service  │ Service  │ Svc  ││ │
        │  │          │          │          │          │      ││ │
        │  │ :3001    │ :3002    │ :3003    │ :3004    │ :3005││ │
        │  └────┬─────┴────┬─────┴────┬─────┴────┬─────┴───┬──┘ │
        │       │          │          │          │         │    │
        │       └──────────┴──────────┴──────────┴─────────┘    │
        │                         │                              │
        └─────────────────────────┼──────────────────────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │   CloudWatch Logs          │
                    │   (Monitoring & Logging)   │
                    └────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Supporting Services                           │
├─────────────────────────────────────────────────────────────────┤
│  • ECR: Container Registry                                       │
│  • VPC: Network Isolation (Public/Private Subnets)             │
│  • NAT Gateway: Outbound internet for private subnets          │
│  • Security Groups: Firewall rules                             │
│  • IAM Roles: Service permissions                              │
│  • Auto Scaling: Dynamic capacity management                   │
└─────────────────────────────────────────────────────────────────┘
```

## Network Architecture

### VPC Layout

```
VPC (10.0.0.0/16)
│
├── Availability Zone A (us-east-1a)
│   ├── Public Subnet A (10.0.0.0/24)
│   │   ├── NAT Gateway A
│   │   └── ALB (Instance A)
│   │
│   └── Private Subnet A (10.0.100.0/24)
│       └── ECS Tasks (Auto-assigned IPs)
│
└── Availability Zone B (us-east-1b)
    ├── Public Subnet B (10.0.1.0/24)
    │   ├── NAT Gateway B
    │   └── ALB (Instance B)
    │
    └── Private Subnet B (10.0.101.0/24)
        └── ECS Tasks (Auto-assigned IPs)
```

### Traffic Flow

1. **External Request**
   - Client → Route53 DNS → ALB (HTTPS:443)
   - HTTP (port 80) automatically redirects to HTTPS

2. **Load Balancing**
   - ALB terminates SSL/TLS
   - Routes to appropriate target group based on path
   - Path pattern: `/api/{service-name}/*`

3. **Service Communication**
   - ALB → ECS Tasks in private subnets
   - Tasks can communicate with each other via security groups
   - Outbound internet via NAT Gateway

4. **Response Path**
   - ECS Task → ALB → Client

## Service Architecture

### Microservices

#### 1. Users Service (Port 3001)
**Responsibilities:**
- User registration and authentication
- User profile management
- JWT token generation

**Endpoints:**
- `GET /api/users` - List all users
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create new user
- `GET /health` - Health check

#### 2. Products Service (Port 3002)
**Responsibilities:**
- Product catalog management
- Inventory tracking
- Product search and filtering

**Endpoints:**
- `GET /api/products` - List all products
- `GET /api/products/:id` - Get product by ID
- `POST /api/products` - Create new product
- `GET /health` - Health check

#### 3. Orders Service (Port 3003)
**Responsibilities:**
- Order creation and management
- Order status tracking
- Integration with Products and Payments services

**Endpoints:**
- `GET /api/orders` - List all orders
- `GET /api/orders/:id` - Get order by ID
- `POST /api/orders` - Create new order
- `GET /health` - Health check

#### 4. Payments Service (Port 3004)
**Responsibilities:**
- Payment processing
- Refund handling
- Integration with payment gateways (Stripe)

**Endpoints:**
- `POST /api/payments/charge` - Process payment
- `GET /api/payments/:id` - Get payment details
- `POST /api/payments/refund` - Process refund
- `GET /health` - Health check

#### 5. Notifications Service (Port 3005)
**Responsibilities:**
- Email notifications
- SMS notifications
- Integration with AWS SES/SNS

**Endpoints:**
- `POST /api/notifications/email` - Send email
- `POST /api/notifications/sms` - Send SMS
- `GET /api/notifications/:id` - Get notification status
- `GET /health` - Health check

## Infrastructure Components

### ECS Fargate

**Configuration:**
- **Launch Type:** Fargate (serverless)
- **CPU:** 256 units (0.25 vCPU)
- **Memory:** 512 MB
- **Desired Count:** 2 tasks per service
- **Network Mode:** awsvpc

**Benefits:**
- No server management
- Automatic scaling
- Pay only for what you use
- High availability across AZs

### Application Load Balancer (ALB)

**Features:**
- SSL/TLS termination
- Path-based routing
- Health checks
- Cross-zone load balancing
- Connection draining

**Listeners:**
- HTTP:80 → Redirect to HTTPS:443
- HTTPS:443 → Route to target groups

**SSL/TLS:**
- Certificate from AWS Certificate Manager (ACM)
- TLS 1.2 minimum
- Strong cipher suites

### Auto Scaling

**Policies:**

1. **CPU-based Scaling**
   - Target: 70% CPU utilization
   - Scale out: Add tasks when above target
   - Scale in: Remove tasks when below target
   - Cooldown: 60s (scale out), 300s (scale in)

2. **Memory-based Scaling**
   - Target: 80% memory utilization
   - Scale out: Add tasks when above target
   - Scale in: Remove tasks when below target
   - Cooldown: 60s (scale out), 300s (scale in)

**Limits:**
- Minimum tasks: 2 (per service)
- Maximum tasks: 8 (per service)

### Security

#### Security Groups

1. **ALB Security Group**
   - Inbound: 80, 443 from 0.0.0.0/0
   - Outbound: All traffic

2. **ECS Tasks Security Group**
   - Inbound: All ports from ALB SG
   - Inbound: All ports from self (inter-service communication)
   - Outbound: All traffic

#### IAM Roles

1. **ECS Task Execution Role**
   - Pull images from ECR
   - Write logs to CloudWatch
   - Read secrets from Secrets Manager (optional)

2. **ECS Task Role**
   - Application-level permissions
   - Access to AWS services (S3, DynamoDB, etc.)
   - CloudWatch Logs access

### Monitoring and Logging

#### CloudWatch Container Insights

**Metrics Available:**
- CPU utilization
- Memory utilization
- Network I/O
- Task count
- Service deployment status

#### CloudWatch Logs

**Log Groups:**
- `/ecs/{project}-{env}/{service-name}`
- Retention: 30 days
- Structured logging with JSON format

**Log Streams:**
- One per task
- Format: `ecs/{service}/{task-id}`

## CI/CD Pipeline

### GitHub Actions Workflows

#### 1. Build and Test (`build-test.yml`)
**Trigger:** PR to main/develop

**Steps:**
1. Checkout code
2. Setup Node.js
3. Install dependencies
4. Run tests
5. Build Docker images
6. Security scan with Trivy

#### 2. Terraform Plan (`terraform-plan.yml`)
**Trigger:** PR with Terraform changes

**Steps:**
1. Checkout code
2. Setup Terraform
3. Validate configuration
4. Generate plan
5. Comment plan on PR

#### 3. Terraform Apply (`terraform-apply.yml`)
**Trigger:** Push to main (Terraform changes)

**Steps:**
1. Checkout code
2. Setup Terraform
3. Apply changes
4. Upload outputs as artifacts

#### 4. Deploy Service (`deploy-service.yml`)
**Trigger:** Push to main (service changes) or manual

**Steps:**
1. Detect changed services
2. Build Docker images
3. Push to ECR
4. Update ECS task definition
5. Deploy to ECS
6. Wait for stability

### Deployment Strategy

**Type:** Rolling update

**Configuration:**
- Maximum percent: 200%
- Minimum healthy percent: 100%
- Circuit breaker: Enabled with rollback

**Process:**
1. ALB health check passes for new tasks
2. New tasks start serving traffic
3. Old tasks are drained and stopped
4. Deployment completes or rolls back on failure

## Scalability and Performance

### Horizontal Scaling

**Current:**
- 2 tasks per service (baseline)
- Auto-scale up to 8 tasks

**Considerations for Growth:**
- Increase max tasks per service
- Add more availability zones
- Implement caching (Redis/ElastiCache)
- Use database read replicas

### Vertical Scaling

**Current:**
- CPU: 256 units (0.25 vCPU)
- Memory: 512 MB

**Options:**
- Increase to 512 CPU / 1024 MB
- Or 1024 CPU / 2048 MB
- Update in `terraform/variables.tf`

### Performance Optimization

**Recommendations:**
1. Implement caching layer (Redis)
2. Use database connection pooling
3. Optimize Docker image size
4. Enable CloudFront CDN for static assets
5. Implement API Gateway for rate limiting

## Cost Optimization

### Current Monthly Estimate (us-east-1)

**ECS Fargate:**
- 5 services × 2 tasks × 0.25 vCPU × 0.5 GB = ~$45/month
- Auto-scaling may increase costs

**ALB:**
- 1 ALB = ~$20/month
- Data transfer = variable

**NAT Gateway:**
- 2 NAT Gateways = ~$65/month
- Data transfer = variable

**CloudWatch:**
- Logs ingestion = ~$5-10/month
- Container Insights = ~$5/month

**Total Estimated:** ~$140-160/month (baseline)

### Cost Optimization Tips

1. **Use Fargate Spot:** Save up to 70% on compute
2. **Right-size tasks:** Monitor and adjust CPU/memory
3. **Enable auto-scaling:** Scale down during low traffic
4. **Use S3 Gateway Endpoint:** Free VPC endpoint for S3
5. **Optimize log retention:** Reduce from 30 to 7 days if acceptable
6. **Single NAT Gateway:** Use one NAT for non-production environments

## High Availability

### Multi-AZ Deployment

- Services deployed across 2+ availability zones
- ALB distributes traffic across all zones
- Automatic failover on zone failure

### Health Checks

**ALB Target Group:**
- Interval: 30 seconds
- Timeout: 5 seconds
- Healthy threshold: 2
- Unhealthy threshold: 3

**ECS Container:**
- Command: HTTP GET to /health
- Interval: 30 seconds
- Timeout: 5 seconds
- Retries: 3
- Start period: 60 seconds

### Disaster Recovery

**RTO (Recovery Time Objective):** ~5 minutes
**RPO (Recovery Point Objective):** ~1 minute

**Backup Strategy:**
- Terraform state: Versioned in S3
- Docker images: Retained in ECR
- Application data: Not included (add RDS/DynamoDB backups)

## Security Best Practices

### Implemented

- ✅ SSL/TLS termination at ALB
- ✅ Private subnets for ECS tasks
- ✅ Security groups with least privilege
- ✅ IAM roles with minimal permissions
- ✅ ECR image scanning enabled
- ✅ VPC Flow Logs enabled
- ✅ Encrypted Terraform state

### Recommended Additions

- 🔲 AWS WAF on ALB
- 🔲 Secrets Manager for sensitive data
- 🔲 GuardDuty for threat detection
- 🔲 AWS Config for compliance
- 🔲 KMS encryption for logs
- 🔲 VPN/PrivateLink for admin access

## Future Enhancements

### Short-term

1. Add RDS/Aurora for persistent storage
2. Implement API Gateway with authentication
3. Add ElastiCache Redis for caching
4. Setup CloudFront CDN
5. Implement centralized logging (ELK/Datadog)

### Long-term

1. Migrate to EKS (Kubernetes) for more flexibility
2. Implement service mesh (Istio/App Mesh)
3. Add message queue (SQS/SNS) for async processing
4. Implement event sourcing with EventBridge
5. Multi-region deployment for global availability

---

**Last Updated:** 2026-02-07
