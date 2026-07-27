aws_region    = "us-east-1"
environment   = "dev"
application   = "otms"
owner         = "Infra-Titans"
cost_center   = "Snaatak"

instance_type = "t3.small"

ami_name = "salary-golden-v1"

# These values are discovered dynamically by packer-build.sh
subnet_id         = ""
security_group_id = ""
