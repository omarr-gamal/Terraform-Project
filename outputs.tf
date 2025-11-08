output "public_alb_dns" {
  value = module.alb_public.lb_dns
}
output "internal_alb_dns" {
  value = module.alb_internal.lb_dns
}

output "public_proxy_ip_1" {
  value = element(module.public_ec2.public_ips, 0)
}
output "public_proxy_ip_2" {
  value = element(module.public_ec2.public_ips, 1)
}
output "private_backend_ip_1" {
  value = element(module.private_ec2.private_ips, 0)
}
output "private_backend_ip_2" {
  value = element(module.private_ec2.private_ips, 1)
}

