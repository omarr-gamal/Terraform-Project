terraform {
  backend "s3" {
    bucket = "terraform-project-state-bucket"
    key    = "environment/${terraform.workspace}/terraform.tfstate"
    region = "us-east-1"
  }
}
