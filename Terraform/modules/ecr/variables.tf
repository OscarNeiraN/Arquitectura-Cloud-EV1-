variable "project_name" {
  type        = string
  description = "Project name used for tags."
}

variable "repository_name" {
  type        = string
  description = "ECR repository name."
}

variable "force_delete" {
  type        = bool
  description = "Delete the repository even if it still contains images."
  default     = true
}
