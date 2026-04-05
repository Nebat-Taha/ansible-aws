# terraform/regions/us-east-1/main.tf

module "vpc" {
  source             = "../../modules/vpc"
  project_name       = var.project_name
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"

}

# --- ADD THIS: The Security Group Module ---
module "ec2_sg" {
  source       = "../../modules/security_groups"
  name         = "${var.project_name}-mongodb-sg"
  vpc_id       = module.vpc.vpc_id # Pass the VPC ID from the VPC module
  project_name = var.project_name
  vpc_cidr     = module.vpc.vpc_cidr
}



module "ec2_mongodb" {
  source               = "../../modules/ec2"
  project_name         = var.project_name
  instance_type        = "t2.micro"
  public_subnet_id     = module.vpc.public_subnet_id
  security_group_id    = module.ec2_sg.id
  iam_instance_profile = "${var.project_name}-ansible-aws-cicd-role"

  custom_tags = {
    Name        = "${var.project_name}-mongodb-server"
    Service     = "mongodb"     # Matches Ansible tag_Service_mongodb
    Project     = "ansible-aws" # Matches your CI/CD filter
    Environment = var.environment
    Region      = "us-east-1"
  }
}
