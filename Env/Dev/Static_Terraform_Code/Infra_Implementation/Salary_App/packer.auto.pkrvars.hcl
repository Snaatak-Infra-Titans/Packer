aws_region        = "ap-south-1"
environment       = "dev"
application       = "otms"
owner             = "Infra-Titans"
cost_center       = "Snaatak"

instance_type     = "t3.small"

ami_name          = "salary-golden-v1"

# These values are overwritten dynamically by packer-build.sh
# after discovering the backend subnet and Salary Packer SG.
subnet_id         = "subnet-xxxxxxxxxxxxxxxxx"
security_group_id = "sg-xxxxxxxxxxxxxxxxx"
