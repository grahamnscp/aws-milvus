# Output Values:

# Domain
output "domainname" {
  value = "${var.route53_subdomain}.${var.route53_domain}"
}

# Instances

# masters:
output "instance-master-private-ips" {
  value = ["${aws_instance.masters.*.private_ip}"]
}
output "instance-master-public-ips" {
  value = ["${aws_eip.masters-eip.*.public_ip}"]
}
output "instance-master-names" {
  value = ["${aws_route53_record.masters.*.name}"]
}

# agents:
output "instance-agent-private-ips" {
  value = ["${aws_instance.agents.*.private_ip}"]
}
output "instance-agent-public-ips" {
  value = ["${aws_eip.agents-eip.*.public_ip}"]
}
output "instance-agent-names" {
  value = ["${aws_route53_record.agents.*.name}"]
}
