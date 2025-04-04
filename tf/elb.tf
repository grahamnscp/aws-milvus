# elb for rancher

# elb on master nodes
resource "aws_elb" "rke-elb" {

  name = "${var.prefix}-rke-elb"

  subnets = [
    "${aws_subnet.dc-subnet1.id}",
    "${aws_subnet.dc-subnet2.id}",
    "${aws_subnet.dc-subnet3.id}"
  ]
  security_groups = [
    "${aws_security_group.dc-instance-sg.id}",
    "${aws_security_group.lb-sg.id}",
  ]
  cross_zone_load_balancing = true

  # tcp - pass https traffic through
  listener {
    lb_port = 6443
    lb_protocol = "tcp"
    instance_port = 6443
    instance_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 10
    timeout = 5
    target = "TCP:6443"
    interval = 10
  }

  instances = "${aws_instance.masters.*.id}"

  idle_timeout = 240
}

# elb on agent nodes
resource "aws_elb" "app-elb" {

  name = "${var.prefix}-app-elb"

  subnets = [
    "${aws_subnet.dc-subnet1.id}",
    "${aws_subnet.dc-subnet2.id}",
    "${aws_subnet.dc-subnet3.id}"
  ]
  security_groups = [
    "${aws_security_group.dc-instance-sg.id}",
    "${aws_security_group.lb-sg.id}",
  ]
  cross_zone_load_balancing = true

  # tcp - pass https traffic through
  listener {
    lb_port = 443
    lb_protocol = "tcp"
    instance_port = 443
    instance_protocol = "tcp"
  }
  listener {
    lb_port = 80
    lb_protocol = "tcp"
    instance_port = 80
    instance_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 10
    timeout = 5
    target = "TCP:443"
    interval = 10
  }

  instances = "${aws_instance.agents.*.id}"

  idle_timeout = 240
}
