data "aws_caller_identity" "current" {}

module "testing" {
  source = "../"

  name                 = "test-ami-refresh"
  ami_filters          = "name=amzn2-ami-hvm-2.*-x86_64-ebs;owner-alias=amazon"
  launch_template_name = "foo-bar-20211202"
  tags                 = { "group" : "foo" }
}