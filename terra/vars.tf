variable "REGION" {
  default = "us-east-1"
}

variable "lambda_fxn_name" {
  default = "CRC-terra1"
}

variable "lambda_handler" {
  default = "lambda_function.lambda_handler"
}

variable "dynamo_fxn_name" {
  default = "CRC-terra"
}
