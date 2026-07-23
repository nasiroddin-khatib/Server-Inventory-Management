############################################
# Frontend S3 Bucket
############################################

resource "aws_s3_bucket" "frontend" {

  bucket = var.frontend_bucket_name

  tags = {
    Name        = "frontend-bucket"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

############################################
# Versioning
############################################

resource "aws_s3_bucket_versioning" "frontend" {

  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

############################################
# Server Side Encryption
############################################

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {

  bucket = aws_s3_bucket.frontend.id

  rule {

    apply_server_side_encryption_by_default {

      sse_algorithm = "AES256"

    }

  }

}

############################################
# Ownership Controls
############################################

resource "aws_s3_bucket_ownership_controls" "frontend" {

  bucket = aws_s3_bucket.frontend.id

  rule {

    object_ownership = "BucketOwnerPreferred"

  }

}

############################################
# Block Public Access
############################################

resource "aws_s3_bucket_public_access_block" "frontend" {

  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true

}
