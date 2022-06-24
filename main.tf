locals {
  source_sha256 = filesha256("${path.module}/lambda.py")
}

data "archive_file" "this" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "builds/lambda_${local.source_sha256}.zip"
}

resource "aws_lambda_function" "this" {
  architectures    = ["x86_64"]
  description      = "Function for updating EC2 Launch Template AMI IDs"
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  function_name    = var.name
  handler          = "lambda.handler"
  memory_size      = 128
  package_type     = "Zip"
  publish          = true
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.9"
  tags             = var.tags
  timeout          = var.lambda_timeout
  environment {
    variables = {
      AMI_FILTERS             = var.ami_filters,
      LAUNCH_TEMPLATE_NAME    = var.launch_template_name,
      LAUNCH_TEMPLATE_VERSION = var.launch_template_version
    }
  }
}

resource "aws_lambda_permission" "current_version_triggers" {
  count         = var.enable_cloudwatch_schedule ? 1 : 0
  function_name = aws_lambda_function.this.function_name
  qualifier     = aws_lambda_function.this.version
  #statement_id  = "Execute"
  action     = "lambda:InvokeFunction"
  principal  = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.this_schedule[0].arn
}

resource "aws_lambda_permission" "unqualified_alias_triggers" {
  count         = var.enable_cloudwatch_schedule ? 1 : 0
  function_name = aws_lambda_function.this.function_name
  #statement_id  = "TerminateInstanceEvent"
  action     = "lambda:InvokeFunction"
  principal  = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.this_schedule[0].arn
}
