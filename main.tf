module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  public_azs = var.public_azs
  private_azs = var.private_azs
}

# public proxies (2)
module "public_ec2" {
  source = "./modules/ec2"
  name_prefix = "proxy"
  subnet_ids = module.vpc.public_subnets
  instance_count = 2
  ami_filter = { name = "amzn2-ami-hvm-*-x86_64-gp2", owners = ["amazon"] }
  instance_type = "t3.micro"
  key_name = aws_key_pair.deployer.key_name
  ssh_private_key_path = var.ssh_private_key_path
  remote_commands = [
    "sudo yum update -y",
    "sudo amazon-linux-extras install -y nginx1",
    "sudo systemctl enable nginx",
    "sudo systemctl start nginx",
    # reverse proxy config would be placed by further remote-exec or file provisioner
  ]
  # do not upload app files for proxies
  copy_files = []
}

# private backends (2)
module "private_ec2" {
  source = "./modules/ec2"
  name_prefix = "backend"
  subnet_ids = module.vpc.private_subnets
  instance_count = 2
  ami_filter = { name = "amzn2-ami-hvm-*-x86_64-gp2", owners = ["amazon"] }
  instance_type = "t3.micro"
  key_name = aws_key_pair.deployer.key_name
  ssh_private_key_path = var.ssh_private_key_path
  remote_commands = [
    "sudo yum update -y",
    "sudo yum install -y python3 pip",
    "pip3 install flask",
    "sudo firewall-cmd --permanent --add-port=5000/tcp || true",
    "sudo firewall-cmd --reload || true",
  ]
  copy_files = [ var.backend_app_local_path ]
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh_pub_key
}

# ALBs
module "alb_public" {
  source = "./modules/alb"
  name = "public-alb"
  subnets = module.vpc.public_subnets
  internal = false
  target_instance_ids = module.public_ec2.instance_ids
  target_port = 80
}

module "alb_internal" {
  source = "./modules/alb"
  name = "internal-alb"
  subnets = module.vpc.private_subnets
  internal = true
  target_instance_ids = module.private_ec2.instance_ids
  target_port = 5000
}

# local-exec to write all-ips.txt
resource "null_resource" "write_ips" {
  depends_on = [
    module.public_ec2,
    module.private_ec2
  ]

  provisioner "local-exec" {
    command = <<EOT
echo "public-ip1 $(terraform output -raw public_proxy_ip_1 2>/dev/null || true)" > all-ips.txt
echo "public-ip2 $(terraform output -raw public_proxy_ip_2 2>/dev/null || true)" >> all-ips.txt
echo "private-ip1 $(terraform output -raw private_backend_ip_1 2>/dev/null || true)" >> all-ips.txt
echo "private-ip2 $(terraform output -raw private_backend_ip_2 2>/dev/null || true)" >> all-ips.txt
EOT
  }
}

