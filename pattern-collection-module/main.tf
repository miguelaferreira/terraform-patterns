###################################################################################################################
# Create no key - conditional module
###################################################################################################################
module "no_key" {
  source = "./modules/some-key-collection-static-type"

  collection_input = {}
}

output "no_public_keys" {
  value = module.no_key.public_keys
}

output "no_key_aws_key_names" {
  value = module.no_key.aws_key_names
}

###################################################################################################################
# Create single key - use module variables
###################################################################################################################
module "single_key" {
  source = "./modules/some-key-collection-static-type"

  create_aws_key = false
  ssh_dir        = "/tmp"
}

output "single_public_keys" {
  value = module.single_key.public_keys
}

output "single_key_aws_key_names" {
  value = module.single_key.aws_key_names
}

###################################################################################################################
# Create collection of keys with static typping - use collection variable
###################################################################################################################
module "multiple_static" {
  source = "./modules/some-key-collection-static-type"

  collection_input = {
    key1 = {
      create_aws_key = false
      ssh_dir = "/tmp/ssh"
    }

    key2 = {
      create_aws_key = true
      ssh_dir = "/tmp/ssh"
    }

    key3 = {
      create_aws_key = false
      ssh_dir = "/tmp/ssh-3"
    }
  }
}

output "multiple_static_public_keys" {
  value = module.multiple_static.public_keys
}

output "multiple_static_aws_key_names" {
  value = module.multiple_static.aws_key_names
}

###################################################################################################################
# Create collection of keys with static typping - use collection variable
###################################################################################################################
module "multiple_dynamic" {
  source = "./modules/some-key-collection-dynamic-type"

  collection_input = {
    key4 = {}

    key5 = {
      create_aws_key = true
    }

    key6 = {
      create_aws_key = false
      ssh_dir = "/tmp/ssh-6"
    }
  }
}

output "multiple_dynamic_public_keys" {
  value = module.multiple_dynamic.public_keys
}

output "multiple_dynamic_aws_key_names" {
  value = module.multiple_dynamic.aws_key_names
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}
