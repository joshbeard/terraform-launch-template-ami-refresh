output "lambda_function_arn" {
  value = aws_lambda_function.this.arn
}

output "lambda_function_invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}

output "lambda_function_name" {
  value = aws_lambda_function.this.function_name
}

output "lambda_function_source_code_hash" {
  value = aws_lambda_function.this.source_code_hash
}