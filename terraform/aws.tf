provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Terraform = true
      Owner     = "user@gmail.com"
    }
  }
}

resource "random_string" "random" {
  length           = 4
  special          = false
}
