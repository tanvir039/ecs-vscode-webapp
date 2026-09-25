# ECS code-server deployment

A production-style deployment of [coder/code-server](https://github.com/coder/code-server) on AWS ECS Fargate, built manually in the AWS Console first, then fully rebuilt as modular Terraform, with GitHub Actions CI/CD authenticating via OIDC (no static AWS keys).

Live at: `https://tm.tanvirahmed.uk` (torn down between sessions to avoid idle cost — see [Reproducing this deployment](#reproducing-this-deployment))

## Overview

This project takes an open-source, non-trivial application (code-server — a full VS Code server, not a toy "hello world" app) and deploys it the way a real workload would be: containerised, fronted by an ALB with a real domain and HTTPS, orchestrated by ECS Fargate, and deployed through an automated pipeline rather than by hand.

The brief called for exactly this progression, and the project follows it in order:

1. Run the app locally, outside Docker
2. Containerise it (multi-stage, non-root, minimal image)
3. Push to a private container registry (ECR)
4. Deploy manually via the AWS Console ("ClickOps") to understand every moving part
5. Tear it down and rebuild identically as modular Terraform
6. Automate builds and deployments with GitHub Actions, using OIDC

## Architecture

![Runtime architecture](docs/architecture.svg)

A request reaches `tm.tanvirahmed.uk` via Route 53, hits an Application Load Balancer (TLS terminated with an ACM certificate, HTTP forced to redirect to HTTPS), and is forwarded to a single ECS Fargate task. That task runs two containers sharing one network interface (`awsvpc` mode):

- **nginx-sidecar** (port 8081) — the only container the ALB ever talks to. It exposes `/health`, which does **not** just return a static "ok" — it performs an internal `auth_request` subrequest to code-server's own `/healthz` endpoint over loopback before answering, so a genuinely dead backend is reported as unhealthy rather than the sidecar lying about its own liveness. Everything else is reverse-proxied straight through to code-server, including the WebSocket upgrade needed for the integrated terminal.
- **code-server-app** (port 8080) — the actual application, reachable by nginx only, never directly by the ALB.

Supporting services: the task pulls its images from **ECR** at startup, resolves its login password from **Secrets Manager** (never stored in Terraform state or CI), and streams both containers' logs to **CloudWatch**.

### A deliberate departure from "standard" AWS reference architecture

There is no private subnet and no NAT Gateway anywhere in this design. The ECS task runs in a **public subnet** with a public IP, and the actual security boundary is the security group (`ecs-task-sg`), which only accepts inbound traffic from the ALB's security group (`alb-sg`) — never from the wider internet. This was a conscious cost decision: a NAT Gateway costs a fixed hourly rate plus per-GB data charges indefinitely, which isn't justified for a project at this scale. The tradeoff is documented, not accidental.

### CI/CD flow

![CI/CD architecture](docs/cicd-architecture.svg)

Two independent GitHub Actions workflows, deliberately connected only through a human decision rather than an automatic chain:

- **`build-push.yml`** — triggers automatically on every push to `main` that touches `app/**`. Builds both images, tags them with the short git commit SHA, pushes to ECR. Uses a narrow IAM role (`github-actions-ecr-push`) that can only push to these two specific ECR repositories.
- **`terraform-deploy.yml`** — triggers only via manual `workflow_dispatch`, requiring the operator to explicitly type in the image tag to deploy (no default value). Runs `terraform fmt -check`, `validate`, and `tflint` as a quality gate, then `plan`/`apply`, waits for the ECS service to genuinely stabilise, then retries a real `/health` check against the live domain and fails the pipeline if it doesn't return `200`. Uses a broader IAM role (`github-actions-terraform-deploy`), scoped as tightly as Terraform's own needs allow.

Deploy is a deliberate gate rather than automatic-on-push, mirroring a common real-world pattern: build continuously, promote/deploy on purpose.

## Repository structure

```
.
├── app/
│   ├── code-server/
│   │   ├── Dockerfile          # multi-stage, non-root, debian:bookworm-slim
│   │   └── .dockerignore
│   └── nginx/
│       ├── Dockerfile          # nginxinc/nginx-unprivileged, non-root by default
│       ├── nginx.conf          # auth_request health check, websocket upgrade
│       └── .dockerignore
├── bootstrap/                  # one-time, manually-applied foundational infra
│   ├── main.tf                 # S3 state bucket (versioned, encrypted)
│   ├── oidc.tf                 # GitHub OIDC provider + two IAM roles
│   ├── secrets.tf              # Secrets Manager secret for PASSWORD
│   └── terraform.tfvars        # gitignored — real password value
├── infra/                      # the routinely destroy/apply'd application stack
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── backend.tf              # S3 backend, native locking
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/
│       ├── ecr/
│       ├── alb/
│       ├── ecs/
│       ├── acm/
│       └── dns/
├── .github/workflows/
│   ├── build-push.yml
│   └── terraform-deploy.yml
└── docs/
    ├── architecture.svg
    ├── cicd-architecture.svg
    └── screenshots/
```

## Design decisions

| Decision | Reasoning |
|---|---|
| nginx sidecar in front of code-server | code-server has no `/health` route matching the brief's contract. The sidecar genuinely checks code-server's own `/healthz` before answering, rather than returning a hardcoded `200`. |
| `debian:bookworm-slim`, not Alpine, for code-server | code-server's official release tarball bundles a prebuilt `node-pty` binary linked against glibc. Alpine uses musl, which breaks that binary — a well-documented, common failure mode for Node apps with native addons on Alpine. |
| Non-root containers | `appuser` for code-server (manual `useradd`/`COPY --chown`/`USER`); `nginxinc/nginx-unprivileged` for nginx, which solves it out of the box. |
| Public subnets, no NAT Gateway | Private subnets require a NAT Gateway to reach ECR/AWS APIs, costing ~$32+/month indefinitely. The task instead gets a public IP directly, with the security group — not subnet isolation — as the actual access boundary. |
| SHA-tagged, immutable ECR images | Traceability between an exact commit and an exact deployed image. Immutability prevents a tag being silently overwritten. |
| Hand-rolled ECS Terraform (no community module) | This is the genuinely custom part of the project (a two-container sidecar task). Writing it explicitly, rather than fighting a generic module's abstraction, was the more instructive choice. |
| Security group *objects* live in their module; cross-referencing *rules* live in the root | `alb-sg` and `ecs-task-sg` each need the other's ID. Neither module can see the other's resources, so the rules that reference both have to live where both are visible — the root module — avoiding a circular dependency. |
| Route 53 hosted zone is not Terraform-managed | Destroying and recreating a hosted zone generates a new set of nameservers every time, requiring re-delegation from the domain's registrar (Cloudflare) and a fresh propagation wait. Created once, manually, and referenced everywhere else via a `data` source. |
| Secrets Manager secret created in `bootstrap/`, referenced (not created) in `infra/` | If the secret's value were set via a Terraform variable inside `infra/`, the plaintext would sit in `infra/`'s state file and need to be supplied on every `apply`/CI run. Creating it once in the rarely-touched `bootstrap/` stack means `infra/` and CI only ever handle an ARN, never the plaintext password. |
| Two separate GitHub Actions workflows, connected by a manual SHA input | Build is safe to automate on every push. Deploy can cost money and modify live infrastructure, so it's a deliberate `workflow_dispatch` gate requiring a human to explicitly choose which image tag to deploy — matching the brief's own hint to pair a trigger-based pipeline with `workflow_dispatch`. |
| Two narrowly-scoped IAM roles for CI, not one broad role | The build/push job only ever needs ECR push permissions. The Terraform job needs much broader access. Splitting them means a compromised build job can't touch infrastructure. |

## Known limitations

- **No persistent storage.** ECS Fargate tasks are ephemeral; anything created inside the code-server workspace is lost on task restart. Adding an EFS volume mount was considered and deliberately deferred as out of scope for this project's MVP.
- **Single task, no real multi-AZ redundancy in practice.** The infrastructure spans two Availability Zones (a hard requirement for the ALB), but `desired_count = 1` means only one task is ever actually running at a time. The architecture diagram reflects this honestly rather than implying duplicated capacity that doesn't exist.
- **The Route 53 hosted zone, the Secrets Manager secret, and the GitHub OIDC trust setup are one-time manual/local steps**, not something a single `terraform apply` reproduces end-to-end from zero in a new AWS account. This was a deliberate choice (see Design decisions above) rather than an oversight — full automation of the Cloudflare NS delegation step specifically would require adding the Cloudflare Terraform provider and a second set of credentials, which wasn't judged worth the added complexity for a single-maintainer learning project.
- **ECR lives inside `infra/`, not `bootstrap/`.** This creates a real bootstrapping order dependency: `build-push.yml` cannot push images until the ECR repositories exist, but those repositories are only created by `terraform apply` on `infra/`. In practice this means the very first deploy of a fresh `infra/` stack has to be run once with a placeholder `image_tag` (the ECS service will fail to place tasks until real images exist — harmless, since `terraform apply` doesn't block on tasks actually starting), `build-push.yml` can then push real images, and `terraform-deploy.yml` is re-run with the real tag to let the service stabilise. It also means every full `terraform destroy` of `infra/` deletes the pushed images along with everything else, requiring a re-push before the next deploy. The cleaner design — moving the `ecr` module into `bootstrap/`, alongside the other foundational, rarely-destroyed resources (the state bucket, OIDC roles, Secrets Manager secret) — was identified but deliberately not carried out this late in the project, to avoid re-testing the full pipeline against a Terraform state migration this close to completion. Listed here as the clearest concrete improvement for a next iteration.

## Reproducing this deployment

### Prerequisites

- An AWS account
- A domain with a DNS provider that supports delegating a subdomain via NS records (this project used Cloudflare)
- Terraform >= 1.10, Docker, AWS CLI, a GitHub repository (forked or your own)

### 1. Bootstrap (one time, run locally)

```bash
cd bootstrap
# create terraform.tfvars with a real code_server_password value
terraform init
terraform apply
```

This creates the S3 state bucket, the GitHub OIDC provider and IAM roles, and the Secrets Manager secret. Note the two role ARNs it outputs — they're referenced directly in the two workflow files.

### 2. DNS delegation (one time, manual)

```bash
aws route53 create-hosted-zone --name tm.<your-domain> --caller-reference "$(date +%s)"
```

Take the four nameservers from the output and add them as `NS` records for the `tm` subdomain at your DNS provider. Verify with `dig NS tm.<your-domain>` before continuing.

### 3. First-time deploy (creates the ECR repositories)

The ECR repositories are created by `infra/`, but `build-push.yml` needs them to exist before it can push anything — so on a genuinely fresh AWS account, deploy once first with any placeholder tag:

```
Actions → Terraform Deploy → Run workflow → image_tag: bootstrap
```

The ECS service will fail to place tasks (no image exists yet at that tag) — this is expected and harmless; every other resource, including the ECR repositories, will have been created successfully.

### 4. Build and push the real images

Push a commit touching `app/**` to `main` — `build-push.yml` will build and push both images automatically. Note the short SHA it produces.

### 5. Deploy for real

Go to **Actions → Terraform Deploy → Run workflow**, and enter the SHA from step 4 as the `image_tag` input. The service should now stabilise successfully.

> This two-step first deploy is a direct consequence of the ECR module living in `infra/` rather than `bootstrap/` — see [Known limitations](#known-limitations). On every subsequent redeploy where the repositories already exist and hold images, step 3 isn't needed.

### 5. Verify

```bash
curl -i https://tm.<your-domain>/health
```

Should return `200 {"status": "ok"}`.

### Tearing down

```bash
cd infra
terraform destroy
```

`bootstrap/` is left running — it holds no meaningful ongoing cost and is what lets `infra/` be rebuilt cleanly without re-doing DNS delegation, OIDC trust, or the secret.

## Debugging log — real issues hit and fixed

Kept deliberately, since the debugging is as much a part of this project as the final working state.

1. **`ecs-task-sg` had no outbound rule at all.** Security groups created via the AWS Console get an implicit "allow all outbound" rule automatically; a Terraform-managed `aws_security_group` with no `egress` block does not replicate that default. The task could resolve ECR's DNS name but every connection attempt timed out — traced via `lsof`-style layer-by-layer checking (route table, then security group rules) rather than guessing.
2. **`terraform destroy` deletes ECR repository contents, not just the repositories.** Terraform manages infrastructure *shape*, never application artifacts — destroying and reapplying the stack means the images have to be re-pushed before the next deploy will succeed. Also surfaced a Terraform-specific gotcha: `force_delete = true` on a resource has to be applied *before* a subsequent `destroy`, since destroy operations act on the last-applied state, not a same-run edit to the config.
3. **`PowerUserAccess` deliberately excludes IAM permissions.** The Terraform deploy role could plan and apply almost everything, but failed on `iam:GetRole` when managing the ECS execution role — a supplemental, narrowly-scoped IAM policy (limited to `ecs-code-server-*` role names, including `iam:PassRole`) was added alongside `PowerUserAccess` rather than reaching for a broader managed policy.
4. **A one-word schema mismatch silently broke authentication for days.** The ECS container definition used an `environment` block with a `valueFrom` key inside it — syntactically valid JSON, but `valueFrom` is only meaningful inside a `secrets` block. ECS silently ignored the unrecognised field. `terraform validate`, `plan`, and `tflint` all passed cleanly throughout, because the mistake was semantic (what ECS's API expects inside that specific key), not structural. Only caught by reading actual CloudWatch startup logs and noticing code-server reported `Using password from config.yaml` instead of `Using password from $PASSWORD` — a reminder that static analysis can't substitute for verifying real runtime behaviour against actual evidence.
5. **A stale local `terraform.tfvars`** caused a `CannotPullContainerError` after a local `apply` was run outside the CI pipeline — the file still referenced a commit SHA from early in the project, silently overriding whatever tag the pipeline had actually been deploying.

## Tech stack

Docker · Terraform · AWS (ECS Fargate, ALB, VPC, ECR, Route 53, ACM, Secrets Manager, CloudWatch, IAM/OIDC) · GitHub Actions · nginx · code-server
