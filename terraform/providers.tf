terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  alias  = "europe"
  region = var.europe.region
}

provider "aws" {
  alias  = "us_east"
  region = var.us_east.region
}
