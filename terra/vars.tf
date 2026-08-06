variable "REGION" {
  description = "AWS region used by the portfolio stack."
  type        = string
  default     = "us-east-1"
}

variable "lambda_fxn_name" {
  description = "Name of the visitor-counter Lambda function."
  type        = string
  default     = "CRC-terra1"
}

variable "lambda_handler" {
  description = "Python handler invoked by Lambda."
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "dynamo_fxn_name" {
  description = "Name of the DynamoDB table that stores the visitor count."
  type        = string
  default     = "CRC-terra"
}
