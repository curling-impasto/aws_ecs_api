variable "name" {
  description = "Name prefix for the roles"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ECR repository the task may pull from"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group the task may write to"
  type        = string
}
