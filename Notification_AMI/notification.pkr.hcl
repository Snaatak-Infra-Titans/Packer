packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.3.0, < 2.0.0"
    }
  }
}

source "amazon-ebs" "notification" {

  region        = var.aws_region
  instance_type = var.instance_type

  ssh_username = "ubuntu"
  ssh_timeout  = "20m"

  ami_name        = "${var.ami_name}-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
  ami_description = "Golden AMI for OT-Micro Notification Service with Elasticsearch"

  #
  # Automatically select the default VPC in the configured AWS region.
  #
  vpc_filter {
    filters = {
      "isDefault" = "true"
    }
  }

  #
  # Automatically select an available default subnet.
  # If more than one default subnet exists, use the one with the
  # most free IPv4 addresses.
  #
  subnet_filter {
    filters = {
      "default-for-az"   = "true"
      "state"             = "available"
      "availability-zone" = "us-east-1a"
    }

    most_free = true
  }

  #
  # Automatically select the latest Ubuntu 22.04 AMI.
  #
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }

    owners      = ["099720109477"]
    most_recent = true
  }

  #
  # Give the temporary Packer instance a public IP so Packer can
  # connect over SSH. Packer creates a temporary security group.
  #
  associate_public_ip_address               = true
  temporary_security_group_source_public_ip = true

  tags = {
    Name        = var.ami_name
    Environment = var.environment
    Application = var.application
    Owner       = var.owner
    CostCenter  = var.cost_center
    CreatedBy   = "Packer"
  }

  run_tags = {
    Name        = "notification-packer-builder"
    Environment = var.environment
    Application = var.application
    Owner       = var.owner
  }
}

build {

  name = "notification-golden-ami"

  sources = [
    "source.amazon-ebs.notification"
  ]

  #
  # Install OS packages, Elasticsearch and Notification application.
  #
  provisioner "shell" {
    script = "install.sh"
  }

  #
  # Copy Notification API systemd service.
  #
  provisioner "file" {
    source      = "notification-api.service"
    destination = "/tmp/notification-api.service"
  }

  #
  # Configure and start services.
  #
  provisioner "shell" {
    script = "configure.sh"
  }

  #
  # Validate the completed AMI before Packer creates the image.
  #
  provisioner "shell" {
    script = "validate.sh"
  }
}
