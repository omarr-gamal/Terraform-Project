terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-65"
    key    = "environment/${terraform.workspace}/terraform.tfstate"
    region = "us-east-1"
  }
}
