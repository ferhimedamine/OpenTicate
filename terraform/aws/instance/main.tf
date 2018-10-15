#resource "aws_key_pair" "myKey" {
#  key_name   = "openTicate"
#  public_key = ""
#}

resource "aws_instance" "instance" {
  count = "${var.new_node_count}"

  instance_type          = "${var.new_node_type}"
  ami                    = "${data.aws_ami.ubuntu.id}"
  key_name               = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${var.security_group_id}"]
  subnet_id              = "${aws_subnet.sub_1.id}"
  user_data       = "${data.template_cloudinit_config.rancheragent-all-cloudinit.*.rendered[count.index]}"
  vpc_security_group_ids = ["${aws_security_group.rancher_sg_allowall.id}"]


  root_block_device {
      volume_size = "${var.new_node_disk}"
  }
  
  tags {
      Name = "${var.prefix}-rancheragent-${count.index}-all"
      Group = "${var.prefix}"
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  # Example Provisioning
  
  #connection {
  #  user = "ubuntu"
  #  private_key = "${file(var.private_key_path)}"
  #}

  # You can call scripts here
  #provisioner "remote-exec" {
  #  inline = [
  #    "echo toto",
  #  ]
  #}
}
