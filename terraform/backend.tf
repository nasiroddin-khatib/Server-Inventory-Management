terraform {
  backend "s3" {
    bucket = "terraform-state-575458732395-ap-south-1-an"
    key    = "server-inventory/terraform.tfstate"
    region = "ap-south-1"

    encrypt      = true
    use_lockfile = true
  }
}
