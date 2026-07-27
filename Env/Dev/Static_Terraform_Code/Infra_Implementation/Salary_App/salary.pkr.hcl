packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.3.0, < 2.0.0"
    }
  }
}

source "amazon-ebs" "salary" {

  region        = var.aws_region
  instance_type = var.instance_type
  ssh_username  = "ubuntu"
  ssh_timeout   = "20m"

  ami_name        = "${var.ami_name}-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
  ami_description = "Golden AMI for OTMS Salary API"

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
    Owner       = var.owner
    CostCenter  = var.cost_center
    CreatedBy   = "Packer"
  }

  run_tags = {
    Name        = "salary-packer-builder"
    Environment = var.environment
    Application = var.application
    Owner       = var.owner
  }
}

build {

  name = "salary-golden-ami"

  sources = [
    "source.amazon-ebs.salary"
  ]

  #
  # Install Java, Maven and Salary Application
  #
  provisioner "shell" {
    script = "install.sh"
  }

  #
  # Copy Salary Service
  #
  provisioner "file" {
    source      = "salary.service"
    destination = "/tmp/salary.service"
  }

  #
  # Configure Salary Service
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
