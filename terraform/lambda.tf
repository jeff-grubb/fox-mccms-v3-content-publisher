resource "aws_cloudwatch_log_group" "fox_mccms_v3_content_publisher_lambda_log_group" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = false
  }
}

data "archive_file" "fox_mccms_v3_content_publisher_lambda_archive_file" {
  type = "zip"
  source_file = "../lambda/fox-mccms-v3-content-publisher/main.py"
  output_path = "../lambda/fox-mccms-v3-content-publisher/build/content-publisher.zip"
}

resource "aws_lambda_function" "fox_mccms_v3_content_publisher_lambda_function" {
  depends_on        = [aws_cloudwatch_log_group.fox_mccms_v3_content_publisher_lambda_log_group]
  function_name     = local.function_name
  role              = aws_iam_role.fox_mccms_v3_content_publisher_iam_role.arn
  handler           = "main.lambda_handler"
  runtime           = "python3.10"
  filename          = "../lambda/fox-mccms-v3-content-publisher/build/content-publisher.zip"
  source_code_hash  = data.archive_file.fox_mccms_v3_content_publisher_lambda_archive_file.output_base64sha256
  #s3_bucket        = var.primary_control_bucket
  #s3_key           = "common/lambda/${var.app_name}-${var.lambda_version}.zip"
  timeout           = 900
  architectures     = ["arm64"]

  layers            = [
    "arn:aws:lambda:${var.region}:017000801446:layer:AWSLambdaPowertoolsPythonV3-python38-arm64:2"
  ]

  environment {
    variables = {
      "LOGGING_LEVEL": var.logging_level,
      "ENVIRONMENT": var.environment_name,
      "BUSINESS_UNIT": var.business_unit,
      "POWERTOOLS_SERVICE_NAME": var.app_name,
      "POWERTOOLS_LOG_LEVEL": var.logging_level,
      "S3_BUCKET": aws_s3_bucket.fox_mccms_v3_content_publisher_data_bucket.bucket
    }
  }
}
