packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.8"
    }
  }
}

variable "app_name" {
  type = string
}

variable "artifact_file" {
  type = string
}

variable "artifact_manifest_file" {
  type = string
}

variable "artifact_sha256" {
  type = string
}

variable "install_script" {
  type = string
}

variable "git_sha" {
  type = string
}

variable "git_branch" {
  type = string
}

variable "ci_job" {
  type = string
}

variable "ci_build" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "packer_manifest_file" {
  type = string
}

locals {
  short_sha = substr(var.git_sha, 0, 12)
}

source "amazon-ebs" "application" {
  ami_name      = "otms-${var.app_name}-${local.short_sha}-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.aws_region
  ssh_username  = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name           = "otms-${var.app_name}-${local.short_sha}"
    Application    = var.app_name
    GitSha         = var.git_sha
    GitBranch      = var.git_branch
    CIJob          = var.ci_job
    CIBuild        = var.ci_build
    ArtifactSha256 = var.artifact_sha256
    BuiltBy        = "Jenkins-Packer"
    Purpose        = "OTMS-application-golden-image"
  }
}

build {
  name    = "otms-${var.app_name}"
  sources = ["source.amazon-ebs.application"]

  provisioner "file" {
    source      = var.artifact_file
    destination = "/tmp/application-artifact"
  }

  provisioner "file" {
    source      = var.artifact_manifest_file
    destination = "/tmp/artifact-manifest.json"
  }

  provisioner "file" {
    source      = var.install_script
    destination = "/tmp/install-application.sh"
  }

  provisioner "shell" {
    environment_vars = [
      "APP_NAME=${var.app_name}",
      "ARTIFACT_SHA256=${var.artifact_sha256}"
    ]
    inline = [
      "set -euo pipefail",
      "echo \"${var.artifact_sha256}  /tmp/application-artifact\" | sha256sum --check --strict",
      "chmod 0755 /tmp/install-application.sh",
      "sudo -E /tmp/install-application.sh /tmp/application-artifact",
      "sudo install -d -m 0755 /etc/otms",
      "sudo install -m 0644 /tmp/artifact-manifest.json /etc/otms/${var.app_name}-image-manifest.json",
      "sudo rm -f /tmp/application-artifact /tmp/artifact-manifest.json /tmp/install-application.sh"
    ]
  }

  post-processor "manifest" {
    output     = var.packer_manifest_file
    strip_path = true
  }
}
