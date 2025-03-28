# Route53 for instances

resource "aws_route53_record" "masters" {
  zone_id = "${var.route53_zone_id}"
  count = "${var.master_count}"
  name = "${var.prefix}-master${count.index + 1}.${var.route53_subdomain}.${var.route53_domain}"
  type = "A"
  ttl = "300"
  records = ["${element(aws_eip.masters-eip.*.public_ip, count.index)}"]
}
resource "aws_route53_record" "agents" {
  zone_id = "${var.route53_zone_id}"
  count = "${var.agent_count}"
  name = "${var.prefix}-agent${count.index + 1}.${var.route53_subdomain}.${var.route53_domain}"
  type = "A"
  ttl = "300"
  records = ["${element(aws_eip.agents-eip.*.public_ip, count.index)}"]
}

resource "aws_route53_record" "rke" {
  zone_id = "${var.route53_zone_id}"
  name = "rke.${var.route53_subdomain}.${var.route53_domain}"
  type = "CNAME"
  ttl = "60"
  records = [aws_elb.rke-elb.dns_name]
}

