# elastic ips

# Associate Elastic IPs to Instances
resource "aws_eip" "masters-eip" {

  count = "${var.master_count}"
  instance = "${element(aws_instance.masters.*.id, count.index)}"

  tags = {
    Name = "${var.prefix}-master${count.index + 1}"
  }

  depends_on = [aws_instance.masters]
}

resource "aws_eip" "agents-eip" {

  count = "${var.agent_count}"
  instance = "${element(aws_instance.agents.*.id, count.index)}"

  tags = {
    Name = "${var.prefix}-agent${count.index + 1}"
  }

  depends_on = [aws_instance.agents]
}
