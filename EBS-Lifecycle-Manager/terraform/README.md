# EBS Lifecycle Manager — Terraform

Deploys `../lambda_function.py` as a Lambda that runs daily, creates snapshots
of any EBS volume tagged `Backup: true`, and deletes its own snapshots older
than 7 days (retention is hard-coded in the Lambda source, not exposed here).

## What this creates

| Resource | Purpose |
|---|---|
| `aws_lambda_function.this` | The function itself, packaged directly from `../lambda_function.py` |
| `aws_iam_role.lambda` + `aws_iam_role_policy.lambda` | Execution role scoped to: describe volumes/snapshots, create snapshots only on `Backup: true` volumes, delete snapshots only if tagged `CreatedBy: EBSLifecycleManager`, and write to its own log group |
| `aws_cloudwatch_log_group.this` | Log group created ahead of the function, with a finite retention period |
| `aws_cloudwatch_event_rule.schedule` + `aws_cloudwatch_event_target.lambda` | EventBridge schedule trigger |
| `aws_lambda_permission.allow_eventbridge` | Grants EventBridge permission to invoke the function |

## Prerequisites

- Terraform >= 1.9
- AWS credentials with permission to create IAM roles/policies, Lambda functions, EventBridge rules, and CloudWatch log groups
- At least one EBS volume tagged `Backup: true` if you want the run to actually produce a snapshot

## Usage

```bash
cd EBS-Lifecycle-Manager/terraform
cp terraform.tfvars.example terraform.tfvars   # edit as needed
terraform init
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Variables

See `variables.tf` for the full list and defaults. The only one worth calling
out: `slack_webhook_url` is optional — leave it blank and the function runs
in silent mode exactly as the source code already handles.

