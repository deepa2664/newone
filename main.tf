provider "aws" {
  region = "us-east-1"
}

# 1. S3 Bucket for File Uploads
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "my-file-upload-bucket"
 
}

# 2. DynamoDB Table to Store Metadata
resource "aws_dynamodb_table" "file_data" {
  name           = "FileData"
  hash_key       = "FileID"
  billing_mode   = "PAY_PER_REQUEST"

  attribute {
    name = "FileID"
    type = "S"
  }

  
}

# 3. IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_role" {
  name               = "lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 4. Attach Lambda Basic Execution Role
resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "lambda-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  roles      = [aws_iam_role.lambda_role.name]
}

# 5. IAM Policy to Allow Lambda to Interact with DynamoDB
resource "aws_iam_policy" "dynamo_policy" {
  name        = "dynamo-policy"
  description = "Allows Lambda to interact with DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "dynamodb:PutItem"
        Effect   = "Allow"
        Resource = aws_dynamodb_table.file_data.arn
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "dynamo_policy_attachment" {
  name       = "lambda-dynamo-policy-attachment"
  policy_arn = aws_iam_policy.dynamo_policy.arn
  roles      = [aws_iam_role.lambda_role.name]
}

# 6. Lambda Function (Python)
resource "aws_lambda_function" "s3_trigger_lambda" {
  function_name = "s3_trigger_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  filename      = "lambda_function.zip"  # ZIP your Python code and upload it
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.file_data.name
    }
  }
}

# 7. S3 Event Notification to Trigger Lambda
resource "aws_s3_bucket_notification" "s3_event_notification" {
  bucket = aws_s3_bucket.s3_bucket.id

  lambda_function {
    events = ["s3:ObjectCreated:*"]
    filter_prefix = ""  # Optional: add a prefix filter
    filter_suffix = ""  # Optional: add a suffix filter

    lambda_function_arn = aws_lambda_function.s3_trigger_lambda.arn
  }

  depends_on = [
    aws_lambda_function.s3_trigger_lambda
  ]
}
resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  acl    = "private"  # Set the ACL to 'private'
}
