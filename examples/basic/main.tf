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
