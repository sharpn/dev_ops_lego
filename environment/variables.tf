variable "environment_name" {
  type = string
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "cluster" {
  type = object({
    version = string
    nodes = list(object({
      min_size      = number
      max_size      = number
      desired_size  = number
      instance_type = optional(string)
    }))
  })
}
