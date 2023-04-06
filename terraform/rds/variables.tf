// Name
variable "db_name" {
  type        = string
  description = "The name of the RDS instance"
  validation {
    condition     = length(var.db_name) <= 15
    error_message = "Please provide db name with less than 15 chars"
  }
}

// Env specific variables
variable "environment" {
  type        = string
  description = "Environment"
  validation {
    condition = contains(
      ["production", "staging", "systems-production", "load-test"],
      var.environment
    )
    error_message = "Given environment is not valid. Please use one of these values: production, staging, systems-production, load-test"
  }
  default = "staging"
}

variable "region" {
    type = string
    description = "AWS region where the db should be created"
    default = "us-east-1"
}

variable "aws_access_key" {
    type = string
    description = "AWS region where the db should be created"
}

variable "aws_access_key_id" {
    type = string
    description = "AWS region where the db should be created"
}

// DB specific variables
variable "engine_name" {
    type = string
    description = "AWS region where the db should be created"
    default = "mysql"
}

variable "engine_version" {
    type = string
    description = "AWS region where the db should be created"
    default = "8.0"
}

variable "instance_class" {
    type = string
    description = "AWS region where the db should be created"
    default = "db.m6g.12xlarge"
}

variable "multi_AZ" {
    type = bool
    description = "AWS region where the db should be created"
    default = true
}

variable "storage" {
    type = number
    description = "AWS region where the db should be created"
    default = 50
}

variable "username" {
  type        = string
  description = "MySql DB login username"
  validation {
    condition     = length(var.username) > 3
    error_message = "The username cannot be 3 characters or less."
  }
  default = "admin"
}

variable "password" {
  type        = string
  description = "MySql DB login password"
  validation {
    condition     = length(var.password) >= 8
    error_message = "The password cannot be less than 8 characters."
  }
  default = "adminadmin"
}

// Replica specific variables
variable "replica_count" {
  type        = string
  description = "Number of replicas the master db should have"
  default     = "2"
}

variable "replica_instance" {
  type        = string
  description = "Number of replicas the master db should have"
  default     = "db.m6g.2xlarge"
}

variable "replica_multiAZ" {
  type        = bool
  description = "Number of replicas the master db should have"
  default     = false
}
