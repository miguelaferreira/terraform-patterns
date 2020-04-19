variable "key_name" {
  type    = string
  default = "some-key"
}

variable "create_aws_key" {
  type    = bool
  default = false
}

variable "ssh_dir" {
  type    = string
  default = "/tmp/ssh"
}

variable "collection_input" {
  description = "Collection of keys to create"

  type = map(object({
    create_aws_key = bool
    ssh_dir        = string
  }))

  default = null
}

resource "tls_private_key" "some_key" {
  for_each = local.module_input

  algorithm   = "RSA"
  ecdsa_curve = "4096"
}

resource "local_file" "priv_key_on_disk" {
  for_each = local.module_input

  filename          = "${each.value.ssh_dir}/${each.key}-priv-key.pem"
  sensitive_content = tls_private_key.some_key[each.key].private_key_pem
  file_permission   = "0400"
}

resource "local_file" "pub_key_on_disk" {
  for_each = local.module_input

  filename          = "${each.value.ssh_dir}/${each.key}-pub-key.pem"
  sensitive_content = tls_private_key.some_key[each.key].public_key_pem
  file_permission   = "0600"
}

resource "aws_key_pair" "some_aws_key" {
  for_each = local.aws_keys

  key_name   = each.key
  public_key = local.aws_keys_pub_keys[each.key]
}

locals {
  single_input = {
    (var.key_name) = {
      create_aws_key = var.create_aws_key
      ssh_dir        = var.ssh_dir
    }
  }

  module_input = var.collection_input != null ? var.collection_input : local.single_input

  aws_keys          = {for key, value in local.module_input : key => value if value.create_aws_key}
  aws_keys_pub_keys = {for key, value in local.module_input : key => tls_private_key.some_key[key].public_key_openssh if value.create_aws_key}
}

output "public_keys" {
  value = {for key, value in local.module_input : key => tls_private_key.some_key[key].public_key_pem}
}

output "aws_key_names" {
  value = {for key, value in local.aws_keys : key => aws_key_pair.some_aws_key[key].key_name}
}
