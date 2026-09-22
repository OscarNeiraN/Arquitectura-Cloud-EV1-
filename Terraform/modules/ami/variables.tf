variable "ami_config" {
  type = object({
    most_recent = bool
    owners      = list(string)
    filters = list(object({
      name   = string
      values = list(string)
    }))
  })
}
