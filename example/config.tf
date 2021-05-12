terraform {
  required_version = ">= 0.15.0"

  backend "s3" {
    bucket = "gd-wireguard-demo-setup" # TODO: remove gd prefix and randomize name to avoid conflicts since buckets should be globally unique
    key    = "example"
    region = "eu-central-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.37.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    wireguard = {
      source  = "OJFord/wireguard"
      version = "0.1.3"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "wireguard" {}