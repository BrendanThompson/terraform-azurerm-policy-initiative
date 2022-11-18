resource "random_uuid" "policy" {
  for_each = {
    for k, v in local.policies :
    k => v
    if v.type == "Custom"
  }
}
resource "random_uuid" "exemptions" {}
resource "random_uuid" "assignment" {
  for_each = {
    for assignment in var.assignment.assignments :
    assignment.name => assignment.id
  }
}

locals {
  initiative_definition = yamldecode(file(var.initiative_definition))
  policies              = local.initiative_definition.policies
}

resource "azurerm_policy_definition" "this" {
  for_each = {
    for k, v in local.policies :
    k => jsondecode(
      templatefile(
        "${path.root}/policies/${v.file}",
        { effect = try(v[var.environment].effect, v.default.effect) }
      )
    )
    if v.type == "Custom"
  }

  name         = random_uuid.policy[each.key].result
  policy_type  = each.value.properties.policyType
  mode         = each.value.properties.mode
  display_name = each.value.properties.displayName
  description  = each.value.properties.description
  metadata     = jsonencode(each.value.properties.metadata)
  policy_rule  = jsonencode(each.value.properties.policyRule)
  parameters   = jsonencode(each.value.properties.parameters)
}

data "azurerm_policy_definition" "this" {
  for_each = {
    for k, v in local.policies :
    k => v
    if v.type == "BuiltIn"
  }

  name = each.value.id
}

locals {
  all_policies = merge(azurerm_policy_definition.this, data.azurerm_policy_definition.this)

  parameters = {
    for k, v in local.all_policies :
    k => try(
      local.policies[k][var.environment].parameters,
      local.policies[k].default.parameters
    )
  }
}

resource "azurerm_policy_set_definition" "this" {
  name         = local.initiative_definition.name
  policy_type  = "Custom"
  display_name = local.initiative_definition.display_name
  description  = local.initiative_definition.description

  dynamic "policy_definition_reference" {
    for_each = local.all_policies

    content {
      policy_definition_id = policy_definition_reference.value.id
      parameter_values     = jsonencode(local.parameters[policy_definition_reference.key])
    }
  }
}

resource "azurerm_subscription_policy_assignment" "this" {
  for_each = {
    for assignment in var.assignment.assignments :
    assignment.name => assignment.id
    if var.assignment.scope == "sub"
  }

  name                 = random_uuid.assignment[each.key].result
  subscription_id      = each.value
  policy_definition_id = azurerm_policy_set_definition.this.id
}

resource "azurerm_management_group_policy_assignment" "this" {
  for_each = {
    for assignment in var.assignment.assignments :
    assignment.name => assignment.id
    if var.assignment.scope == "mg"
  }

  name                 = random_uuid.assignment[each.key].result
  management_group_id  = each.value
  policy_definition_id = azurerm_policy_set_definition.this.id
}

resource "azurerm_resource_group_policy_assignment" "this" {
  for_each = {
    for assignment in var.assignment.assignments :
    assignment.name => assignment.id
    if var.assignment.scope == "rg"
  }

  name                 = random_uuid.assignment[each.key].result
  resource_group_id    = each.value
  policy_definition_id = azurerm_policy_set_definition.this.id
}

locals {
  assignments = {
    sub = try(azurerm_subscription_policy_assignment.this, "")
    mg  = try(azurerm_management_group_policy_assignment.this, "")
    rg  = try(azurerm_resource_group_policy_assignment.this, "")
  }
}

resource "azurerm_subscription_policy_exemption" "this" {
  for_each = {
    for i in flatten([
      for assignment in var.assignment.assignments : [
        for exemption in var.exemptions : {
          id = format("%s_%s", assignment.name, element(
            split("/", exemption.id),
            length(split("/", exemption.id)) - 1
          ))
          data = {
            id       = exemption.id
            risk_id  = exemption.risk_id
            category = exemption.category
            assignment_id = one([
              for scope, assignment in local.assignments :
              assignment[exemption.assignment_reference].id
              if scope == var.assignment.scope
            ])
          }
        }
        if(
          exemption.assignment_reference == assignment.name
          && exemption.scope == "sub"
        )
      ]
    ]) : i.id => i.data
  }

  name = format(
    "%s_%s",
    random_uuid.exemptions.result,
    element(
      split("/", each.key),
      length(split("/", each.key)) - 1
    )
  )
  policy_assignment_id = each.value.assignment_id
  subscription_id      = each.value.id
  exemption_category   = each.value.category
  metadata = jsonencode({
    "risk_id" : "${each.value.risk_id}"
  })
}

resource "azurerm_management_group_policy_exemption" "this" {
  for_each = {
    for i in flatten([
      for assignment in var.assignment.assignments : [
        for exemption in var.exemptions : {
          id = format("%s_%s", assignment.name, element(
            split("/", exemption.id),
            length(split("/", exemption.id)) - 1
          ))
          data = {
            id       = exemption.id
            risk_id  = exemption.risk_id
            category = exemption.category
            assignment_id = one([
              for scope, assignment in local.assignments :
              assignment[exemption.assignment_reference].id
              if scope == var.assignment.scope
            ])
          }
        }
        if(
          exemption.assignment_reference == assignment.name
          && exemption.scope == "mg"
        )
      ]
    ]) : i.id => i.data
  }

  name = format(
    "%s_%s",
    random_uuid.exemptions.result,
    element(
      split("/", each.key),
      length(split("/", each.key)) - 1
    )
  )
  policy_assignment_id = each.value.assignment_id
  management_group_id  = each.value.id
  exemption_category   = each.value.category
  metadata = jsonencode({
    "risk_id" : "${each.value.risk_id}"
  })
}

resource "azurerm_resource_group_policy_exemption" "this" {
  for_each = {
    for i in flatten([
      for assignment in var.assignment.assignments : [
        for exemption in var.exemptions : {
          id = format("%s_%s", assignment.name, element(
            split("/", exemption.id),
            length(split("/", exemption.id)) - 1
          ))
          data = {
            id       = exemption.id
            risk_id  = exemption.risk_id
            category = exemption.category
            assignment_id = one([
              for scope, assignment in local.assignments :
              assignment[exemption.assignment_reference].id
              if scope == var.assignment.scope
            ])
          }
        }
        if(
          exemption.assignment_reference == assignment.name
          && exemption.scope == "rg"
        )
      ]
    ]) : i.id => i.data
  }

  name = format(
    "%s_%s",
    random_uuid.exemptions.result,
    element(
      split("/", each.key),
      length(split("/", each.key)) - 1
    )
  )
  policy_assignment_id = each.value.assignment_id
  resource_group_id    = each.value.id
  exemption_category   = each.value.category
  description = jsonencode({
    "risk_id" : "${each.value.risk_id}"
  })
}
