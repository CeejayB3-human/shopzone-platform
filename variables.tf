variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (e.g. production, staging)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Short project identifier used in resource names"
  type        = string
  default     = "shopzone"
}

variable "vpc_cidr" {
  description = "CIDR block for the ShopZone VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Two Availability Zones the platform is spread across"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for the public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDRs for the private application subnets (one per AZ)"
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDRs for the private database subnets (one per AZ)"
  type        = list(string)
  default     = ["10.20.20.0/24", "10.20.21.0/24"]
}

# --- ECS / Fargate -----------------------------------------------------

variable "container_image" {
  description = "Full ECR image URI:tag deployed by the pipeline (overridden per release)"
  type        = string
}

variable "container_port" {
  description = "Port the ShopZone application listens on inside the container"
  type        = number
  default     = 3000
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory (MiB)"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Baseline number of running tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum tasks for Service Auto Scaling"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum tasks for Service Auto Scaling (covers ~2x peak demand)"
  type        = number
  default     = 6
}

variable "cpu_target_value" {
  description = "Target average CPU utilization (%) that triggers scale-out/in"
  type        = number
  default     = 60
}

variable "request_count_target" {
  description = "Target ALB requests per target that triggers scale-out/in"
  type        = number
  default     = 1000
}

# --- RDS -----------------------------------------------------------------

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

variable "db_instance_class" {
  description = "RDS instance class (deliberately sized/reviewed by hand, not auto-scaled)"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage (GB)"
  type        = number
  default     = 50
}

variable "db_max_allocated_storage" {
  description = "Ceiling for RDS storage autoscaling (GB)"
  type        = number
  default     = 500
}

variable "db_name" {
  description = "Application database name"
  type        = string
  default     = "shopzone"
}

variable "db_username" {
  description = "Master username for RDS (password is generated and stored in Secrets Manager, never in code)"
  type        = string
  default     = "shopzone_admin"
}

variable "db_backup_retention_days" {
  description = "Automated RDS snapshot retention, supporting recovery within the RPO target"
  type        = number
  default     = 14
}
