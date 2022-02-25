provider "aws" {
  region = var.region
}

# EC2 Bastion host
module "bastion_host_sgroup" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4"

  name        = "${var.env}-${var.project}-bastion-sg"
  description = "Bastion Host security group"
  vpc_id      = "${data.aws_vpc.selected.id}"

  # ingress
  ingress_with_cidr_blocks  = [
    {
        from_port   = 22,
        to_port     = 22,
        protocol    = "tcp",
        description = "Allow my IP"
        cidr_blocks = "99.238.227.251/32"
     }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "${var.project}-${var.env}-bastion"

  ami                    = "ami-0cd73cc497a2d6e69"
  instance_type          = "t2.micro"
  key_name               = "gma-keypair"
  monitoring             = false
  subnet_id              = sort(tolist(data.aws_subnet_ids.public_subnets_id.ids))[0]
  vpc_security_group_ids = ["${module.bastion_host_sgroup.security_group_id}"]
}

module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4"

  name        = "${var.env}-${var.project}-pg"
  description = "PostgreSQL security group"
  vpc_id      = "${data.aws_vpc.selected.id}"

  # ingress
  ingress_with_cidr_blocks = local.cidr_blocks_rendered
  ingress_with_source_security_group_id = [
    {
      from_port         = 5432
      to_port           = 5432
      protocol          = "-1"
      description       = "Allow bastion host"
      source_security_group_id = "${module.bastion_host_group.security_group_id}"
    }
  ]
}

################################################################################
# RDS
################################################################################

resource "aws_db_instance" "medium-pg" {
  allocated_storage        = 20 # gigabytes
  backup_retention_period  = 0   # in days
  engine                   = "postgres"
  db_subnet_group_name     = "${var.project}-${var.env}-vpc"
  engine_version           = "12.9"
  identifier               = "${var.project}-${var.env}-pg"
  instance_class           = "db.t2.micro"
  multi_az                 = "${var.multi_az}"
  name                     = "${var.project}${var.env}"
  password                 = "${var.database_master_password}"
  port                     = 5432
  publicly_accessible      = false
  storage_encrypted        = "${var.storage_encrypted}"
  storage_type             = "gp2"
  username                 = "${var.database_master_user}"
  vpc_security_group_ids   = ["${module.rds_security_group.security_group_id}"]
  skip_final_snapshot      = true
}

module "lambda_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4"

  name        = "${var.env}-${var.project}-lambda-pg"
  description = "Lambda PG init security group"
  vpc_id      = "${data.aws_vpc.selected.id}"
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_security_group_rule" "lambda_rds" {
  type                      = "ingress"
  from_port                 = 5432
  to_port                   = 5432
  protocol                  = "tcp"
  security_group_id         = module.rds_security_group.security_group_id
  source_security_group_id  = module.lambda_security_group.security_group_id
}

resource "aws_lambda_function" "lambda_init_db" {
  code_signing_config_arn = ""
  description             = "Lambda function to init medium DB"
  filename                = data.archive_file.lambda.output_path
  function_name           = "${var.project}-initdb-function"
  role                    = data.aws_iam_role.basic_lambda.arn
  handler                 = "initdb.lambda_handler"
  runtime                 = "python3.8"
  source_code_hash        = filebase64sha256(data.archive_file.lambda.output_path)
  timeout                 = 180

  vpc_config {
    subnet_ids         = data.aws_subnet_ids.intra_subnets_id.ids
    security_group_ids = [module.lambda_security_group.security_group_id]
  }
  environment {
    variables = {
      APP_DB_USER = "${var.database_user}"
      APP_DB_PASS = "${var.database_password}"
      APP_DB_NAME = "medium"
      DB_HOST = aws_db_instance.medium-pg.address
      DB_NAME = aws_db_instance.medium-pg.name
      ENV = "${var.env}"
      PROJECT = "${var.project}"
    }
  }
}

data "aws_lambda_invocation" "init_db" {
  function_name = aws_lambda_function.lambda_init_db.function_name

  input = <<JSON
{
  "key": "dummy"
}
JSON
}