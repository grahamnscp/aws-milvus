# security-lb

resource "aws_security_group" "lb-sg" {

  name = "${var.prefix}-lb_sg-${random_string.suffix.result}"
  description = "Security Group for LB"

  tags = {
    Name = "${var.prefix}_lb_sg"
  }

  vpc_id = "${aws_vpc.dc-vpc.id}"

  # allow self
  ingress {
    description = "Self"
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  # allow all for internal subnet
  ingress {
    description = "Internal VPC"
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["172.20.0.0/16"]
  }

  # open all for specific ips
  ingress {
    description = "Allow IPs"
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.ip_cidr_me}","${var.ip_cidr_work}"]
  }

  # egress out for all
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

