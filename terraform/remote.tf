terraform {
  backend "s3" {
    bucket = "jm3-state"
    key    = "vault-syslog-ng-audit.tfstate"
    region = "us-east-1"
    #dynamodb_table  = "jm3-state"
  }
}
