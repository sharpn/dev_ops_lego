variable "name" {
  description = "The name of the vpc"
  type = string
}

variable "cidr" {
  description = "The cidr block of the vpc"
  type = string
}

variable "environment" {
  type = string
}

variable "availability_zones" {
  description = "The availability zones of the vpc"
  type = list(string)
}

variable "private" {
  description = "The private subnets and tags of the vpc"
  type = object({
    subnets = list(string)
    tags    = map(string)
  })
}

variable "public" {
  description = "The public subnets and tags of the vpc"
  type = object({
    subnets = list(string)
    tags    = map(string)
  })
}

variable "tags" {
  description = "The global tags for all resources in the vpc"
  type = map(string)
}
