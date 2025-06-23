terraform {
  backend "s3" {
    bucket = "test-dev-storage"
    key    = "dev/terraform.tfstate"
    region = "ap-south-1"
  }
}

