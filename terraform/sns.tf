resource "aws_sns_topic" "fox-mccms-v3-content-publisher-topic" {
  name = "${var.environment_name}-${var.business_unit}-fox-mccms-v3-external-content-publisher"
}

data "aws_iam_policy_document" "fox-mccms-v3-content-publisher-topic-policy-doc" {
  policy_id = "${var.environment_name}-${var.business_unit}-fox-mccms-v3-external-content-publisher-sns-topic-policy"

  statement {
    sid     = "DefaultTopicPolicy"
    effect  = "Allow"

    actions = [
      "sns:Subscribe"
    ]

    condition {
      test      = "StringEquals"
      variable  = "AWS:SourceOwner"

      values    = local.subscribe_accounts
    }
    principals {
      type          = "AWS"
      identifiers   = ["*"]
    }

    resources = [aws_sns_topic.fox-mccms-v3-content-publisher-topic.arn]
  }
}

resource "aws_sns_topic_policy" "fox-mccms-v3-content-publisher-topic-policy" {
  arn = aws_sns_topic.fox-mccms-v3-content-publisher-topic.arn
  policy = data.aws_iam_policy_document.fox-mccms-v3-content-publisher-topic-policy-doc.json
}
