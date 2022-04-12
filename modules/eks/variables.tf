variable "cluster" {
  type = object({
    name    = string
    version = string
    node_groups = map(object({
      scaling = object({
        min_size     = number
        max_size     = number
        desired_size = number
      })
      instance_type = string
    }))
  })
}

variable "vpc" {
  type = object({
    id                 = string
    private_subnet_ids = list(string)
  })
}
