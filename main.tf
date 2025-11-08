module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  public_azs = var.public_azs
  private_azs = var.private_azs
}

locals {
  nginx_conf_content = templatefile("${path.root}/nginx.conf.tpl", {
    internal_alb_dns = module.alb_internal.lb_dns
  })
}

resource "local_file" "rendered_nginx_conf" {
  content  = local.nginx_conf_content
  filename = "${path.root}/rendered-nginx.conf"
}

# public proxies (2)
module "public_ec2" {
  source = "./modules/ec2"
  name_prefix = "proxy"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
  instance_count = 2
  ami_filter = { name = "amzn2-ami-hvm-*-x86_64-gp2", owner = "amazon" }
  instance_type = "t3.micro"
  key_name = aws_key_pair.deployer.key_name
  ssh_private_key_path = var.ssh_private_key_path

  depends_on = [local_file.rendered_nginx_conf]

  remote_commands = [
    "sudo yum update -y",
    "sudo amazon-linux-extras install -y nginx1",
    "sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf",
    "sudo nginx -t",
    "sudo systemctl enable nginx",
    "sudo systemctl start nginx",
  ]

  copy_file = {
    source      = "${path.root}/rendered-nginx.conf"
    destination = "/tmp/nginx.conf"
  }
}


locals {
  backend_archive = "/tmp/backend_app.tar.gz"
}

resource "null_resource" "archive_backend" {
  provisioner "local-exec" {
    command = "tar -czf ${local.backend_archive} -C $(dirname ${var.backend_app_local_path}) $(basename ${var.backend_app_local_path})"
  }
}

module "private_ec2" {
  source = "./modules/ec2"
  name_prefix = "backend"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  instance_count = 2
  ami_filter = { name = "amzn2-ami-hvm-*-x86_64-gp2", owner = "amazon" }
  instance_type = "t3.micro"
  key_name = aws_key_pair.deployer.key_name
  ssh_private_key_path = var.ssh_private_key_path

  remote_commands = [
    "sudo yum update -y",
    "sudo yum install -y python3 pip",
    "pip3 install flask",
    "mkdir -p /home/ec2-user/app",
    "tar -xzf /home/ec2-user/backend_app.tar.gz",
    "sudo firewall-cmd --permanent --add-port=5000/tcp || true",
    "sudo firewall-cmd --reload || true",
    "sudo loginctl enable-linger ec2-user",
    "nohup setsid /usr/bin/python3 /home/ec2-user/app/app.py > /home/ec2-user/app/flask.log 2>&1 &",
    "sleep 2",
  ]

  # Wait for archive to exist
  depends_on = [null_resource.archive_backend]

  copy_file = {
    source      = local.backend_archive
    destination = "/home/ec2-user/backend_app.tar.gz"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh_pub_key
}

# ALBs
module "alb_public" {
  source = "./modules/alb"
  name = "public-alb"
  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  internal = false
  target_instance_ids = module.public_ec2.instance_ids
  target_port = 80
}

module "alb_internal" {
  source = "./modules/alb"
  name = "int-alb"
  vpc_id = module.vpc.vpc_id
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
echo "public_alb_dns: ${module.alb_public.lb_dns}" > all-ips.txt
echo "internal_alb_dns: ${module.alb_internal.lb_dns}" >> all-ips.txt
echo "public_proxy_ip_1: ${element(module.public_ec2.public_ips, 0)}" >> all-ips.txt
echo "public_proxy_ip_2: ${element(module.public_ec2.public_ips, 1)}" >> all-ips.txt
echo "private_backend_ip_1: ${element(module.private_ec2.private_ips, 0)}" >> all-ips.txt
echo "private_backend_ip_2: ${element(module.private_ec2.private_ips, 1)}" >> all-ips.txt
EOT
  }
}

