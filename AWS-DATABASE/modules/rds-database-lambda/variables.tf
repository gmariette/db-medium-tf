variable "env" {}
variable "project" {}
variable "region" {}
variable "storage_encrypted" {}
variable "multi_az" {}
variable "database_master_password" {}
variable "database_master_user" {}
variable "database_user" {}
variable "database_password" {}

data "aws_availability_zones" "available" {
    state = "available"

    filter {
        name   = "region-name"
        values = ["${var.region}"]
  }
    filter {
        name = "state"
        values = ["available"]
    }
}

data "aws_vpc" "selected" {
    state = "available"
    filter {
        name   = "tag:Name"
        values = ["${var.project}-${var.env}-vpc"]
  }
}

data "aws_subnet_ids" "db_subnets_id" {
  vpc_id = "${data.aws_vpc.selected.id}"
  tags = {
    Name = "${var.project}-${var.env}-vpc-db-*"
  }
}

data "aws_subnet_ids" "public_subnets_id" {
  vpc_id = "${data.aws_vpc.selected.id}"
  tags = {
    Name = "${var.project}-${var.env}-vpc-public-*"
  }
}

data "aws_subnet_ids" "intra_subnets_id" {
  vpc_id = "${data.aws_vpc.selected.id}"
  tags = {
    Name = "${var.project}-${var.env}-vpc-intra-*"
  }
}

data "aws_subnet" "db_subnets_cidr" {
  for_each = toset(data.aws_subnet_ids.db_subnets_id.ids)
  id       = each.value
}

locals {
  cidr_blocks = [
    for subnet in data.aws_subnet.db_subnets_cidr :
      subnet.cidr_block
    ]

  cidr_blocks_rendered = [
    for cidr_block in local.cidr_blocks :
     {
        from_port   = 5432,
        to_port     = 5432,
        protocol    = "tcp",
        description = "PostgreSQL access from within VPC"
        cidr_blocks = cidr_block
     }
  ]
}

data "aws_iam_role" "basic_lambda" {
  name = "${var.project}-${var.env}-iam-role-lambda-trigger"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/source-code"
  output_path = "lambda.zip"
}