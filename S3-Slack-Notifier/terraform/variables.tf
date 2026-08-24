variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used to prefix created resources."
  type        = string
  default     = "s3-slack-notifier"
}

variable "environment" {
  description = "Deployment environment label (e.g. production, staging)."
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags applied to every resource this module creates."
  type        = map(string)
  default     = {}
}

variable "existing_bucket_names" {
  description = "Names of buckets that already exist and should be registered for upload notifications. Each bucket gets this Lambda wired up as its notification target - nothing else about the bucket (encryption, versioning, public access settings) is touched. Leave empty to have this module create one new bucket instead (see new_bucket_name)."
  type        = list(string)
  default     = []
}

variable "new_bucket_name" {
  description = "Name for a new bucket to create. Only used when existing_bucket_names is empty - the two are mutually exclusive. Leave blank to auto-generate a globally-unique name."
  type        = string
  default     = ""

  validation {
    condition     = !(var.new_bucket_name != "" && length(var.existing_bucket_names) > 0)
    error_message = "Set either new_bucket_name or existing_bucket_names, not both. existing_bucket_names takes priority when both are set, so new_bucket_name would silently be ignored - this error exists so that doesn't happen quietly."
  }
}

variable "lambda_runtime" {
  description = "Lambda Python runtime."
  type        = string
  default     = "python3.13"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory in MB."
  type        = number
  default     = 128
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period for the function's log group."
  type        = number
  default     = 14
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL. The function still deploys without one, but send_slack_notification() will fail every invocation until it's set - this is not truly optional like the other two functions in this repo."
  type        = string
  default     = ""
  sensitive   = true
}
