############################################
# AWS
############################################

aws_region = "ap-south-1"


############################################
# Packer Build Instance
############################################

instance_type = "t3.micro"


############################################
# Existing AWS Key Pair
############################################

key_name = "mykey"


############################################
# Amazon Linux 2023 SSH User
############################################

ssh_username = "ec2-user"


############################################
# Backend IAM Instance Profile
############################################

backend_instance_profile_name = "aws_iam_instance_profile.backend_instance_profile.name"
