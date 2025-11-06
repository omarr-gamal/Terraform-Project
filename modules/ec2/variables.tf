variable "name_prefix" { type = string }
variable "subnet_ids" { type = list(string) }
variable "instance_count" { type = number }
variable "ami_filter" { type = map(any) }
variable "instance_type" { type = string }
variable "key_name" { type = string }
variable "ssh_private_key_path" { type = string }
variable "remote_commands" { type = list(string) }
variable "copy_files" { type = list(string) } # local paths to copy to instances

