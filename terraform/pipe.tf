resource "aws_pipes_pipe" "fox-mccms-v3-content-publisher-pipe" {
  name = "${var.environment_name}-${var.business_unit}-fox-mccms-v3-content-publisher-pipe"
  role_arn = aws_iam_role.fox_mccms_v3_content_publisher_iam_role.arn
  source = local.content_stream_arn
  target = aws_sns_topic.fox-mccms-v3-content-publisher-topic.arn


  #filters = [{ pattern = "{ \"body\": { \"customer_type\": [\"Platinum\"] }}" }]
  enrichment = aws_lambda_function.fox_mccms_v3_content_publisher_lambda_function.arn

  source_parameters {
    dynamodb_stream_parameters {
      starting_position = "LATEST"
      batch_size = 1
    }

    #filter_criteria {
    #  filter {
    #    pattern = "{ \"dynamodb\": { \"Keys\": { \"post_status\": { \"S\": [\"publish\"] } } } }"
    #  }
    #}
  }

  #    {
  #      "dynamodb": {
  #        "Keys": {
  #          "post_status": {
  #            "S": ["publish"]
  #          }
  #        }
  #      }
  #    }



  target_parameters {}
}
