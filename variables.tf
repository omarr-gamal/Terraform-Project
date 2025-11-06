variable "aws_region" { type = string; default = "us-east-1" }
variable "vpc_cidr" { type = string; default = "10.0.0.0/16" }
variable "public_azs" { type = list(string); default = ["us-east-1a", "us-east-1b"] }
variable "private_azs" { type = list(string); default = ["us-east-1a", "us-east-1b"] }
variable "ssh_pub_key" { type = string } # content of public key
variable "ssh_private_key_path" { type = string } # local path for connection
variable "backend_app_local_path" { type = string } # path to web app files to copy

