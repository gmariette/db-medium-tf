variable "env" {
    description = "Current environment"
    type = string
    default = "training"
}

variable "owner" {
    description = "Stack owner"
    type = string
    default = "owner"
}

variable "allowed_account_ids" {
    description = "AWS account ids"
    type = list(string)
    default = [ "123456789012" ]
}

variable "project" {
    description = "Project"
    type = string
    default = "medium"  
}

variable "region" {
    description = "A list of availability zones in the region"
    type        = string
    default     = "ca-central-1"
}

variable "storage_encrypted" {
    description = "Storage encryption"
    type = bool
    default = false
}

variable "multi_az" {
    description = "Multi AZ mode for db"
    type = bool
    default = false
}

variable "database_master_user" {
    description = "Db master user"
    type        = string
    default     = "root"
}

variable "database_master_password" {
    description = "Db master password"
    type        = string
    default     = "MyAweSomePassWord"
}

variable "database_user" {
    description = "Db user"
    type        = string
    default     = "medium"
}

variable "database_password" {
    description = "Db password"
    type        = string
    default     = "MyP@ssw0rdIsNotSecureAtAll"
}