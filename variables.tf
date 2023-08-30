#
# app variables
#
variable "app_name" {
  type    = string
  default = "jha"
}

#
# aws provider variables
#
variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

#
# vpc and subnet variables
#
variable "vpc_cidr_block" {
  type    = string
  default = "172.16.10.0/16"
}

variable "public_subnet_cidr_block" {
  type    = string
  default = "172.16.10.0/24"
}

#
# ec2 variables
#
variable "ec2_ami" {
  type    = string
  default = "ami-06f25f372d5d98da3"
}

variable "ec2_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ec2_domain" {
  type = string
}

variable "ec2_hosted_zone_name" {
  type = string
}
