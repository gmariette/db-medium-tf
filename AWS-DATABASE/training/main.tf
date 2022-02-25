provider "aws" {
  region = var.region

  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = {
      Environment = var.env
      Owner       = var.owner
      Terraform   = "true"
    }
  }
}

terraform {  
  backend "s3" {    
    bucket = "training-medium-db-tf-state"   
    key    = "dev/tfstate.tf" 
    region = "ca-central-1"   
    }
}

locals {
    vpc_name = "${var.env}-vpc"
}

module "rds-database-lambda" {
  source = "../modules/rds-database-lambda"
  env = "${var.env}"
  project = "${var.project}"
  region = "${var.region}"
  storage_encrypted = "${var.storage_encrypted}"
  multi_az = "${var.multi_az}"
  database_master_user = "${var.database_master_user}"
  database_master_password = "${var.database_master_password}"
  database_user = "${var.database_user}"
  database_password = "${var.database_password}"
}

module "parameter-store" {
  source = "../modules/parameter-store"
  env = "${var.env}"
  project = "${var.project}"
  database_master_user = "${var.database_master_user}"
  database_master_password = "${var.database_master_password}"
  database_user = "${var.database_user}"
  database_password = "${var.database_password}"
}