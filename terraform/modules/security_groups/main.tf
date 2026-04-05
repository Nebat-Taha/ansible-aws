# ==============================================================================
# MODULE: Security Group Factory
# ARCHITECTURE: Generic Security Group Container
# DECISION: We define the "Monitoring" rules here, but this module could be 
#           expanded to accept rules as a list/map variable for total reuse.
# ==============================================================================

resource "aws_security_group" "this" {
  name        = var.name
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  # Rule 1: SSH (Standard for all our instances)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = var.name
    Project = var.project_name
  }
}


