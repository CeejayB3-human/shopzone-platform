# ShopZone Infrastructure — Terraform

Infrastructure as Code for ShopZone's production platform on AWS, deployed and
maintained by Descasio. This repository is the evidence referenced under
**REL-001 — Automate Deployment and Leverage Infrastructure-as-Code Tools**
in the AWS DevOps Competency assessment.

## What this repo proves for REL-001

| Control requirement | Where it's satisfied |
|---|---|
| Infrastructure changes automated via a scripting/IaC tool | Entire environment defined in `.tf` files, applied via Terraform |
| No manual AWS Console changes to production | `.github/workflows/terraform.yml` — `terraform apply` runs **only** inside GitHub Actions, gated on `main`, after `validate` + `plan` succeed |
| Change history / version control | Every infrastructure change is a reviewed pull request against this repo |
| Prevents conflicting concurrent changes | Remote state in S3 + DynamoDB locking (`versions.tf`) |

## Architecture

```
                              Users
                                │
                    Application Load Balancer (public, TLS)
                                │
          ┌─────────────────────┴─────────────────────┐
     AZ-A │ Private App Subnet                          │ AZ-B
          │  ECS Fargate Task (auto-scaled 2–6)          │  ECS Fargate Task
          └─────────────────────┬─────────────────────┘
                                │
                    Amazon RDS PostgreSQL (Multi-AZ)
                                │
                      Amazon S3 (product images)

  Amazon ECR (container registry) · Amazon CloudWatch (logs, metrics, alarms)
```

Full diagram context and the reasoning behind each design choice are covered
in the accompanying speaker guide (DOC-001 / REL-001 responses).

## Repository layout

```
.
├── versions.tf              # Providers + S3/DynamoDB remote state backend
├── variables.tf              # All configurable inputs
├── network.tf                 # VPC, subnets (public/private-app/private-db), NAT, IGW
├── security_groups.tf        # ALB → app → DB, tightly scoped (no flat access)
├── alb.tf                     # Application Load Balancer, listeners, target group
├── ecr.tf                      # Container registry, scan-on-push, immutable tags
├── ecs.tf                       # Cluster, task definition, Fargate service, auto scaling
├── rds.tf                        # Multi-AZ PostgreSQL, automated backups
├── s3.tf                          # Product asset storage, versioned, encrypted
├── iam.tf                          # Least-privilege roles, GitHub OIDC federation
├── ssm.tf                           # Runtime config via Parameter Store / Secrets Manager
├── cloudwatch.tf                     # Dashboard + alarms (scaling, health, storage)
├── outputs.tf                         # Useful outputs (ALB DNS, ECR URL, etc.)
├── terraform.tfvars.example            # Example variable values
└── .github/workflows/
    ├── terraform.yml                    # Validate → plan → (on main) apply
    └── deploy.yml                        # Build → test → scan → deploy app to ECS
```

## How a change actually reaches production

1. An engineer opens a pull request changing one or more `.tf` files.
2. `terraform.yml` runs automatically: `fmt -check`, `validate`, and `plan`,
   posting the plan output as a PR comment for review.
3. A second engineer reviews and approves the PR — this is the code review
   gate; nobody applies infrastructure changes unreviewed.
4. On merge to `main`, the same workflow runs `terraform apply` **inside
   GitHub Actions**, using short-lived credentials obtained via OIDC — no
   engineer ever runs `terraform apply` from a laptop, and no one edits
   resources directly in the AWS Console.
5. Application code changes follow a parallel path in `deploy.yml`: build →
   test → ECR vulnerability scan (deployment blocked on CRITICAL findings) →
   rolling deploy to ECS with automatic rollback if health checks fail.

## Getting started (for reference / local plan review only — apply always
runs through CI)

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -var-file="terraform.tfvars"
```

`terraform apply` is intentionally **not** part of local usage instructions —
production applies happen exclusively through the `terraform.yml` workflow.

## Design notes

- **Two Availability Zones throughout** — public, private-app, and
  private-db subnets are each duplicated across AZ-A and AZ-B, with one NAT
  Gateway per AZ so an AZ failure never blocks outbound access for the
  other.
- **RDS compute is not auto-scaled** — `db_instance_class` is a deliberate,
  reviewed setting. Storage autoscaling *is* enabled. This mirrors the same
  approach used for other Descasio customers: the data layer changes size
  under controlled review, while the stateless application layer scales
  freely.
- **Every secret and config value is externalized** — `ssm.tf` and
  `aws_secretsmanager_secret` resources mean nothing sensitive is hardcoded
  in the task definition or committed to this repository.
