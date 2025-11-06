variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "private_azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "ssh_pub_key" {
  type        = string
  description = "Content of the SSH public key"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Local path to SSH private key"
}

variable "backend_app_local_path" {
  type        = string
  default = "./app"
}
