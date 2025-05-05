terraform {
  backend "s3" {
    bucket = "okhatavkar-backup-restore-terraform-state"
    key    = "rancher/infrastructure.tfstate"
    region = "us-east-2"
  }
}