data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "lambda_permissions" {
  # describe_security_groups() does not support resource-level restriction.
  statement {
    sid       = "AllowDescribe"
    effect    = "Allow"
    actions   = ["ec2:DescribeSecurityGroups"]
    resources = ["*"]
  }

  # The function audits every security group in the account by design (no
  # tag filter in the source), so this can't be scoped further than the
  # security-group resource type itself.
  statement {
    sid       = "AllowRevokeOnSecurityGroupsOnly"
    effect    = "Allow"
    actions   = ["ec2:RevokeSecurityGroupIngress"]
    resources = ["arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*"]
  }

  statement {
    sid       = "AllowLogging"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.this.arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${local.function_name}-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}
