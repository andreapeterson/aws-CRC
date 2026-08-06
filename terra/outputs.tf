output "cloudfront_distribution_id" {
  description = "CloudFront distribution to invalidate after a website deployment."
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "visitor_counter_url" {
  description = "Public Lambda Function URL used by the visitor counter."
  value       = aws_lambda_function_url.fxn_url.function_url
}
