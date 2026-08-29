resource "aws_s3_bucket" "satellite_images" {
  bucket = var.bucket_name

  tags = {
    Name = "${var.project_name}-satellite-images"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.satellite_images.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.satellite_images.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.satellite_images.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Ciclo de vida: mover imágenes ópticas/radar crudas a Infrequent Access
# después de 30 días, ya que se reprocesan poco una vez ingeridas.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.satellite_images.id

  rule {
    id     = "raw-images-to-ia"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
