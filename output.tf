output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.s3_bucket.bucket
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.file_data.name
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.s3_trigger_lambda.function_name
}
