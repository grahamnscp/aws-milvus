# Instances:

# Downstream Cluster Nodes
# rke3 masters:
resource "aws_instance" "masters" {

  instance_type = "${var.aws_instance_type_master}"
  ami           = "${var.aws_ami}"
  key_name      = "${var.aws_key_name}"

  root_block_device {
    volume_size = "${var.volume_size}"
    volume_type = "gp2"
    delete_on_termination = true
  }

  # second disk
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "${var.volume_size_second_disk}"
    volume_type = "gp2"
    delete_on_termination = true
  }

  iam_instance_profile = "${aws_iam_instance_profile.rancher_instance_profile.id}"

  vpc_security_group_ids = ["${aws_security_group.dc-instance-sg.id}"]
  subnet_id = "${aws_subnet.dc-subnet1.id}"

  user_data = "${file("master-userdata.sh")}"

  count = "${var.master_count}"

  tags = {
    Name = "${var.prefix}-master${count.index + 1}"
  }
}

# rke2 agents:
resource "aws_instance" "agents" {

  instance_type = "${var.aws_instance_type_agent}"
  ami           = "${var.aws_ami}"
  key_name      = "${var.aws_key_name}"

  root_block_device {
    volume_size = "${var.volume_size}"
    volume_type = "gp2"
    delete_on_termination = true
  }

  # second disk
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "${var.volume_size_second_disk}"
    volume_type = "gp2"
    delete_on_termination = true
  }

  # third disk
  #ebs_block_device {
  #  device_name = "/dev/sdc"
  #  volume_size = "${var.volume_size_third_disk}"
  #  volume_type = "gp2"
  #  delete_on_termination = true
  #}

  iam_instance_profile = "${aws_iam_instance_profile.rancher_instance_profile.id}"

  vpc_security_group_ids = ["${aws_security_group.dc-instance-sg.id}"]
  subnet_id = "${aws_subnet.dc-subnet1.id}"

  user_data = "${file("agent-userdata.sh")}"

  count = "${var.agent_count}"

  tags = {
    Name = "${var.prefix}-agent${count.index + 1}"
  }
}

