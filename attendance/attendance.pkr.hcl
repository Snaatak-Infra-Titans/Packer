packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.3.0, < 2.0.0"
    }
  }
}

source "amazon-ebs" "attendance" {

  region        = var.aws_region
  instance_type = var.instance_type
  ssh_username  = "ubuntu"
  ssh_timeout   = "20m"

  ami_name        = "${var.ami_name}-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
  ami_description = "Golden AMI for OTMS Attendance API with Liquibase support"

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
    Name        = var.ami_name
    Environment = var.environment
    Application = var.application
    Service     = "attendance-api"
    Owner       = var.owner
    CostCenter  = var.cost_center
    CreatedBy   = "Packer"
  }

  run_tags = {
    Name        = "attendance-api-packer-builder"
    Environment = var.environment
    Application = var.application
    Service     = "attendance-api"
    Owner       = var.owner
  }
}

build {

  name = "attendance-api-golden-ami"

  sources = [
    "source.amazon-ebs.attendance"
  ]

  #
  # Install required packages, Liquibase,
  # PostgreSQL JDBC driver and Attendance API
  #
  provisioner "shell" {
    script = "install.sh"
  }


  #
  # Copy Attendance API systemd service
  #
  provisioner "file" {
    source      = "attendance-api.service"
    destination = "/tmp/attendance-api.service"
  }

  #
  # Configure application, Liquibase and service
  #
  provisioner "shell" {
    script = "configure.sh"
  }

  #
  # Validate the AMI
  #
  provisioner "shell" {
    script = "validate.sh"
  }
}