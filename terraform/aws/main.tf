# Configure the Amazon AWS Provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
}

variable "aws_access_key" {
  default     = "xxx"
  description = "Amazon AWS Access Key"
}

variable "aws_secret_key" {
  default     = "xxx"
  description = "Amazon AWS Secret Key"
}

variable "prefix" {
  default     = "yourname"
  description = "Cluster Prefix - All resources created by Terraform have this prefix prepended to them"
}

variable "rancher_version" {
  default     = "latest"
  description = "Rancher Server Version"
}

variable "count_agent_all_nodes" {
  default     = "1"
  description = "Number of Agent All Designation Nodes"
}

variable "count_agent_etcd_nodes" {
  default     = "0"
  description = "Number of ETCD Nodes"
}

variable "count_agent_controlplane_nodes" {
  default     = "0"
  description = "Number of K8s Control Plane Nodes"
}

variable "count_agent_worker_nodes" {
  default     = "0"
  description = "Number of Worker Nodes"
}

variable "admin_password" {
  default     = "admin"
  description = "Password to set for the admin account in Rancher"
}

variable "cluster_name" {
  default     = "cluster1"
  description = "Kubernetes Cluster Name"
}

variable "region" {
  default     = "us-west-2"
  description = "Amazon AWS Region for deployment"
}

variable "type" {
  default     = "t2.medium"
  description = "Amazon AWS Instance Type"
}

variable "docker_version_server" {
  default     = "17.03"
  description = "Docker Version to run on Rancher Server"
}

variable "docker_version_agent" {
  default     = "17.03"
  description = "Docker Version to run on Kubernetes Nodes"
}

variable "ssh_key_name" {
  default     = ""
  description = "Amazon AWS Key Pair Name"
}

variable "availability_zone" {
  default = "us-east-1a"
  description = "AZ"
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

resource "aws_vpc" "OpenTicateVpc" {
    cidr_block = "172.31.0.0/16"
    tags {
      Name = "OpenTicateMain"
    }
    enable_dns_support = "true"
    enable_dns_hostnames = true
}

resource "aws_internet_gateway" "default" {
   vpc_id = "${aws_vpc.OpenTicateVpc.id}"
}

# Internet acces not necessary for now
resource "aws_route" "internet_access"{
  route_table_id          = "${aws_vpc.OpenTicateVpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id              = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "sub_1" {
  vpc_id = "${aws_vpc.OpenTicateVpc.id}"
  availability_zone = "${var.availability_zone}"
  cidr_block = "172.31.1.0/24"
  map_public_ip_on_launch = "true"
  tags {
   Name = "sub_1"
  }

}

resource "aws_security_group" "rancher_sg_allowall" {
  name = "${var.prefix}-allowall"
  vpc_id = "${aws_vpc.OpenTicateVpc.id}"

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
   Name = "${var.prefix}-allowall"
  }
}

data "template_cloudinit_config" "rancherserver-cloudinit" {
  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancherserver\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata_server.rendered}"
  }
}

resource "aws_instance" "rancherserver" {
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "${var.type}"
  key_name        = "${var.ssh_key_name}"
  user_data       = "${data.template_cloudinit_config.rancherserver-cloudinit.rendered}"
  subnet_id       = "${aws_subnet.sub_1.id}"  
  vpc_security_group_ids = ["${aws_security_group.rancher_sg_allowall.id}"]

  tags {
    Name = "${var.prefix}-rancherserver"
  }
}

data "template_cloudinit_config" "rancheragent-all-cloudinit" {
  count = "${var.count_agent_all_nodes}"

  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancheragent-${count.index}-all\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata_agent.rendered}"
  }
}

resource "aws_instance" "rancheragent-all" {
  count           = "${var.count_agent_all_nodes}"
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "${var.type}"
  key_name        = "${var.ssh_key_name}"
  user_data       = "${data.template_cloudinit_config.rancheragent-all-cloudinit.*.rendered[count.index]}"
  subnet_id       = "${aws_subnet.sub_1.id}"  
  vpc_security_group_ids = ["${aws_security_group.rancher_sg_allowall.id}"]


  tags {
    Name = "${var.prefix}-rancheragent-${count.index}-all"
  }
}

data "template_cloudinit_config" "rancheragent-etcd-cloudinit" {
  count = "${var.count_agent_etcd_nodes}"

  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancheragent-${count.index}-etcd\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata_agent.rendered}"
  }
}

resource "aws_instance" "rancheragent-etcd" {
  count           = "${var.count_agent_etcd_nodes}"
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "${var.type}"
  key_name        = "${var.ssh_key_name}"
  user_data       = "${data.template_cloudinit_config.rancheragent-etcd-cloudinit.*.rendered[count.index]}"
  subnet_id       = "${aws_subnet.sub_1.id}"  
  vpc_security_group_ids = ["${aws_security_group.rancher_sg_allowall.id}"]

  tags {
    Name = "${var.prefix}-rancheragent-${count.index}-etcd"
  }
}

data "template_cloudinit_config" "rancheragent-controlplane-cloudinit" {
  count = "${var.count_agent_controlplane_nodes}"

  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancheragent-${count.index}-controlplane\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata_agent.rendered}"
  }
}

resource "aws_instance" "rancheragent-controlplane" {
  count           = "${var.count_agent_controlplane_nodes}"
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "${var.type}"
  key_name        = "${var.ssh_key_name}"
  user_data     = "${data.template_cloudinit_config.rancheragent-controlplane-cloudinit.*.rendered[count.index]}"
  subnet_id       = "${aws_subnet.sub_1.id}"  
  vpc_security_group_ids = ["${aws_security_group.rancher_sg_allowall.id}"]

  tags {
    Name = "${var.prefix}-rancheragent-${count.index}-controlplane"
  }
}

data "template_cloudinit_config" "rancheragent-worker-cloudinit" {
  count = "${var.count_agent_worker_nodes}"

  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancheragent-${count.index}-worker\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata_agent.rendered}"
  }
}

resource "aws_instance" "rancheragent-worker" {
  count           = "${var.count_agent_worker_nodes}"
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "${var.type}"
  key_name        = "${var.ssh_key_name}"
  user_data       = "${data.template_cloudinit_config.rancheragent-worker-cloudinit.*.rendered[count.index]}"
  subnet_id       = "${aws_subnet.sub_1.id}"  
  vpc_security_group_ids = ["${aws_security_group.rancher_sg_allowall.id}"]

  tags {
    Name = "${var.prefix}-rancheragent-${count.index}-worker"
  }
}

data "template_file" "userdata_server" {
  template = "${file("../provisioning/KubernetesCluster/userdata_server")}"

  vars {
    admin_password        = "${var.admin_password}"
    cluster_name          = "${var.cluster_name}"
    docker_version_server = "${var.docker_version_server}"
    rancher_version       = "${var.rancher_version}"
  }
}


data "template_file" "userdata_agent" {
  template = "${file("../provisioning/KubernetesCluster/userdata_agent")}"

  vars {
    admin_password       = "${var.admin_password}"
    cluster_name         = "${var.cluster_name}"
    docker_version_agent = "${var.docker_version_agent}"
    rancher_version      = "${var.rancher_version}"
    server_address       = "${aws_instance.rancherserver.public_ip}"
  }
}

output "rancher-url" {
  value = ["https://${aws_instance.rancherserver.public_ip}"]
}
