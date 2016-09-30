# OV: TODO:
# security group must not be too restrictive: it must allow connection from internal network 172.31.0.0/20

# OV: now replaced by "source .aws_creds, which sets TF_VAR_aws_access_key and TF_VAR_aws_secret_key accordingly:
# variable "aws_access_key" {default = "AXXXXXXXXXXXXXXXXXXX"}
# variable "aws_secret_key" {default = "SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "key_path" {}
variable "security_group" {default = "default" }
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

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_instance" "ose-master" {
    ami = "${var.aws_ami}"
    instance_type = "${var.master_instance_type}"
    security_groups = [ "default", "${var.security_group}" ]
    availability_zone = "${var.aws_availability_zone}"
    key_name = "${var.keypair}"
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
        # key_file = "${var.key_path}"
        private_key = "${file("${var.key_path}")}"
    }
  }
}

resource "aws_instance" "ose-node" {
    count = "${var.num_nodes}"
    ami = "${var.aws_ami}"
    instance_type = "${var.node_instance_type}"
    security_groups = [ "default", "${var.security_group}" ]
    availability_zone = "${var.aws_availability_zone}"
    key_name = "${var.keypair}"
    tags {
        #Name = "${concat("node", count.index)}" 
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
        # key_file = "${var.key_path}"
        private_key = "${file("${var.key_path}")}"
    }
  }
}
