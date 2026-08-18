packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.3.0, < 2.0.0"
    }
  }
}

###############################################################################
# Source AMI
###############################################################################

source "amazon-ebs" "attendance" {

  region        = var.aws_region
  instance_type = var.instance_type

  ssh_username = "ubuntu"
  ssh_timeout  = "30m"

  ami_name        = "${var.ami_name}-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
  ami_description = "Golden AMI for OTMS Attendance API"

  source_ami_filter {

    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }

    owners      = ["099720109477"]
    most_recent = true
  }

  # Use the AWS default VPC.
  # subnet_id and security_group_ids are intentionally omitted.
  # Packer will use the default VPC and create/use its temporary
  # security group.

  associate_public_ip_address = true

  ena_support = true

  launch_block_device_mappings {

    device_name = "/dev/sda1"

    volume_size = 15

    volume_type = "gp3"

    delete_on_termination = true
  }

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
    CreatedBy   = "Packer"
  }
}

###############################################################################
# Build
###############################################################################

build {

  name = "attendance-api-golden-ami"

  sources = [
    "source.amazon-ebs.attendance"
  ]

  ############################################################
  # Install OS packages and Attendance API
  ############################################################

  provisioner "shell" {

    script = "install.sh"

    execute_command = "chmod +x {{ .Path }} && sudo {{ .Path }}"
  }

  ############################################################
  # Upload Attendance API Service
  ############################################################

  provisioner "file" {

    source      = "attendance-api.service"
    destination = "/tmp/attendance-api.service"
  }

  ############################################################
  # Upload Migration Service
  ############################################################

  provisioner "file" {

    source      = "attendance-migration.service"
    destination = "/tmp/attendance-migration.service"
  }

  ############################################################
  # Configure Application
  ############################################################

  provisioner "shell" {

    script = "configure.sh"

    execute_command = "chmod +x {{ .Path }} && sudo {{ .Path }}"
  }

  ############################################################
  # Validate AMI
  ############################################################

  provisioner "shell" {

    script = "validate.sh"

    execute_command = "chmod +x {{ .Path }} && sudo {{ .Path }}"
  }
}
