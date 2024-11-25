variable "usuario_aws" {}
variable "region_aws" {}
variable "vpc_id" {}
variable "subnets_ids" {
  type = list(string)
}
variable "nombre_base_app" {}
variable "role_deploy" {}
variable "database_name" {}
variable "database_port" {}
variable "database_host" {}
variable "database_user" {}
variable "database_user_pass" {}
