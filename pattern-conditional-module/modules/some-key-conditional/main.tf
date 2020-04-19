variable "enable" {
  description = "Whether to create the resources in the module"
  type        = bool
  default     = true
}

variable "create_aws_key" {
  type    = bool
  default = false
}

resource "tls_private_key" "some_key" {
  count = var.enable ? 1 : 0

  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "local_file" "priv_key_on_disk" {
  count = var.enable ? 1 : 0

  filename          = "${local.ssh_dir}/priv-key.pem"
  sensitive_content = local.private_key
  file_permission   = "0400"
}

resource "local_file" "pub_key_on_disk" {
  count = var.enable ? 1 : 0

  filename          = "${local.ssh_dir}/pub-key.pem"
  sensitive_content = local.public_key
  file_permission   = "0600"
}

resource "aws_key_pair" "some_key_pair" {
  count = var.enable && var.create_aws_key ? 1 : 0

  key_name   = "some-key"
  public_key = local.public_key
}

output "fingerprint" {
  value = local.fingerprint
}

output "aws_key_id" {
  value = local.aws_key_id
}

locals {
  home_dir = pathexpand("~")
  ssh_dir  = "${local.home_dir}/.ssh"

  aws_key_id = join("", aws_key_pair.some_key_pair.*.id)

  public_key  = try(tls_private_key.some_key[0].public_key_pem, "NA")
  private_key = try(tls_private_key.some_key[0].private_key_pem, "NA")
  fingerprint = try(tls_private_key.some_key[0].public_key_fingerprint_md5, "NA")
}
