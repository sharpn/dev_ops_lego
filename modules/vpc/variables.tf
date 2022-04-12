variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "private" {
  type = object({
    subnets = list(string)
    tags    = map(string)
  })
}

variable "public" {
  type = object({
    subnets = list(string)
    tags    = map(string)
  })
}

variable "tags" {
  type = map(string)
}
