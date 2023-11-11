provider "aws" {
  region = "eu-west-1"
  default_tags {
    tags = {
      Project   = "nba-play-db"
      Terraform = true
    }
  }
}
