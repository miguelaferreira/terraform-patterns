variable "enable_some_key" {
  type = bool
}

variable "create_aws_key" {
  type    = bool
  default = false
}

module "some_key" {
  source = "./modules/some-key-conditional"

  enable = var.enable_some_key

  create_aws_key = var.create_aws_key
}

output "some_key_fingerprint" {
  value = module.some_key.fingerprint
}

output "some_key_aws_key_id" {
  value = module.some_key.aws_key_id
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}
