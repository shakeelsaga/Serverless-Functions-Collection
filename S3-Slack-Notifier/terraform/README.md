# S3 Slack Notifier — Terraform

Deploys `../lambda_function.py` as a shared notification service: any S3
bucket can be registered against it, and every object uploaded to a
registered bucket triggers a 1-hour presigned download link posted to
Slack.

## Two ways to register a bucket

**Create a new bucket** (default) — leave `existing_bucket_names` empty.
This module provisions one bucket for you: private, encrypted (SSE-S3),
versioned. Set `new_bucket_name` to name it yourself, or leave it blank
for an auto-generated, globally-unique name.

**Register one or more existing buckets** — set `existing_bucket_names` to
a list of bucket names that already exist. This module does not touch
their encryption, versioning, or public-access settings — it only adds
this Lambda as their notification target. Any number of buckets can share
this one Lambda deployment; add or remove names from the list and
re-apply to change what's registered.

The two are mutually exclusive per deployment — if `existing_bucket_names`
is set, `new_bucket_name` is ignored, and `terraform plan` refuses to
proceed if both are set at once, so that ignoring doesn't happen silently.

## Before you register an existing bucket

`aws_s3_bucket_notification` owns a bucket's entire notification
configuration — applying it replaces whatever's already there in one
shot, it doesn't merge. Only put a bucket in `existing_bucket_names` if it
has no other notification configured (Slack-related or not). If it does,
that configuration is deleted on `terraform apply`, silently.

## What this creates

| Resource | Purpose |
|---|---|
| `aws_lambda_function.this` | The function itself, packaged directly from `../lambda_function.py` |
| `aws_iam_role.lambda` + `aws_iam_role_policy.lambda` | Execution role scoped to `s3:GetObject` on every registered bucket's objects, and writes to its own log group |
| `aws_cloudwatch_log_group.this` | Log group created ahead of the function, with a finite retention period |
| `aws_s3_bucket.new` (+ public access block, SSE, versioning) | Only created in "new bucket" mode |
| `data.aws_s3_bucket.existing` | Only used in "existing bucket" mode — one lookup per registered bucket |
| `aws_s3_bucket_notification.this` + `aws_lambda_permission.allow_s3` | One pair per registered bucket, wiring `s3:ObjectCreated:*` events to the function |

## Prerequisites

- Terraform >= 1.9
- AWS credentials with permission to create S3 buckets (new-bucket mode) or read bucket metadata (existing-bucket mode), plus IAM roles/policies and Lambda functions
- A Slack incoming webhook URL — see the note below, this one isn't optional

## Usage

```bash
cd S3-Slack-Notifier/terraform
cp terraform.tfvars.example terraform.tfvars   # edit as needed
terraform init
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Important: this function is not silent-mode-safe

The EBS and Security-Group functions in this repo skip Slack cleanly when
no webhook is set. This one doesn't: `send_slack_notification()` returns
`False` if `SLACK_WEBHOOK_URL` is missing, and `lambda_handler` turns that
into a `500` response on every single upload. Set `slack_webhook_url`
before applying, or every invocation will show as a failure in CloudWatch
even though the presigned URL was generated fine.

## Variables

See `variables.tf` for the full list and defaults.
