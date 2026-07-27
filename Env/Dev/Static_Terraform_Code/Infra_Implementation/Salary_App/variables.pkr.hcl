variable "aws_region" {
  description = "AWS Region where the AMI will be built"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "application" {
  description = "Application name"
  type        = string
}

variable "owner" {
  description = "Resource owner"
  type        = string
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type used by Packer to build the AMI"
  type        = string
}

variable "ami_name" {
  description = "Base name of the AMI"
  type        = string
}

variable "subnet_id" {
  description = "Subnet where the temporary Packer instance will be launched"
  type        = string
}

variable "security_group_id" {
  description = "Security Group attached to the temporary Packer instance"
  type        = string
}
