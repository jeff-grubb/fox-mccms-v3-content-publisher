locals {
  account_id          = data.aws_caller_identity.current.account_id
  function_name       = "${var.environment_name}-${var.business_unit}-${var.app_name}"
  sqs_function_name   = "${local.function_name}-sqs-test"
  content_stream_arn  = "${data.aws_dynamodb_table.spark_v3_content_table.stream_arn}"
  content_table_arn   = "${data.aws_dynamodb_table.spark_v3_content_table.arn}"
  s3_data_table       = "${local.function_name}-data"
  subscribe_accounts  = []

  #articles_bucket     = "${var.environment_name}-fox-content-stream-article-bucket"
  #sns_topic_name      = "${var.environment_name}-fs-fox-mccms-external-content-publisher" # todo - more dynamic
  #source_account      = "684424026845" # todo - more dynamic

  #secrets_json = {
  #  secrets   = jsondecode(data.aws_s3_object.fox_content_stream_secrets_object.body)
  #  datadog   = jsondecode(data.aws_s3_object.datadog_secrets_object.body)
  #}

  #secrets = {
  #  super_secret_value  = local.secrets_json.secrets["super_secret_value"]
  #}

  #datadog = {
  #  runtime_layer_mapping   = local.secrets_json.datadog[var.node_version]["LayerMapping"]
  #  runtime_core_layer      = local.secrets_json.datadog[var.node_version]["CoreLayer"]
  #  extension_layer         = local.secrets_json.datadog[var.node_version]["ExtensionLayer"]
  #  api_key                 = local.secrets_json.datadog["DD"]["apikey"]
  #}
}
