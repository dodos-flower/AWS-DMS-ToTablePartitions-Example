terraform {
  backend "s3" {
    bucket         = "terraform-state-${var.nombre_base_app}"
    key            = "dms-project/terraform.tfstate"
    region         = var.region_aws
    dynamodb_table = "terraform-lock-${var.nombre_base_app}"
  }
}
