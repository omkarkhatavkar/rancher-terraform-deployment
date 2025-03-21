# AWS provider configuration
provider "aws" {
  alias  = "instance"
  region = var.aws_region_instance
}

provider "aws" {
  alias  = "s3"
  region = var.aws_region_s3
}
