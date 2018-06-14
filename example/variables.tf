variable "name" {
  type        = "string"
  description = "Name (unique identifier for app or service)"
}

variable "namespace" {
  type        = "string"
  description = "Namespace (e.g. `cp` or `cloudposse`)"
}

variable "delimiter" {
  description = "The delimiter to be used in labels."
  default     = "-"
}

variable "stage" {
  type        = "string"
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}

variable "attributes" {
  type        = "list"
  description = "List of attributes to add to label."
  default     = []
}

variable "tags" {
  type        = "map"
  description = "Map of key-value pairs to use for tags."
  default     = {}
}

variable "region" {
  type        = "string"
  description = "AWS region"
}

variable "github_oauth_token" {
  description = "GitHub Oauth Token with permissions to access private repositories"
}

variable "repo_owner" {
  description = "GitHub Organization or Username."
}

variable "repo_name" {
  description = "GitHub repository name of the application to be built and deployed to ECS."
}

variable "branch" {
  description = "Branch of the GitHub repository, e.g. master"
}
