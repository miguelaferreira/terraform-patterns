# terraform-patterns
Collection of patterns for terraform code.

## Conditional modules

Pattern [here](./pattern-conditional-module/README.md).

Module declarations do not allow for `count` or `for_each`, so there's no way to have a module declared in the code but only enable it in certain conditions.
```hcl-terraform
# main.tf
variable "enable_some_module" {
  type = bool
}

module "some_module" {
  source = "modules/some-module"
  
  count = var.enable_some_module ?  1 : 0
}
```
That means this ☝️ does not work.
Why does that matter? Modules are a great language feature of terraform, but because they do not support all language features it gets hard to write modules that are driven by different shapes and sizes of input data.
Instead, the amount of modules explodes because different combinations of logic get encapsulated in different modules with lots od duplication between them.
This pattern is helpful to reduce duplication between modules, but also tobe able to write modules with richer logic.


