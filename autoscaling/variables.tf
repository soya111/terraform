variable "vpc_id" {
  type        = string
  description = "default vpc id"
}

variable "subnet_ids" {
  type        = map(string)
  description = "subnet ids"
}

variable "default_security_group_id" {
  type        = string
  description = "default security group id"
}

variable "key_name" {
  type        = string
  description = "key name for launch template"
}
