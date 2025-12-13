# terraform {
#   backend "s3" {
#     region  = "" # Set by Makefile update-state-configs or -backend-config flags
#     bucket  = "" # Set by Makefile update-state-configs or -backend-config flags
#     key     = "global/s3/terraform.tfstate"
#     encrypt = true
#   }
# }
