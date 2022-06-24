variable "name" {
  description = "The name to use for resources."
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to resources."
  type        = map(any)
  default     = {}
}

variable "permissions_boundary" {
  description = "An optional IAM permissions boundary to use when creating IAM roles."
  type        = string
  default     = null
}

variable "logging_retention_in_days" {
  description = "The number of days to retain logs in CloudWatch."
  type        = number
  default     = 30
}

variable "ami_filters" {
  description = "String of key/value pairs for the AMI filter. Refer to lambda.py for more info. For example: name=amzn2-ami-hvm-2.*-x86_64-ebs;owner-alias=amazon"
  type        = string
}

variable "launch_template_name" {
  description = "The name of the launch template to check and update."
  type        = string
}

variable "launch_template_version" {
  description = "The version of the launch template to check ($Default, $Latest)."
  type        = string
  default     = "$Default"
}

variable "enable_cloudwatch_schedule" {
  description = "Toggles managing a CloudWatch event rule and trigger based on a schedule."
  type        = bool
  default     = true
}

variable "cloudwatch_schedule_expression" {
  description = "A CloudWatch schedule expression. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html."
  type        = string
  default     = "rate(6 hours)"
}

variable "lambda_timeout" {
  description = "The duration allowed for the Lambda function to run in seconds."
  type        = number
  default     = 30
}