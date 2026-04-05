terraform {
  backend "s3" {
    bucket         = "nebatn" # Replace with your bucket name
    key            = "ansible-terraform-state/global/terraform.tfstate"
    region         = "us-east-1" # Replace with your preferred region
    encrypt        = true
    dynamodb_table = "terraform-state-locking"

  }
}
