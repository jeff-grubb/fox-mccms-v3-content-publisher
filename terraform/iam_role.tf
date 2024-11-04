data "aws_iam_policy_document" "fox_mccms_v3_content_publisher_role_doc" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "pipes.amazonaws.com"
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "fox_mccms_v3_content_publisher_inline_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
  statement {
    effect = "Allow"
    actions   = [
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams",
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem"
    ]
    resources = [
      "${local.content_table_arn}/*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "sns:Publish",
      "sns:RemovePermission",
      "sns:SetTopicAttributes",
      "sns:DeleteTopic",
      "sns:ListSubscriptionsByTopic",
      "sns:GetTopicAttributes",
      "sns:AddPermission",
      "sns:Subscribe"
    ]
    resources = [
      aws_sns_topic.fox-mccms-v3-content-publisher-topic.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.fox_mccms_v3_content_publisher_lambda_function.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.fox_mccms_v3_content_publisher_data_bucket.arn,
      "${aws_s3_bucket.fox_mccms_v3_content_publisher_data_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role" "fox_mccms_v3_content_publisher_iam_role" {
  name = "${var.environment_name}-${var.business_unit}-fox-mccms-v3-content-publisher-role"
  assume_role_policy = data.aws_iam_policy_document.fox_mccms_v3_content_publisher_role_doc.json
}

resource "aws_iam_policy" "fox_mccms_v3_content_publisher_inline_policy" {
  name    = "${var.environment_name}-${var.business_unit}-fox-mccms-v3-content-publisher-inline-policy"
  policy  = data.aws_iam_policy_document.fox_mccms_v3_content_publisher_inline_policy_doc.json
}

resource "aws_iam_policy_attachment" "fox_mccms_v3_content_publisher_inline_policy_attachment" {
  name        = "inline_policy"
  roles       = [
    aws_iam_role.fox_mccms_v3_content_publisher_iam_role.id
  ]
  policy_arn  = aws_iam_policy.fox_mccms_v3_content_publisher_inline_policy.arn
}
