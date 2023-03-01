variable "task_policy_arns" {
  type        = list(string)
  description = "A list of IAM Policy ARNs to attach to the generated task role."
  default     = []
}

variable "task_exec_policy_arns" {
  type        = list(string)
  description = "A list of IAM Policy ARNs to attach to the generated task execution role."
  default     = []
}
