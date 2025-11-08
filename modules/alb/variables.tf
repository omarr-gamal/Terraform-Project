variable "name" { type = string }
variable "subnets" { type = list(string) }
variable "internal" { type = bool }
variable "target_instance_ids" { type = list(string) }
variable "target_port" { type = number }
variable "vpc_id" {
  type = string
}
