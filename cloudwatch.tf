resource "aws_cloudwatch_event_rule" "this_schedule" {
  count               = var.enable_cloudwatch_schedule ? 1 : 0
  name                = "${var.name}-schedule"
  description         = "Trigger ${var.name} Lambda function on a schedule"
  schedule_expression = var.cloudwatch_schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "this_schedule" {
  count     = var.enable_cloudwatch_schedule ? 1 : 0
  rule      = aws_cloudwatch_event_rule.this_schedule[0].name
  target_id = "TriggerTerminateLambda"
  arn       = aws_lambda_function.this.arn
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.logging_retention_in_days
  tags              = var.tags
}