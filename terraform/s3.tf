resource "aws_s3_bucket" "fox_mccms_v3_content_publisher_data_bucket" {
  bucket = local.s3_data_table
}

resource "aws_s3_bucket_lifecycle_configuration" "delete_old_messages" {
  bucket = aws_s3_bucket.fox_mccms_v3_content_publisher_data_bucket.id

  rule {
    id = "delete_after_2_days"
    expiration {
      days = 2
    }
    status = "Enabled"
  }
}
