# Pattern Collection Module

Using this patter a module offers two flavours of input
1. Normal terraform variables that the user sets to create a single set of the resources described in the module
2. A special terraform variable that models all the normal terraform variables as values of a map
The special terraform variable is not  required (ie. has a neutral default value) but when set takes precedence over the normal variables.

The pattern to achieve this is the following:
1. Add a `var.collection_input` of type map (because we want to name the input) to the module with a `null` or `{}` default
```hcl-terraform
# Statically typed
variable "collection_input" {
  type = map(object({
    create_aws_key = bool
    ssh_dir        = string
  }))
  
  default = null
} 
```
```hcl-terraform
# Dynamically typed
variable "collection_input" {
  type = any
  default = null
}
```
2. Add a `var.name` (which could be `var.key_name` for example) of type string that names the single set of resources (ie. when `var.collection_input` not set to a map with entries)
```hcl-terraform
variable "key_name" {
  type = string
  default = "some key"
}
```
3. Define a local value `local.single_input` to map `var.name` to the set of all other variables except for `var.collection_input`
```hcl-terraform
locals {
  single_input = {
    (var.key_name) = {
      create_aws_key = var.create_aws_key
      ssh_dir        = var.ssh_dir
    }
  }
}
```
4. Define a local value `local.module_input` to abstract away the operation mode of the module (ie. single or collection) and simplify the implementation of resources
```hcl-terraform
locals {
  module_input = var.collection_input != null ? var.collection_input : local.single_input
}
```
6. Declare `for_each` on every module resource and iterate over `local.module_input`
```hcl-terraform
####################################################################
# Statically typed
####################################################################
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
```
```hcl-terraform
####################################################################
# Dynamically typed
####################################################################
resource "tls_private_key" "some_key" {
  for_each = local.module_input

  algorithm   = "RSA"
  ecdsa_curve = "4096"
}

resource "local_file" "priv_key_on_disk" {
  for_each = local.module_input

  filename          = "${lookup(each.value, "ssh_dir", var.ssh_dir)}/${each.key}-priv-key.pem"
  sensitive_content = tls_private_key.some_key[each.key].private_key_pem
  file_permission   = "0400"
}

resource "local_file" "pub_key_on_disk" {
  for_each = local.module_input

  filename          = "${lookup(each.value, "ssh_dir", var.ssh_dir)}/${each.key}-pub-key.pem"
  sensitive_content = tls_private_key.some_key[each.key].public_key_pem
  file_permission   = "0600"
}
```
8. For resources that depend on extra conditions, create sub-collections with the appropriate filtering of `local.module_input`, assign those to local values, then iterate over them for the required resources
```hcl-terraform
####################################################################
# Statically typed
####################################################################
resource "aws_key_pair" "some_aws_key" {
  for_each = local.aws_keys

  key_name   = each.key
  public_key = local.aws_keys_pub_keys[each.key]
}

locals {
  aws_keys          = {for key, value in local.module_input : key => value if value.create_aws_key}
  aws_keys_pub_keys = {for key, value in local.module_input : key => tls_private_key.some_key[key].public_key_openssh if value.create_aws_key}
}
```
```hcl-terraform
####################################################################
# Dynamically typed
####################################################################
resource "aws_key_pair" "some_aws_key" {
  for_each = local.aws_keys

  key_name   = each.key
  public_key = local.aws_keys_pub_keys[each.key]
}

locals {
  aws_keys          = {for key, value in local.module_input : key => value if lookup(value, "create_aws_key", false)}
  aws_keys_pub_keys = {for key, value in local.module_input : key => tls_private_key.some_key[key].public_key_openssh if lookup(value, "create_aws_key", false)}
}
```
10. Module outputs all become maps of something where the key set is the same as the key set of `local.module_input`
```hcl-terraform
output "public_keys" {
  value = {for key, value in local.module_input : key => tls_private_key.some_key[key].public_key_pem}
}

output "aws_key_names" {
  value = {for key, value in local.aws_keys : key => aws_key_pair.some_aws_key[key].key_name}
}
```
12. If the module declares sub-modules (and if those implement this pattern as well) pass `local.module_input` (or a subset) along to the sub-modules
