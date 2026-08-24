# Security Group Auditor — Terraform

Deploys `../lambda_function.py` as a Lambda that runs on a schedule, scans
every security group in the account/region, and revokes any ingress rule
that opens port 22 (SSH) to `0.0.0.0/0`.

## What this creates

| Resource | Purpose |
|---|---|
| `aws_lambda_function.this` | The function itself, packaged directly from `../lambda_function.py` |
| `aws_iam_role.lambda` + `aws_iam_role_policy.lambda` | Execution role scoped to: describe security groups, revoke ingress rules only on security-group resources, and write to its own log group |
| `aws_cloudwatch_log_group.this` | Log group created ahead of the function, with a finite retention period |
| `aws_cloudwatch_event_rule.schedule` + `aws_cloudwatch_event_target.lambda` | EventBridge schedule trigger |
| `aws_lambda_permission.allow_eventbridge` | Grants EventBridge permission to invoke the function |

## Prerequisites

- Terraform >= 1.9
- AWS credentials with permission to create IAM roles/policies, Lambda functions, EventBridge rules, and CloudWatch log groups

## Usage

```bash
cd Security-Group-Auditor/terraform
cp terraform.tfvars.example terraform.tfvars   # edit as needed
terraform init
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Read this before applying to a real account

This function **auto-remediates on every scheduled run with no dry-run
mode and no exceptions list**. Any security group anywhere in the target
region with SSH open to the internet gets its rule revoked immediately —
including one you opened intentionally five minutes ago for a legitimate
reason. The default schedule here is every 15 minutes. If you want a safety
net, that's a change to `lambda_function.py` (e.g. an allowlist tag), not
something this Terraform module can add on its own.

## Variables

See `variables.tf` for the full list and defaults.

