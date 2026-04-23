# poc-flask-celery-gcp

Flask + Celery + GCP proof of concept.

## Architecture

```
Internet
   │
   ▼
Cloud Run (Flask API)          ← submits tasks, queries results
   │  VPC connector
   ▼
Cloud Memorystore (Redis)      ← Celery broker (db/0) + backend (db/1)
   ▲
   │  private VPC
Compute Engine MIG             ← Celery workers (Container-Optimized OS)
```

## Task

`tasks.monte_carlo_pi` — estimates Pi via Monte Carlo sampling using numpy.
CPU-bound, reports progress every 500k iterations. Takes ~5–30s for 10M–100M iterations on `e2-standard-2`.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness check |
| POST | `/jobs` | Submit job — body: `{"iterations": 10000000}` |
| GET | `/jobs/<id>` | Poll status — returns `PENDING`, `PROGRESS`, `SUCCESS`, `FAILURE` |

## Prerequisites

- `gcloud` CLI authenticated
- `terraform` >= 1.5
- `docker`
- GCP project with billing enabled

## Local

```bash
podman-compose up -d
```

## Deploy

```bash
cd terraform

cat > terraform.tfvars << EOF
project_id = "your-project-id"
EOF

terraform init

terraform plan -out plan.out -target=google_artifact_registry_repository.repo -target=google_project_iam_member.cloudbuild_storage -target=google_project_iam_member.cloudbuild_ar_writer

terraform apply -target=google_artifact_registry_repository.repo -target=google_project_iam_member.cloudbuild_storage -target=google_project_iam_member.cloudbuild_ar_writer plan.out

REPO_URL=$(terraform output -raw artifact_registry_url)

gcloud builds submit ../api --tag="${REPO_URL}/api:latest"
gcloud builds submit ../worker --tag="${REPO_URL}/worker:latest"

terraform plan -out plan.out

terraform apply plan.out
```

## Test

```bash
cd terraform

API_URL=$(terraform output -raw api_url)

curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  "$API_URL/health"

curl -sH "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -H "Content-Type: application/json" \
  -X POST "$API_URL/jobs" \
  -d '{"iterations": 100000000}' | jq

curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
   "${API_URL}/jobs/JOB_ID"
```

## Tear down

```bash
terraform destroy
```
