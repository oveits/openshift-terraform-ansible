variable "IP_with_full_access" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "key_path" {}
#variable "security_group" {default = "default" }
variable "keypair" {default = "AWS_SSH_Key"}
variable "master_instance_type" {default = "c3.large"}
variable "node_instance_type" {default = "c3.large"}
variable "aws_availability_zone" { default = "eu-central-1a" }
variable "aws_region" { default = "eu-central-1" }
variable "ebs_root_block_size" {default = "50"}
# fedora 25:
#variable "aws_ami" {default = "ami-a6a15dc9" }
# CentOS 7:
variable "aws_ami" {default = "ami-9bf712f4" }
variable "ssh_user" {default = "centos"}
variable "inline_script" {default = "echo hallo"}
variable "num_nodes" { default = "2" }
variable "aws_vpc_openshift_cidr_block" {default = "10.50.0.0/16"}
variable "aws_subnet_openshift_master_nodes_cidr_block" {default = "10.50.1.0/24"}


resource "aws_vpc" "openshift" {
    cidr_block = "${var.aws_vpc_openshift_cidr_block}"

    tags {
        Name = "openshift"
    }
}

resource "aws_security_group" "openshift" {
  name = "openshift"
  description = "Allow all internal traffic, allow all traffic from creator"

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["${var.IP_with_full_access}/32"]
  }

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      self = "true"
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "openshift_master_nodes" {
    vpc_id = "${aws_vpc.openshift.id}"
    cidr_block = "${var.aws_subnet_openshift_master_nodes_cidr_block}"

    tags {
        Name = "OpenShift Master Nodes"
    }
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_instance" "ose-master" {
    ami = "${var.aws_ami}"
    instance_type = "${var.master_instance_type}"
    security_groups = [ "${aws_security_group.openshift.id}" ]
    availability_zone = "${var.aws_availability_zone}"
    key_name = "${var.keypair}"
    subnet_id = "${aws_subnet.openshift_master_nodes.id}"

    tags {
        Name = "master"
        sshUser = "${var.ssh_user}"
        role = "masters"
    }
        root_block_device = {
                volume_type = "gp2"
                volume_size = "${var.ebs_root_block_size}"
        }

    provisioner "remote-exec" {
        inline = [
            "${var.inline_script}"
            ]
        connection {
            user = "${var.ssh_user}"
            private_key = "${file("${var.key_path}")}"
        }
    }
}

resource "aws_instance" "ose-node" {
    count = "${var.num_nodes}"
    ami = "${var.aws_ami}"
    instance_type = "${var.node_instance_type}"
    security_groups = [ "${aws_security_group.openshift.id}" ]
    availability_zone = "${var.aws_availability_zone}"
    key_name = "${var.keypair}"
    subnet_id = "${aws_subnet.openshift_master_nodes.id}"

    tags {
        Name = "node${count.index}"
        sshUser = "${var.ssh_user}"
        role = "nodes"
    }
        root_block_device = {
                volume_type = "gp2"
                volume_size = "${var.ebs_root_block_size}"
        }

    provisioner "remote-exec" {
        inline = [
            "${var.inline_script}"
            ]
        connection {
            user = "${var.ssh_user}"
            private_key = "${file("${var.key_path}")}"
        }
    }
}
