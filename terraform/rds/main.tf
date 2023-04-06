terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  
  backend "s3" {
    bucket = "terraform"
    key    = "rds-state/"
    region = var.region 
  }
  
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region 
  access_key = var.aws_access_key
  secret_key = var.aws_access_key_id
}

data "aws_vpcs" "vpc" {
  tags = {
    Environment = var.environment
  }
}

data "aws_vpc" "selected_vpc" {
  id = data.aws_vpcs.vpc.ids[0]
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = data.aws_vpcs.vpc.ids
  }

  tags = {
    Environment = var.environment
    Type = "private"
  }
}

data "aws_security_group" "vpc_ssh_sg" {
  tags = {
    Purpose = "vpc-ssh"
  }
  vpc_id = data.aws_vpcs.vpc.ids[0]

}

// Create RDS security Group
resource "aws_security_group" "rds-sg" {
  name        = "${var.db_name}-rds-sg"
  description = "Allow RDS inbound traffic"
  vpc_id      = data.aws_vpcs.vpc.ids[0]
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

// create parameter group
resource "aws_db_parameter_group" "mysql_pg" {
  name   = "${var.db_name}-db-param-group"
  family = "${var.engine_name}${var.engine_version}"
}

// create option group
resource "aws_db_option_group" "mysql_og" {
  name                     = "${var.db_name}-db-option-group"
  option_group_description = "Custom DB Option Group"
  engine_name              = var.engine_name
  major_engine_version     = var.engine_version
}


resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = data.aws_subnets.private_subnets.ids

  tags = {
    Name = "DB subnet group"
  }
}

resource "aws_db_instance" "mysql_db_instance" {
  identifier                   = "${var.db_name}-db"
  db_subnet_group_name         = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids       = [data.aws_security_group.vpc-ssh-sg.id, aws_security_group.rds-sg.id]
  engine                       = var.engine_name
  engine_version               = var.engine_version
  option_group_name            = aws_db_option_group.mysql_og.name
  parameter_group_name         = aws_db_parameter_group.mysql_pg.name
  deletion_protection          = true
  instance_class               = var.instance_class
  username                     = var.username
  password                     = var.password
  multi_az                     = var.multi_AZ
  storage_encrypted            = true
  storage_type                 = "gp3"
  allocated_storage            = var.storage
  max_allocated_storage        = 100
  performance_insights_enabled = true
  skip_final_snapshot          = true
  auto_minor_version_upgrade   = false
  apply_immediately            = true
  backup_retention_period      = 7
  copy_tags_to_snapshot        = true
  backup_window                = "01:00-03:00"

  tags = {
    Name        = var.db_name,
    Environment = var.environment,
    Purpose     = "RDS-Mysql",
    Engine = var.engine_name,
    EngineVersion = var.engine_version
  }
}

// create replica
resource "aws_db_instance" "replica" {
  count                      = var.replica_count
  identifier                 = "${var.db_name}-db-replica-${count.index}"
  instance_class             = var.replica_instance
  skip_final_snapshot        = true
  auto_minor_version_upgrade = false
  backup_retention_period    = 0
  multi_az                   = var.replica_multiAZ
  replicate_source_db        = aws_db_instance.mysql_db_instance.identifier
  storage_encrypted          = true
  max_allocated_storage      = 100
}


// create cw alarm
