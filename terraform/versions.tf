terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-shoplab-dev-zf730"
    storage_account_name = "stshoplabdevtfstate"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    use_oidc             = false
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
