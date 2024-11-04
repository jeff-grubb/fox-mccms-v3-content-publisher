data "aws_caller_identity" "current" {}

data "aws_dynamodb_table" "spark_v3_content_table" {
  name = "${var.environment_name}-${var.business_unit}-spark-v3-content"
}
