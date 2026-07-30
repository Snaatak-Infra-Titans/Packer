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
  ssh_username  = "ubuntu"
  ssh_timeout   = "20m"

  ami_name        = "${var.ami_name}-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
  ami_description = "Golden AMI for OT-Micro Notification Service with Elasticsearch"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }

    owners      = ["099720109477"] # Canonical
    most_recent = true
  }

  subnet_id = var.subnet_id

  security_group_ids = [
    var.security_group_id
  ]

  

  associate_public_ip_address = true

  tags = {
    Name         = var.ami_name
    Environment  = var.environment
    Application  = var.application
    Owner        = var.owner
    CostCenter   = var.cost_center
    CreatedBy    = "Packer"
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
  # Install packages and application
  #
  provisioner "shell" {
    script = "install.sh"
  }

  #
  # Copy Notification API Service
  #
  provisioner "file" {
    source      = "notification-api.service"
    destination = "/tmp/notification-api.service"
  }

  #
  # Copy Notification Sync Service
  #
  provisioner "file" {
    source      = "notification-sync.service"
    destination = "/tmp/notification-sync.service"
  }

  #
  # Configure services
  #
  provisioner "shell" {
    script = "configure.sh"
  }

  #
  # Validate AMI
  #
  provisioner "shell" {
    script = "validate.sh"
  }

}
