variable "create_aws_key" {
  type    = bool
  default = false
}

resource "tls_private_key" "some_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "local_file" "priv_key_on_disk" {
  filename          = "${local.ssh_dir}/priv-key.pem"
  sensitive_content = tls_private_key.some_key.private_key_pem
  file_permission   = "0400"
}

resource "local_file" "pub_key_on_disk" {
  filename          = "${local.ssh_dir}/pub-key.pem"
  sensitive_content = tls_private_key.some_key.public_key_pem
  file_permission   = "0600"
}

resource "aws_key_pair" "some_key_pair" {
  count = var.create_aws_key ? 1 : 0

  key_name   = "some-key"
  public_key = tls_private_key.some_key.public_key_pem
}

output "fingerprint" {
  value = tls_private_key.some_key.public_key_fingerprint_md5
}

output "aws_key_id" {
  value = local.aws_key_id
}

locals {
  home_dir = pathexpand("~")
  ssh_dir  = "${local.home_dir}/.ssh"

  aws_key_id = join("", aws_key_pair.some_key_pair.*.id)
}
