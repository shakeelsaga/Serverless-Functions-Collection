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

# NOTE: the "Backup" / "CreatedBy=EBSLifecycleManager" tag values below mirror
# the filters hard-coded in lambda_function.py. If those filters change, this
# policy must be updated to match, or the function will lose access.
data "aws_iam_policy_document" "lambda_permissions" {
  # describe_volumes / describe_snapshots do not support resource-level
  # restriction, so these two must stay scoped to Resource "*".
  statement {
    sid       = "AllowDescribe"
    effect    = "Allow"
    actions   = ["ec2:DescribeVolumes", "ec2:DescribeSnapshots"]
    resources = ["*"]
  }

  # Only allow snapshotting volumes that already carry the Backup=true tag.
  statement {
    sid       = "AllowSnapshotOfTaggedVolumesOnly"
    effect    = "Allow"
    actions   = ["ec2:CreateSnapshot"]
    resources = ["arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Backup"
      values   = ["true", "True"]
    }
  }

  # CreateSnapshot also touches the not-yet-existing snapshot resource; this
  # cannot carry a tag condition since the snapshot doesn't exist yet.
  # NOTE: account ID is deliberately omitted here - AWS's own policy for this
  # exact scenario (see the "Tag Amazon EBS Snapshots on Creation" AWS
  # Compute Blog post) uses arn:...::snapshot/* with an empty account field.
  # The equivalent ARN with a real account ID simply never matches.
  statement {
    sid       = "AllowSnapshotResourceCreation"
    effect    = "Allow"
    actions   = ["ec2:CreateSnapshot"]
    resources = ["arn:aws:ec2:*::snapshot/*"]
  }

  # Tagging is only permitted as part of the CreateSnapshot call itself, not
  # as a standalone action against arbitrary snapshots.
  statement {
    sid       = "AllowTaggingOnSnapshotCreation"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*::snapshot/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSnapshot"]
    }
  }

  # Deletion is restricted to snapshots this function created itself,
  # matching the app-level filter in backup_cleanup().
  statement {
    sid       = "AllowDeleteOwnSnapshotsOnly"
    effect    = "Allow"
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["arn:aws:ec2:*::snapshot/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/CreatedBy"
      values   = ["EBSLifecycleManager"]
    }
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
