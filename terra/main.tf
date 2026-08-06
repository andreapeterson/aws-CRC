# Static site delivery
# The domain bucket and hosted zone predate this Terraform stack.
data "aws_s3_bucket" "main_bucket" {
  bucket = "andrea-peterson.com"
}
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = data.aws_s3_bucket.main_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_policy" "cloudfront_s3_bucket_policy" {
  bucket = data.aws_s3_bucket.main_bucket.id
  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${data.aws_s3_bucket.main_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}
locals {
  content_type_map = {
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "png"  = "image/png",
    "gif"  = "image/gif",
    "json" = "application/json"
    svg    = "image/svg+xml"
    ico    = "image/x-icon"
    woff   = "font/woff"
    woff2  = "font/woff2"
    ttf    = "font/ttf"
  }
}
resource "aws_s3_object" "website_contents" {
  for_each = fileset("../my_website/", "**/*")
  bucket   = data.aws_s3_bucket.main_bucket.id
  key      = each.key
  source   = "../my_website/${each.key}"
  content_type = lookup(
    local.content_type_map,
    length(split(".", each.key)) > 1 ? lower(element(split(".", each.key), length(split(".", each.key)) - 1)) : "",
    "text/plain"
  )
  cache_control = endswith(lower(each.key), ".html") ? "no-cache, no-store, must-revalidate" : "public, max-age=31536000, immutable"
  etag          = filemd5("../my_website/${each.key}")
}

resource "aws_s3_bucket_ownership_controls" "acl" {
  bucket = data.aws_s3_bucket.main_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "b_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.acl
  ]
  bucket = data.aws_s3_bucket.main_bucket.id
  acl    = "private"
}
locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = data.aws_s3_bucket.main_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.s3_origin_id
  }
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  enabled             = true
  aliases             = ["andrea-peterson.com"] #alternate cname

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 1
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  # Specific cache behavior for CSS files
  ordered_cache_behavior {
    path_pattern     = "*.css"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = true
      headers      = ["Content-Type", "Content-Encoding", "Accept-Encoding", "Cache-Control"]
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = "arn:aws:acm:us-east-1:721286014382:certificate/bffe6ff1-6fc7-4406-8cec-e43624ebc53a"
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 60
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 60
  }
}
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "OAC Settings"
  description                       = "Bucket restricted access to CloudFront only"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_route53_zone" "myzone" {
  name = "andrea-peterson.com"
}
resource "aws_route53_record" "www-a" {
  zone_id = data.aws_route53_zone.myzone.zone_id
  name    = "andrea-peterson.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


# Serverless visitor counter
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.lambda_log_group.arn}:*"]
  }

  statement {
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.dyanmodb.arn]
  }
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name   = "CRC_lambda_permissions"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}
data "archive_file" "lambda_code" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}
resource "aws_lambda_function" "lambda_fxn" {
  filename      = data.archive_file.lambda_code.output_path
  function_name = var.lambda_fxn_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = var.lambda_handler

  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group,
    aws_iam_role_policy.lambda_permissions
  ]

  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  runtime = "python3.12"

  environment {
    variables = {
      table_name = var.dynamo_fxn_name
    }
  }
}
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_fxn_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}
resource "aws_lambda_function_url" "fxn_url" {
  function_name      = aws_lambda_function.lambda_fxn.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["https://andrea-peterson.com"]
  }
}
resource "aws_dynamodb_table" "dyanmodb" {
  name           = var.dynamo_fxn_name
  hash_key       = "id"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "id"
    type = "S"
  }
}
