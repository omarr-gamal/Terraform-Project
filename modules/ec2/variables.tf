variable "name_prefix" { type = string }
variable "vpc_id" {
  type = string
}
variable "subnet_ids" { type = list(string) }
variable "instance_count" { type = number }
variable "ami_filter" { 
  type = map(any) 
  default = {
      name   = "amzn2-ami-hvm-*-x86_64-gp2"
      owner  = "amazon"
  }
}
variable "instance_type" { type = string }
variable "key_name" { type = string }
variable "ssh_private_key_path" { type = string }
variable "remote_commands" { type = list(string) }
variable "copy_files" {
  description = "List of files to copy"
  type = list(object({
    source      = string
    destination = string
  }))
  default = []
}
