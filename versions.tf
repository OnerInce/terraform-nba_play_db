terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.55.0"
    }
  }

  backend "s3" {
    bucket = "tf-state-nbaplaydb"
    key    = "terraform"
    region = "eu-west-1"
  }
}
