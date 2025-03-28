# Global Variables:

variable "prefix" {
  type = string
}


# domain
variable "route53_zone_id" {
  type = string
}
variable "route53_domain" {
  type = string
}
variable "route53_subdomain" {
  type = string
}

# default tags:
variable "aws_tags" {
  description = "Default tags to use for AWS"
  type = map(string)
}

# provider:
variable "aws_profile" {
  type = string
}
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}


# security group ips:
variable "ip_cidr_me" {
  type = string
}
variable "ip_cidr_work" {
  type = string
}


# instances:
variable "aws_ami" {
  type = string
}
variable "aws_key_name" {
  type = string
}

# instance sizes and counts
variable "aws_instance_type_master" {
  type = string
}
variable "master_count" {
  type = string
}

variable "aws_instance_type_agent" {
  type = string
}
variable "agent_count" {
  type = string
}

# instance volume sizes
variable "volume_size" {
  type = string
}
variable "volume_size_second_disk" {
  type = string
}
#variable "volume_size_third_disk" {
#  type = string
#}


# vpc:
variable "dnsSupport" {
  default = true
}
variable "dnsHostNames" {
  default = true
}
variable "vpcCIDRblock" {
  default = "172.20.0.0/16"
}
variable "subnet1CIDRblock" {
  default = "172.20.1.0/24"
}
variable "subnet2CIDRblock" {
  default = "172.20.2.0/24"
}
variable "subnet3CIDRblock" {
  default = "172.20.3.0/24"
}
variable "subnetCIDRspublic" {
  description = "Subnet CIDRs for public subnets"
  default = ["172.20.1.0/24", "172.20.2.0/24", "172.20.3.0/24"]
  type = list
}
variable "availability_zones" {
  description = "AZs in this region to use"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
  type = list
}
variable "destinationCIDRblock" {
  default = "0.0.0.0/0"
}
variable "ingressCIDRblock" {
  # type = "list"
  default = [ "0.0.0.0/0" ]
}
variable "mapPublicIP" {
  default = true
}
variable "instanceTenancy" {
  default = "default"
}
variable "availability_zone" {
  default = "us-east-1a"
}
