#resource "aws_key_pair" "myKey" {
#  key_name   = "openTicate"
#  public_key = ""
#}



##TODO configure the type of node: etcd, all ....
data "template_cloudinit_config" "rancheragent-all-cloudinit" {
  count = "${var.new_node_count}"

  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancheragent-${count.index}-all\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata_agent.rendered}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "userdata_agent" {
  template = "${file("../terraform/files/userdata_agent")}"

  vars {
    admin_password       = "${var.admin_password}"
    cluster_name         = "${var.cluster_name}"
    docker_version_agent = "${var.docker_version_agent}"
    rancher_version      = "${var.rancher_version}"
    server_address       = "${data.aws_instance.rancherserver.public_ip}"
  }
}

data "aws_instance" "rancherserver" {
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-rancherserver"]
  }
}

data "aws_security_group" "rancher_sg_allowall" {
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-allowall"]
  }
}

data "aws_subnet" "sub_1" {
  filter {
    name   = "tag:Name"
    values = ["sub_1"]
  }
}

variable "rancher_version" {
  default     = "latest"
  description = "Rancher Server Version"
}

variable "prefix" {
  default     = "empty"
  description = "Cluster Prefix - All resources created by Terraform have this prefix prepended to them"
}

variable "docker_version_agent" {
  default     = "17.03"
  description = "Docker Version to run on Kubernetes Nodes"
}

variable "admin_password" {
  default     = "admin"
  description = "Password to set for the admin account in Rancher"
}

variable "cluster_name" {
  default     = "cluster1"
  description = "Kubernetes Cluster Name"
}

variable "new_node_type" {
  default     = "t2.medium"
  description = "Amazon AWS Instance Type"
}

variable "new_node_disk" {
  default     = "20"
  description = "Disk size"
}


variable "ssh_key_name" {
  default     = ""
  description = "Amazon AWS Key Pair Name"
}

variable "new_node_count" {
  default = "1"
  description = "Number of node to add"
}



resource "aws_instance" "instance" {
  count = "${var.new_node_count}"

  instance_type          = "${var.new_node_type}"
  ami                    = "${data.aws_ami.ubuntu.id}"
  key_name               = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${data.aws_security_group.rancher_sg_allowall.id}"]
  subnet_id              = "${data.aws_subnet.sub_1.id}"
  user_data       = "${data.template_cloudinit_config.rancheragent-all-cloudinit.*.rendered[count.index]}"
  vpc_security_group_ids = ["${data.aws_security_group.rancher_sg_allowall.id}"]


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
