variable "name" {
  description = "Target group name"
  type        = string
}

variable "vpc_id" {
  description = "VPC of the existing load balancer"
  type        = string
}

variable "listener_arn" {
  description = "Existing HTTPS listener ARN"
  type        = string
}

variable "listener_rule_priority" {
  description = "Listener rule priority, must be unique on the listener"
  type        = number
}

variable "path_prefix" {
  description = "Path prefix routed to this service"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "health_check_path" {
  description = "Target group health check path"
  type        = string
  default     = "/health"
}
