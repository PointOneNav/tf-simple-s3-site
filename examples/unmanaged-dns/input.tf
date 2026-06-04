variable "bucket" {
  type = string
}

variable "hostnames" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "create_iam_user" {
  type    = bool
  default = true
}

variable "github_actions_deploy" {
  type = object({
    allowed_repos        = list(string)
    allowed_branches     = optional(list(string))
    allowed_environments = optional(list(string))
  })
  default = null
}
