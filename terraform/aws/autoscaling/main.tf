provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
}


#### VARIABLES #####
variable "aws_access_key" {
  default     = "xxx"
  description = "Amazon AWS Access Key"
}

variable "aws_secret_key" {
  default     = "xxx"
  description = "Amazon AWS Secret Key"
}

variable "region" {
  default     = "us-east-1"
  description = "Amazon AWS Region for deployment"
}

variable "autoscaling_max_instance_size" {
  default     = "5"
  description = "Autoscaling max instance"
}

variable "autoscaling_min_instance_size" {
  default     = "1"
  description = "Autoscaling min instance"
}

variable "autoscaling_desired_capacity" {
  default     = "1"
  description = "Autoscaling desired capacity"
}
variable "ssh_key_name" {
  default     = ""
  description = "Amazon AWS Key Pair Name"
}
variable "autoscaling-controlplane-type" {
  default     = "t2.medium"
  description = "Type for autoscaling control plane instance"
}
variable "etcd-controlplane-type" {
  default     = "t2.medium"
  description = "Type  for autoscaling etcd node"
}
variable "worker-controlplane-type" {
  default     = "t2.medium"
  description = "Type  for autoscaling worker node"
}



##### DATA SOURCES ####
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



#### LAUNCH CONFIGURATION ####
resource "aws_launch_configuration" "etcd-launch-configuration" {
    name                        = "etcd-launch-configuration"
    image_id                    = "ami-fad25980"
    instance_type               = "${var.autoscaling-etcd-type}"
    iam_instance_profile        = "${aws_iam_instance_profile.someprofile.id}"

    root_block_device {
      volume_type = "standard"
      volume_size = 100
      delete_on_termination = true
    }

    lifecycle {
      create_before_destroy = true
    }

    security_groups             = ["${aws_security_group.rancher_sg_allowall.id}"]
    associate_public_ip_address = "false"
    key_name                    = "${var.ecs_key_pair_name}"
    user_data                   = "${data.template_cloudinit_config.rancheragent-etcd-cloudinit.*.rendered[count.index]}"
}

resource "aws_launch_configuration" "controlplane-launch-configuration" {
    name                        = "controlplane-launch-configuration"
    image_id                    = "${data.aws_ami.ubuntu.id}"
    instance_type               = "${var.autoscaling-controlplane-type}"
    iam_instance_profile        = "${aws_iam_instance_profile.someprofile.id}"

    root_block_device {
      volume_type = "standard"
      volume_size = 100
      delete_on_termination = true
    }

    lifecycle {
      create_before_destroy = true
    }

    security_groups             = ["${aws_security_group.rancher_sg_allowall.id}"]
    associate_public_ip_address = "false"
    key_name                    = "${var.ecs_key_pair_name}"
    user_data                   = "${data.template_cloudinit_config.rancheragent-controlplane-cloudinit.*.rendered[count.index]}"
}

resource "aws_launch_configuration" "worker-launch-configuration" {
    name                        = "worker-launch-configuration"
    image_id                    = "${data.aws_ami.ubuntu.id}"
    instance_type               = "${var.autoscaling-worker-type}"
    iam_instance_profile        = "${aws_iam_instance_profile.someprofile.id}"

    root_block_device {
      volume_type = "standard"
      volume_size = 100
      delete_on_termination = true
    }

    lifecycle {
      create_before_destroy = true
    }

    security_groups             = ["${aws_security_group.rancher_sg_allowall.id}"]
    associate_public_ip_address = "false"
    key_name                    = "${var.ecs_key_pair_name}"
    user_data                   = "${data.template_cloudinit_config.rancheragent-worker-cloudinit.*.rendered[count.index]}"
}

#### AUTOSCALING GROUP ####
resource "aws_autoscaling_group" "etcd-autoscaling-group" {
    name                        = "kubernetes-auto-scaling-group"
    max_size                    = "${var.autoscaling_max_instance_size}"
    min_size                    = "${var.autoscaling_min_instance_size}"
    desired_capacity            = "${var.autoscaling_desired_capacity}"
    vpc_zone_identifier         = ["${aws_subnet.rancher_sg_allowall.id}"] #, "${aws_subnet.public_sub.id}"]
    launch_configuration        = "${aws_launch_configuration.etcd-launch-configuration.name}"
    health_check_type           = "ELB"
  }