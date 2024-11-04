# Create the SQS queue for the test

resource "aws_sqs_queue" "fox_mccms_v3_content_publisher_dlq" {
  name = "${local.sqs_function_name}-queue-dlq"
}

resource "aws_sqs_queue" "fox_mccms_v3_content_publisher_queue" {
  name = "${local.sqs_function_name}-queue"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.fox_mccms_v3_content_publisher_dlq.arn,
    maxReceiveCount = 4
  })
  visibility_timeout_seconds = 900
}

resource "aws_sqs_queue_redrive_allow_policy" "fox_mccms_v3_content_publisher_redrive_allow_policy" {
  queue_url = aws_sqs_queue.fox_mccms_v3_content_publisher_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.fox_mccms_v3_content_publisher_queue.arn]
  })
}

data "aws_iam_policy_document" "fox_mccms_v3_content_publisher_sqs_policy_doc" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.fox_mccms_v3_content_publisher_queue.arn
    ]
  }
}

resource "aws_iam_policy" "fox_mccms_v3_content_publisher_sqs_read_policy" {
  name    = "sqs_policy"
  policy  = data.aws_iam_policy_document.fox_mccms_v3_content_publisher_sqs_policy_doc.json
}

resource "aws_iam_policy_attachment" "fox_mccms_v3_content_publisher_lambda_sqs_policy_attachment" {
  name        = "sqs_test_policy"
  roles       = [
    aws_iam_role.fox_mccms_v3_content_publisher_iam_role.id
  ]
  policy_arn  = aws_iam_policy.fox_mccms_v3_content_publisher_sqs_read_policy.arn
}

resource "aws_lambda_event_source_mapping" "fox_mccms_v3_content_publisher_sqs_test_event_source_mapping" {
  event_source_arn  = aws_sqs_queue.fox_mccms_v3_content_publisher_queue.arn
  function_name     = aws_lambda_function.fox_mccms_v3_content_publisher_sqs_test_lambda_function.arn
}

# sqs test lambda

resource "aws_cloudwatch_log_group" "fox_mccms_v3_content_publisher_sqs_test_lambda_log_group" {
  name              = "/aws/lambda/${local.sqs_function_name}"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = false
  }
}

data "archive_file" "fox_mccms_v3_content_publisher_sqs_test_lambda_archive_file" {
  type = "zip"
  source_file = "../lambda/fox-mccms-v3-content-publisher-sqs-test/main.py"
  output_path = "../lambda/fox-mccms-v3-content-publisher-sqs-test/build/content-publisher-test.zip"
}

resource "aws_lambda_function" "fox_mccms_v3_content_publisher_sqs_test_lambda_function" {
  depends_on        = [aws_cloudwatch_log_group.fox_mccms_v3_content_publisher_sqs_test_lambda_log_group]
  function_name     = local.sqs_function_name
  role              = aws_iam_role.fox_mccms_v3_content_publisher_iam_role.arn
  handler           = "main.lambda_handler"
  runtime           = "python3.10"
  filename          = "../lambda/fox-mccms-v3-content-publisher-sqs-test/build/content-publisher-test.zip"
  source_code_hash  = data.archive_file.fox_mccms_v3_content_publisher_sqs_test_lambda_archive_file.output_base64sha256
  #s3_bucket        = var.primary_control_bucket
  #s3_key           = "common/lambda/${var.app_name}-${var.lambda_version}.zip"
  timeout           = 900
  architectures     = ["arm64"]

  layers            = [
    "arn:aws:lambda:${var.region}:017000801446:layer:AWSLambdaPowertoolsPythonV3-python38-arm64:2"
  ]

  environment {
    variables = {
      "POWERTOOLS_SERVICE_NAME": var.app_name,
      "POWERTOOLS_LOG_LEVEL": var.logging_level,
    }
  }
}

# SNS Subscription

resource "aws_sns_topic_subscription" "fs_articles_topic_subscription" {
  topic_arn = aws_sns_topic.fox-mccms-v3-content-publisher-topic.arn
  protocol = "sqs"
  endpoint = aws_sqs_queue.fox_mccms_v3_content_publisher_queue.arn
}

data "aws_iam_policy_document" "fs_articles_sqs_queue_policy" {
  statement {
    sid    = "First"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.fox_mccms_v3_content_publisher_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [
        "${aws_sns_topic.fox-mccms-v3-content-publisher-topic.arn}"
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "fs_articles_sqs_queue_policy" {
  queue_url = aws_sqs_queue.fox_mccms_v3_content_publisher_queue.id
  policy    = data.aws_iam_policy_document.fs_articles_sqs_queue_policy.json
}




