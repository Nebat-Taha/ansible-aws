#  --- IDENTITY (IAM) ---
# Defines what the Monitoring Server can do in the AWS API.
module "iam_aws" {
  source       = "../modules/iam"
  project_name = var.project_name
  role_name    = "${var.project_name}-ansible-aws-cicd-role"

  # We combine the SQS permissions with the Instance Connect permission here.
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permission 1: Monitoring Data (SQS/CloudWatch)
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",

        ]
        Effect   = "Allow"
        Resource = "*"
      },
      # Permission 2: Keyless SSH Access (EC2 Instance Connect)
      {
        Effect   = "Allow"
        Action   = "ec2-instance-connect:SendSSHPublicKey"
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:osuser" = "ubuntu"
          }
        }
      }
    ]
  })
}
