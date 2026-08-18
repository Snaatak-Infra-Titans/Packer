###############################################################################
# AWS Region
###############################################################################

variable "aws_region" {

  description = "AWS Region where the Golden AMI will be created."

  type = string

  validation {

    condition = length(trimspace(var.aws_region)) > 0

    error_message = "AWS Region cannot be empty."

  }

}

###############################################################################
# Environment
###############################################################################

variable "environment" {

  description = "Deployment environment."

  type = string

  validation {

    condition = contains(
      ["dev", "qa", "stage", "prod"],
      lower(var.environment)
    )

    error_message = "Environment must be one of: dev, qa, stage, prod."

  }

}

###############################################################################
# Application
###############################################################################

variable "application" {

  description = "Application name."

  type = string

  validation {

    condition = length(trimspace(var.application)) > 0

    error_message = "Application cannot be empty."

  }

}

###############################################################################
# Owner
###############################################################################

variable "owner" {

  description = "Resource owner."

  type = string

  validation {

    condition = length(trimspace(var.owner)) > 0

    error_message = "Owner cannot be empty."

  }

}

###############################################################################
# Cost Center
###############################################################################

variable "cost_center" {

  description = "Cost center."

  type = string

  validation {

    condition = length(trimspace(var.cost_center)) > 0

    error_message = "Cost Center cannot be empty."

  }

}

###############################################################################
# EC2 Instance Type
###############################################################################

variable "instance_type" {

  description = "EC2 instance type used by Packer to build the Golden AMI."

  type = string

}

###############################################################################
# AMI Name
###############################################################################

variable "ami_name" {

  description = "Base name of the Attendance API Golden AMI."

  type = string

  validation {

    condition = length(trimspace(var.ami_name)) > 0

    error_message = "AMI name cannot be empty."

  }

}

