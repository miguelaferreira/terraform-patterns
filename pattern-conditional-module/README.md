# Pattern Conditional Module

The pattern to achieve this is the following:
1. Add a `var.enabled` to the module
2. Use that variable to set `count` on every resource in the module
3. If the module declares sub-modules (and if those implement this pattern as well) pass it along to the sub-modules
4. For resources that where already conditional, use the variable in disjunction with whatever other logic in a local value.
5. Module outputs encapsulate the conditional nature of the values, that is, the fact that resources are conditional is not visible from outputs

These choices have a negative impact on the readability and maintainability of the code.
Conditional resources (ie. resources that declare `count`) have to be accessed as collections, either using the splat syntax (`.*.`) or an index (`[0]` or `["index]`).
That means the code becomes much more verbose and that means more places for bugs to hide in.

Resource access without condition
```hcl-terraform
resource "null_resource" "now" {
  triggers = {
    now = "now is ${timestamp()}"
  }
}

locals {
  value = null_resource.now.triggers.now
}
```

Resource access with condition
```hcl-terraform
variable "enable" {
  description = "Whether to create the resources in the module"
  type = bool
  default = true
}

resource "null_resource" "now" {
  count = var.enable ? 1 : 0
 
  triggers = {
    now = "now is ${timestamp()}"
  }
}

# Using locals helps to keep with reading code and could even be more efficient depending on how terraform evaluates expressions
locals {
  value_with_array_index = null_resource.now[0].triggers.now             # creates problems on an empty state
  value_with_splat       = join("", null_resource.now.*.triggers.now)    # semantically correct 
  # there other options using collection functions
  value_with_try         = try(null_resource.now[0].triggers.now, "NA")  # discouraged in TF docs but also semantically correct, and gives the option for an alternate value
}
```

## Run

### Setup
```bash
$ terraform init

# Set AWS credentials in the environment!
```

### Module disabled

When the module is disabled terraform will offer no change.
```
$ TF_VAR_enable_some_key=false terraform plan

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

### Module enabled

When the module is enabled terraform will offer to create the key.
```
$ TF_VAR_enable_some_key=true terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.some_key.local_file.priv_key_on_disk[0] will be created
  + resource "local_file" "priv_key_on_disk" {
      + directory_permission = "0777"
      + file_permission      = "0400"
      + filename             = "/Users/miguel/.ssh/priv-key.pem"
      + id                   = (known after apply)
      + sensitive_content    = (sensitive value)
    }

  # module.some_key.local_file.pub_key_on_disk[0] will be created
  + resource "local_file" "pub_key_on_disk" {
      + directory_permission = "0777"
      + file_permission      = "0600"
      + filename             = "/Users/miguel/.ssh/pub-key.pem"
      + id                   = (known after apply)
      + sensitive_content    = (sensitive value)
    }

  # module.some_key.tls_private_key.some_key[0] will be created
  + resource "tls_private_key" "some_key" {
      + algorithm                  = "ECDSA"
      + ecdsa_curve                = "P384"
      + id                         = (known after apply)
      + private_key_pem            = (sensitive value)
      + public_key_fingerprint_md5 = (known after apply)
      + public_key_openssh         = (known after apply)
      + public_key_pem             = (known after apply)
      + rsa_bits                   = 2048
    }

Plan: 3 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

### Module enabled and create AWS key

```
$ TF_VAR_enable_some_key=true TF_VAR_create_aws_key=true terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.some_key.aws_key_pair.some_key_pair[0] will be created
  + resource "aws_key_pair" "some_key_pair" {
      + fingerprint = (known after apply)
      + id          = (known after apply)
      + key_name    = "some-key"
      + key_pair_id = (known after apply)
      + public_key  = (known after apply)
    }

  # module.some_key.local_file.priv_key_on_disk[0] will be created
  + resource "local_file" "priv_key_on_disk" {
      + directory_permission = "0777"
      + file_permission      = "0400"
      + filename             = "/Users/miguel/.ssh/priv-key.pem"
      + id                   = (known after apply)
      + sensitive_content    = (sensitive value)
    }

  # module.some_key.local_file.pub_key_on_disk[0] will be created
  + resource "local_file" "pub_key_on_disk" {
      + directory_permission = "0777"
      + file_permission      = "0600"
      + filename             = "/Users/miguel/.ssh/pub-key.pem"
      + id                   = (known after apply)
      + sensitive_content    = (sensitive value)
    }

  # module.some_key.tls_private_key.some_key[0] will be created
  + resource "tls_private_key" "some_key" {
      + algorithm                  = "ECDSA"
      + ecdsa_curve                = "P384"
      + id                         = (known after apply)
      + private_key_pem            = (sensitive value)
      + public_key_fingerprint_md5 = (known after apply)
      + public_key_openssh         = (known after apply)
      + public_key_pem             = (known after apply)
      + rsa_bits                   = 2048
    }

Plan: 4 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```
