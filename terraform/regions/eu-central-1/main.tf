# terraform/regions/eu-central-1/main.tf

module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  # Using a different CIDR range to avoid overlap
  vpc_cidr           = "10.1.0.0/16"
  public_subnet_cidr = "10.1.1.0/24"
}

module "ec2_sg" {
  source       = "../../modules/security_groups"
  name         = "${var.project_name}-redis-sg"
  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  vpc_cidr     = module.vpc.vpc_cidr
}



module "ec2_redis" {
  source               = "../../modules/ec2"
  project_name         = var.project_name
  instance_type        = "t2.micro"
  public_subnet_id     = module.vpc.public_subnet_id
  security_group_id    = module.ec2_sg.id
  iam_instance_profile = "${var.project_name}-ansible-aws-cicd-role"

  custom_tags = {
    Name        = "${var.project_name}-redis-server"
    Service     = "redis"             # Matches Ansible tag_Service_redis
    Project     = "monitoring-system" # Matches your CI/CD filter
    Environment = var.environment
    Region      = "eu-central-1"
  }
}
