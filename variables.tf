variable "initiative_definition" {
  type        = string
  description = <<DESC
    (Required) path to the initiative definition file
  DESC
}

variable "environment" {
  type        = string
  description = <<DESC
    (Required) environment that the initiatives should be applied to.
  DESC
}

variable "assignment" {
  type = object({
    assignments = list(object({
      id   = string
      name = string
    }))
    scope = optional(string, "rg")
  })
  description = <<DESC
    (Required) assignment details for the policy.
    Properties:
      `assignments` (Required)    - list of assignments
        `id` (Required)   - resource ID
        `name` (Required) - friendly name/reference for the assignment
      `scope` (Optional)          - resource scope for assignment [Default: `rg`]

  DESC

  validation {
    condition = contains(
      ["sub", "mg", "rg"],
      var.assignment.scope
    )
    error_message = "Err: invalid assignment scope."
  }
}

variable "exemptions" {
  type = list(object({
    id                   = string
    risk_id              = string
    scope                = string
    category             = string
    assignment_reference = string
  }))
  description = <<DESC
    (Optional) List of exemption objects
    Properties:
      `id` (Required)                   - the resource ID for the exemption
      `risk_id` (Required)              - internal risk reference ID
      `scope` (Required)                - the scope for the exemption (sub, mg, rg)
      `category` (Required)             - exemption category
      `assignment_reference` (Required) - assignment friendly name/reference
  DESC

  validation {
    condition = alltrue(
      [
        for exemption in var.exemptions :
        contains(
          ["sub", "mg", "rg"],
          exemption.scope
        )
      ]
    )
    error_message = "Err: invalid exemption scope."
  }

  validation {
    condition = alltrue(
      [
        for exemption in var.exemptions :
        contains(
          ["Mitigated", "Waiver"],
          exemption.category
        )
      ]
    )
    error_message = "Err: invalid exemption category."
  }

  default = []
}

