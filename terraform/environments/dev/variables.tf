variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name used in tags"
  type        = string
  default     = "dev"
}

# Existing shared platform resources, passed in by the workflow from repository variables
variable "vpc_id" {
  description = "VPC of the existing load balancer"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets in two AZs for the tasks"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Provide at least two subnets in different AZs."
  }
}

variable "ecs_cluster_arn" {
  description = "Existing ECS cluster ARN"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group of the existing load balancer"
  type        = string
}

variable "alb_listener_arn" {
  description = "Existing HTTPS listener ARN"
  type        = string
}

variable "project_name" {
  description = "Name used for all resources"
  type        = string
  default     = "sample-api"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "route_prefix" {
  description = "Path prefix routed to this service on the shared load balancer"
  type        = string
  default     = "/sample-api"

  validation {
    condition     = can(regex("^/[a-z0-9-]+$", var.route_prefix))
    error_message = "Use a single leading slash and no trailing slash, for example /sample-api."
  }
}

variable "listener_rule_priority" {
  description = "Listener rule priority, must be unused on the shared listener"
  type        = number
  default     = 103

  validation {
    condition     = var.listener_rule_priority >= 1 && var.listener_rule_priority <= 50000
    error_message = "Listener rule priority must be between 1 and 50000."
  }
}

variable "ecr_repository_name" {
  description = "Existing shared ECR repository"
  type        = string
  default     = "sample-ecr-repo"
}

variable "image_tag" {
  description = "Initial image tag, later deployments are done by the pipeline"
  type        = string
  default     = "sample-api-latest"
}

variable "cpu" {
  description = "Task CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of tasks"
  type        = number
  default     = 2
}
