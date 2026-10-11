# aws_ecs_api

Sample API: a small FastAPI service on ECS Fargate behind an existing internal ALB at `/sample-api`. Deployed with Terraform and GitHub Actions.

## Run locally

```bash
cd application
pip install -r requirements-dev.txt
pytest
cd .. && docker build -f docker/Dockerfile -t sample-api .
docker run -p 3000:3000 -e ROUTE_PREFIX=/sample-api sample-api
curl localhost:3000/sample-api/health
```

## Deploy

Two workflows run on push to `main`, each only when its own paths change. Pull requests run the same checks without deploying.

| Workflow | Triggers on | Does |
|---|---|---|
| `ci.yml` | `application/**`, `docker/**` | One job: test, build image, push to ECR, deploy to ECS, smoke test |
| `terraform.yml` | `terraform/**` | One job: fmt, init, validate, plan. On push to `main` it also applies that plan |

Each workflow uses one CodeBuild runner and its IAM role, so there are no AWS keys.

### How a push reaches ECS

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Developer
    participant GH as GitHub
    participant CB as CodeBuild project
    participant R as Runner in VPC
    participant IAM as Runner IAM role
    participant ECR as ECR
    participant ECS as ECS service
    participant ALB as Internal ALB

    Dev->>GH: Push to main
    GH->>GH: Path filter picks ci.yml or terraform.yml
    GH->>CB: Org webhook, workflow job queued
    CB->>R: Start runner from the label in runs-on
    R->>GH: Register and pick up the job
    CB->>IAM: Runner uses the project service role

    alt terraform.yml on dev-github-runner
        R->>R: fmt, init, validate, plan
        R->>IAM: Apply saved plan
        IAM->>ECS: Create or update service, target group, listener rule
    else ci.yml on docker-github-runner
        R->>R: pytest and docker build
        R->>IAM: Push image and register task definition
        IAM->>ECR: Push sample-api image
        IAM->>ECS: Deploy new task definition
        ECS->>ECS: Rolling update with circuit breaker
        ECS->>ALB: New tasks pass /health
        R->>ALB: Smoke test /health and /version
    end

    R->>GH: Job result
    CB->>R: Runner is removed
```

First time: let `terraform.yml` apply, then run `ci.yml` again (`workflow_dispatch`). The service exists only after the apply, and the first image only after the first CI run.

### Repository variables

| Variable | Used by |
|---|---|
| `GIT_RUNNER` | `terraform.yml`, runner name (`ci.yml` always uses `docker-github-runner`) |
| `SMOKE_TEST_BASE_URL` | `ci.yml` |
| `VPC_ID`, `SUBNET_IDS`, `ECS_CLUSTER_ARN`, `ALB_SECURITY_GROUP_ID`, `ALB_LISTENER_ARN` | `terraform.yml`, existing platform values |

`SUBNET_IDS` is a JSON list, for example `["subnet-a","subnet-b"]`.

### Sample names to replace

| Name in this repo | What it stands for |
|---|---|
| `sample-ecr-repo` | Existing shared ECR repository |
| `sample-cluster` | Existing ECS cluster |
| `sample-terraform-state` | Existing S3 bucket for Terraform state |
| `sample-api` | Service, container and URL prefix |

## Layout

| Path | Purpose |
|---|---|
| `application/` | API code and tests |
| `docker/` | Dockerfile, build from the repo root |
| `terraform/` | Modules and the dev environment |
| `.github/workflows/` | CI and Terraform workflows |
| `docs/architecture.md` | Design decisions and trade-offs |
