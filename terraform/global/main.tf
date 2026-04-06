# 1. Attach the permissions to your MANUAL role
resource "aws_iam_role_policy" "cicd_manual_policy" {
  name = "ansible-aws-cicd-permissions"
  role = "ansible-aws-cicd-role" # Points to your manual role

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:DescribeInstances", "ec2:DescribeTags"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "ec2-instance-connect:SendSSHPublicKey"
        Resource = "*"
        Condition = {
          StringEquals = { "ec2:osuser" = "ubuntu" }
        }
      }
    ]
  })
}

# 2. Create the Instance Profile (The "Bridge")
resource "aws_iam_instance_profile" "cicd_profile" {
  name = "ansible-aws-cicd-role"
  role = "ansible-aws-cicd-role"
}
