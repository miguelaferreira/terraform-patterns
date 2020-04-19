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

## Collection modules

Since module declarations do not allow for `count` or `for_each`, provisioning collections of resources is also no possible.
Let us take the example of the ["some-key"](./modules/some-key) module that creates tls keys.
To create a pre-defined set of keys we declare the module the number of times we need.
```hcl-terraform
module "some_key_1" {
  source  = "..."
}

module "some_key_2" {
  source  = "..."
}

module "some_key_n" {
  source  = "..."
}
```

However this is quite rigid and leads to the "explosion of modules" problem (where different combinations of input get packaged as a separate (sub-)module).
Collection modules solve this limitation by offering to create a single set of resources using module variables, or a collection of sets of resources using a special input variable, which we will call `var.collection_input`.  
Terraform supports both static types (ie. types that are evaluated by the type system at "compile" time) and dynamic types (ie. a data type called `any` which accepts anything).
For a terraform module developer this tradeoff boils down to:
1. using static types to simplify the implementation of the module and leverage the type system correctness checks, at the cost of extra verbosity in the module interface
2. using dynamic types to offer users of the module a more compact and elegant interface, at the cost or correctness and a more complex implementation to deal with possible combinations of input

Let us start with statically typed module and then transform it to a dynamically typed module.

### 1. Statically typed collection module


