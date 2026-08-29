output "bucket_name" {
  value = aws_s3_bucket.satellite_images.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.satellite_images.arn
}
