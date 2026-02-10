variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ecs-microservices"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "domain_name" {
  description = "Domain name for the application (for SSL certificate)"
  type        = string
  default     = "yourdomain.com"
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for SSL/TLS"
  type        = string
  default     = ""
}

variable "container_insights_enabled" {
  description = "Enable CloudWatch Container Insights for ECS cluster"
  type        = bool
  default     = true
}

variable "desired_count" {
  description = "Desired number of tasks for each service"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "CPU units for Fargate tasks"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Memory for Fargate tasks"
  type        = string
  default     = "512"
}

variable "services" {
  description = "Map of microservices to deploy"
  type = map(object({
    name          = string
    port          = number
    health_check_path = string
    cpu           = string
    memory        = string
    desired_count = number
  }))
  default = {
    users = {
      name          = "users-service"
      port          = 3001
      health_check_path = "/health"
      cpu           = "256"
      memory        = "512"
      desired_count = 2
    }
    products = {
      name          = "products-service"
      port          = 3002
      health_check_path = "/health"
      cpu           = "256"
      memory        = "512"
      desired_count = 2
    }
    orders = {
      name          = "orders-service"
      port          = 3003
      health_check_path = "/health"
      cpu           = "256"
      memory        = "512"
      desired_count = 2
    }
    payments = {
      name          = "payments-service"
      port          = 3004
      health_check_path = "/health"
      cpu           = "256"
      memory        = "512"
      desired_count = 2
    }
    notifications = {
      name          = "notifications-service"
      port          = 3005
      health_check_path = "/health"
      cpu           = "256"
      memory        = "512"
      desired_count = 2
    }
  }
}
