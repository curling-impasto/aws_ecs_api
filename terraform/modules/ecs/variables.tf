variable "name" {
  description = "Service, family and container name"
  type        = string
}

variable "cluster_arn" {
  description = "Existing ECS cluster ARN"
  type        = string
}

variable "vpc_id" {
  description = "VPC for the task security group"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets in two or more AZs"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Existing load balancer security group"
  type        = string
}

variable "target_group_arn" {
  description = "Target group the service registers tasks in"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "image" {
  description = "Initial container image including tag"
  type        = string
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
  description = "Number of tasks, at least 2 for availability"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_count >= 2
    error_message = "Use at least 2 tasks for high availability."
  }
}

variable "health_check_grace_period" {
  description = "Seconds before load balancer health checks count"
  type        = number
  default     = 30
}

variable "execution_role_arn" {
  description = "Task execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "Task role ARN"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 7
}

variable "route_prefix" {
  description = "Path prefix the application is served under"
  type        = string
}
