# Shared repository, this service pushes images tagged with the project name
data "aws_ecr_repository" "shared" {
  name = var.ecr_repository_name
}
