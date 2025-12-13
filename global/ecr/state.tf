terraform {
  backend "s3" {
    region  = "" # Set by Makefile update-state-configs or -backend-config flags
    bucket  = "" # Set by Makefile update-state-configs or -backend-config flags
    key     = "global/ecr/terraform.tfstate"
    encrypt = true
  }
}
