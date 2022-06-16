provider "aws" {
  region = "us-east-1"
  #default_tags { tags = { Terraform = true Owner     = "user@gmail.com" } }
}

resource "random_string" "random" {
  length  = 6
  special = false
  lower   = true
  upper   = false
}
