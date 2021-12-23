# security_group_inputs Version: 1
#

variable "security_group_enabled" {
  type        = bool
  description = "Whether to create default Security Group for ECS service."
  default     = true
}

variable "security_group_rules" {
  type = list(any)
  default = [
    # {
    #   type        = "egress"
    #   from_port   = 0
    #   to_port     = 0
    #   protocol    = -1
    #   cidr_blocks = ["0.0.0.0/0"]
    #   description = "Allow all outbound traffic"
    # },
    # {
    #   type        = "ingress"
    #   from_port   = 8
    #   to_port     = 0
    #   protocol    = "icmp"
    #   cidr_blocks = ["0.0.0.0/0"]
    #   description = "Enables ping command from anywhere, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-rules-reference.html#sg-rules-ping"
    # }
  ]
  description = <<-EOT
    A list of maps of Security Group rules. 
    The values of map is fully complated with `aws_security_group_rule` resource. 
    To get more info see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule .
  EOT
}

variable "security_groups" {
  type        = list(string)
  description = "A list of Security Group IDs to allow in Service `network_configuration` if `var.network_mode = \"awsvpc\"`"
  default     = []
}

locals {
  allowed_security_group_ids = concat(var.security_groups, var.allowed_security_group_ids)
}

variable "associated_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups allowed to connect to the ECS Service, in addition to the created security group.
    EOT
}

variable "allowed_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups to allow access to the security group created by this module.
    EOT
}

variable "security_group_name" {
  type        = list(string)
  default     = []
  description = <<-EOT
    The name to assign to the created security group. Must be unique within the VPC.
    If not provided, will be derived from the `null-label.context` passed in.
    If `create_before_destroy` is true, will be used as a name prefix.
    EOT
}

variable "security_group_description" {
  type        = string
  default     = "EFS Security Group"
  description = <<-EOT
    The description to assign to the created Security Group.
    Warning: Changing the description causes the security group to be replaced.
    EOT
}

variable "security_group_create_before_destroy" {
  type        = bool
  default     = true
  description = <<-EOT
    Set `true` to enable Terraform `create_before_destroy` behavior on the created security group.
    Note that changing this value will always cause the security group to be replaced.
    EOT
}

variable "security_group_create_timeout" {
  type        = string
  default     = "10m"
  description = "How long to wait for the security group to be created."
}

variable "security_group_delete_timeout" {
  type        = string
  default     = "15m"
  description = <<-EOT
    How long to retry on `DependencyViolation` errors during security group deletion from
    lingering ENIs left by certain AWS services such as Elastic Load Balancing.
    EOT
}

variable "additional_security_group_rules" {
  type        = list(any)
  default     = []
  description = <<-EOT
    A list of Security Group rule objects to add to the created security group, in addition to the ones
    this module normally creates. (To suppress the module's rules, set `create_security_group` to false
    and supply your own security group via `associated_security_group_ids`.)
    The keys and values of the objects are fully compatible with the `aws_security_group_rule` resource, except
    for `security_group_id` which will be ignored, and the optional "key" which, if provided, must be unique and known at "plan" time.
    To get more info see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule .
    EOT
}