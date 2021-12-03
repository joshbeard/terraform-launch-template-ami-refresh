data "aws_launch_template" "this" {
  name = var.launch_template_name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "lambda" {
  name                  = "${var.name}-lambda-role"
  description           = "Role for updating EC2 Launch Templates with a Lambda function"
  path                  = "/"
  permissions_boundary  = var.role_permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.assume_role.json
  force_detach_policies = true
  tags                  = var.tags
}


# This IAM policy is used by the Lambda function.
data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "ec2:DescribeImages",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions",
    ]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions = [
      "ec2:ModifyLaunchTemplate",
      "ec2:CreateLaunchTemplateVersion"
    ]
    resources = [data.aws_launch_template.this.arn]
    effect    = "Allow"
  }

  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
    ]
    effect = "Allow"
    resources = [
      "${aws_cloudwatch_log_group.this.arn}:*",
      "${aws_cloudwatch_log_group.this.arn}:*:*"
    ]
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${var.name}-lambda"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}
