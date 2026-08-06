aws_region = "us-east-1"

environment = "dev"
application = "otms"

owner       = "Infra-Titans"
cost_center = "Snaatak"

instance_type = "m7i-flex.large"

ami_name = "dev-otms-attendance-api"

# Update these values before running Packer
subnet_id         = "subnet-0315113c2df0827d7"
security_group_id = "sg-05c72ddadd2b95bbe"
