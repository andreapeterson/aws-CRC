# FRONT END FRONT END FRONT END #

# FOR S3
##Already established S3 bucket
data "aws_s3_bucket" "main_bucket" {
  bucket = "andrea-peterson.com"
}
##Turning on public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = data.aws_s3_bucket.main_bucket.id

  block_public_policy = false
}
##Bucket policy
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
##Bucket objects
locals {
  content_type_map = {
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "jpg"  = "image/jpeg",
    "png"  = "image/png",
    "json" = "text/json"
  }
}
resource "aws_s3_object" "website_contents" {
  for_each     = fileset("../my_website/", "**/*") #Uploads every file as its own object
  bucket       = data.aws_s3_bucket.main_bucket.id
  key          = each.key
  source       = "../my_website/${each.value}"
  content_type = lookup(local.content_type_map, split(".", each.value)[1], "text/css")
  etag         = filemd5("../my_website/${each.value}") #etag makes the file update when it changes- lets terraform recognize when content has changed
}
##Bucket ACL
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

# FOR CLOUDFRONT
##The distribution
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
    #Not caching based off headers etc.
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    #Cache behavior
    min_ttl     = 1
    default_ttl = 86400
    max_ttl     = 31536000
    compress    = true
  }

  price_class = "PriceClass_100" #North America & Europe to save costs

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = "arn:aws:acm:us-east-1:721286014382:certificate/bffe6ff1-6fc7-4406-8cec-e43624ebc53a"
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
}
##So the origin (our s3 bucket) can not be accessed directly, only through CloudFront. CloudFront will sign any requests it will send to the S3 origin(default)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "OAC Settings"
  description                       = "Bucket restricted access to CloudFront only"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# FOR ROUTE53
##Already established hosted zone
data "aws_route53_zone" "myzone" {
  name = "andrea-peterson.com"
}
##Adding A-record pointing at CloudFront distribution
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


# BACK END BACK END BACK END #

# FOR LAMBDA
##The assume role policy
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
##Lambda assuming the role
resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
##The policy that will be attached to the Lambda iam role
resource "aws_iam_policy" "policy" {
  name        = "CRC_policy"
  description = "AWS IAM Policy for managing CRC"
  policy      = file("iam_policy.json")
}
##Attaching the policy to the iam role
resource "aws_iam_policy_attachment" "policy_attachment" {
  name       = "attachment"
  roles      = [aws_iam_role.iam_for_lambda.id]
  policy_arn = aws_iam_policy.policy.arn
}
##Function code- zipped
data "archive_file" "lambda_code" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}
##Lambda Function
resource "aws_lambda_function" "lambda_fxn" {
  filename      = data.archive_file.lambda_code.output_path
  function_name = var.lambda_fxn_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = var.lambda_handler

  depends_on = [aws_cloudwatch_log_group.lambda_log_group]

  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      table_name = var.dynamo_fxn_name
    }
  }
}
## CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_fxn_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}
##Function URL
resource "aws_lambda_function_url" "fxn_url" {
  function_name      = aws_lambda_function.lambda_fxn.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["https://andrea-peterson.com"]
  }
}
##For updating my_website/index.js with function url
resource "null_resource" "edit_file" {
  provisioner "local-exec" {
    command = <<EOF
      sed -i.bak "s|URL_REPLACE_PLACEHOLDER|${aws_lambda_function_url.fxn_url.function_url}|" ../my_website/index.js
    EOF
  }

  triggers = {
    always_run = timestamp()
  }

  depends_on = [aws_lambda_function_url.fxn_url]
}

# FOR DYNAMODB
##Creating table
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


###Adding item to table with id=1 and views=0
#resource "aws_dynamodb_table_item" "item1" {
#  hash_key   = aws_dynamodb_table.dyanmodb.hash_key
#  table_name = aws_dynamodb_table.dyanmodb.name
#  item       = <<ITEM
#{
#  "id": {"S": "1"},
#  "Views": {"N": "0"}
#}
#ITEM
#}
