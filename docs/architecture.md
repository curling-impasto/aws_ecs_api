# Architecture

## Target

```
Developer -> GitHub -> GitHub Actions (ci.yml and terraform.yml)
                          |
                          +-- Terraform -> AWS
                          |
                          +-- Docker build -> ECR -> ECS Fargate (Task 1, Task 2)
                                                          ^
Internet -> existing ALB :443 -> listener rule 103 (path prefix) -> target group :3000
```

Existing shared resources, passed in as variables: VPC, private subnets, ECS cluster, ALB security group, ALB listener.

## Repository layout

| Path | Purpose |
|---|---|
| `application/` | FastAPI code, tests, Python dependencies |
| `docker/` | Dockerfile and .dockerignore |
| `terraform/modules/` | alb (target group and listener rule), ecs (task definition, service, task security group, logs), iam |
| `terraform/environments/dev/` | Root module that wires the modules and reads existing resources |
| `.github/workflows/` | ci.yml for the app and terraform.yml for infrastructure |

## Decisions

| Decision | Choice | Trade-off |
|---|---|---|
| Workflows | Two files: ci.yml for the app, terraform.yml for infrastructure | Native path filters and no skipped-job logic, and an infra approval never blocks an app deploy. Order of infra before app is not enforced. |
| Existing VPC, subnets, cluster, ALB SG, listener | Terraform variables fed from GitHub repository variables | The runner role is denied ssm:GetParameter, so SSM data sources cannot be used. Values are duplicated from SSM and must be kept in sync. |
| Network module | Removed | Nothing to create. VPC and subnets are owned by the platform. |
| ALB integration | Listener rule priority 103 on existing 443 listener | Does not touch other services. Priority must be unique. |
| Rule condition | Path prefix, app reads ROUTE_PREFIX | Matches how the shared ALB is used by other apps. ALB does not strip the prefix, so the app must accept it. |
| TLS | Terminated at ALB, HTTP to tasks on port 3000 | Simple certificate handling. Traffic inside the VPC is not encrypted. |
| Container port | 3000, one Terraform variable | Declared once and reused by target group and security group. |
| Task security group | Port 3000 from ALB security group only | Tight blast radius. Needs the ALB security group ID. |
| Health check | Target group calls /health directly on the task | Bypasses the listener rule, so /health must work without the prefix. |
| Deployment | Rolling update with deployment circuit breaker | Simple and easy to explain. No traffic shifting, so a bad release reaches users while tasks are replaced. |
| CPU architecture | x86 | Builds natively on GitHub runners. About 20 percent more expensive than ARM64 on Fargate. |
| Pipeline flow | CI: test, build and push image, deploy to ECS, smoke test. Terraform: plan, then apply the saved plan in the same job | Minimal stages. No approval gate, because a gate needs a separate job and a second runner. |
| Runners | One job and one CodeBuild runner per workflow. CI uses docker-github-runner, Terraform uses dev-github-runner | CodeBuild starts a runner per job, so fewer jobs means less startup time. Inside the VPC, so the internal ALB is reachable. Only the docker runner is privileged. |
| AWS authentication | Runner IAM role, no OIDC and no keys | Nothing to create or rotate. The role is shared by every repo on the runner and is broad (ecr, ecs, s3 and more on all resources), so it is less least-privilege than a per-repo OIDC role. |
| Base image | python 3.12 alpine, 76 MB | Half the size of slim at 160 MB. Uses musl, so a future dependency that needs compiling may build slowly or fail. |
| Image ignore file | docker/Dockerfile.dockerignore allowlist | A .dockerignore inside docker/ is not read when the build context is the repo root. |
| ECR | Existing shared repository sample-ecr-repo, images tagged sample-api-<git sha> | No repository to manage. Tags are mutable and pull access is repository wide. |
| Terraform version | 1.5.x or newer, AWS provider ~> 6.68, lock file committed for mac and linux | Matches local and other projects. No native S3 locking, no terraform test mocks. Last open source release. |
| State backend | Existing S3 bucket sample-terraform-state, key sample-api/dev/terraform.tfstate, no lock table | Same as other projects. Pipeline concurrency group prevents parallel applies. |
| Region | us-east-1 (state bucket and platform resources) | Single region, no cross-region traffic. |
