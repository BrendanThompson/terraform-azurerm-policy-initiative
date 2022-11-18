# Azure Policy Initiative Module

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_management_group_policy_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group_policy_assignment) | resource |
| [azurerm_management_group_policy_exemption.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_group_policy_exemption) | resource |
| [azurerm_policy_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition) | resource |
| [azurerm_policy_set_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_set_definition) | resource |
| [azurerm_resource_group_policy_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group_policy_exemption.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_exemption) | resource |
| [azurerm_subscription_policy_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_exemption.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_exemption) | resource |
| [random_uuid.assignment](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [random_uuid.exemptions](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [random_uuid.policy](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [azurerm_policy_definition.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/policy_definition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assignment"></a> [assignment](#input\_assignment) | (Required) assignment details for the policy.<br>    Properties:<br>      `assignments` (Required)    - list of assignments<br>        `id` (Required)   - resource ID<br>        `name` (Required) - friendly name/reference for the assignment<br>      `scope` (Optional)          - resource scope for assignment [Default: `rg`] | <pre>object({<br>    assignments = list(object({<br>      id   = string<br>      name = string<br>    }))<br>    scope = optional(string, "rg")<br>  })</pre> | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | (Required) environment that the initiatives should be applied to. | `string` | n/a | yes |
| <a name="input_exemptions"></a> [exemptions](#input\_exemptions) | (Optional) List of exemption objects<br>    Properties:<br>      `id` (Required)                   - the resource ID for the exemption<br>      `risk_id` (Required)              - internal risk reference ID<br>      `scope` (Required)                - the scope for the exemption (sub, mg, rg)<br>      `category` (Required)             - exemption category<br>      `assignment_reference` (Required) - assignment friendly name/reference | <pre>list(object({<br>    id                   = string<br>    risk_id              = string<br>    scope                = string<br>    category             = string<br>    assignment_reference = string<br>  }))</pre> | `[]` | no |
| <a name="input_initiative_definition"></a> [initiative\_definition](#input\_initiative\_definition) | (Required) path to the initiative definition file | `string` | n/a | yes |

## Example(s)

```hcl
provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "this" {
  name = "rg-policy"
}

module "global_core" {
  source = "../.."

  assignment = {
    assignments = [{
      id   = data.azurerm_resource_group.this.id
      name = "DefaultRG"
    }]
    scope = "rg"
  }

  exemptions = [{
    assignment_reference = "DefaultRG"
    category             = "Mitigated"
    id                   = data.azurerm_resource_group.this.id
    risk_id              = "R-001"
    scope                = "rg"
  }]

  environment           = "dev"
  initiative_definition = format("%s/initiatives/core.yaml", path.module)
}
```