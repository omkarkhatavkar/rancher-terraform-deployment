resource "aws_s3_bucket" "backup_bucket" {
  provider      = aws.s3
  bucket        = var.prefix
  force_destroy = true # Ensures that all objects are deleted when the bucket is destroyed

  tags = {
    Name        = var.prefix
    Environment = "test"
  }
}
