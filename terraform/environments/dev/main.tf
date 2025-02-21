terraform {
  required_version = ">= 1.0.0"
  
  backend "s3" {
    bucket = "microservices-tfstate-dev"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
  
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "microservices-platform"
      ManagedBy   = "terraform"
    }
  }
}

# EKSクラスタモジュールの呼び出し
module "eks" {
  source = "../../modules/eks"
  
  environment = "dev"
  cluster_name = "microservices-dev"
  # その他の設定は必要に応じて追加
} 