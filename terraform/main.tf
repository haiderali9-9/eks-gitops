module "europe_vpc" {
  source = "./vpc"

  providers = {
    aws = aws.europe
  }

  vpc_name         = var.europe.vpc_name
  vpc_cidr         = var.europe.vpc_cidr
  public_subnets   = var.europe.public_subnets
  private_subnets  = var.europe.private_subnets
  azs              = var.europe.availability_zones
  eks_cluster_name = var.europe.eks_cluster_name
}

module "us_east_vpc" {
  source = "./vpc"

  providers = {
    aws = aws.us_east
  }

  vpc_name         = var.us_east.vpc_name
  vpc_cidr         = var.us_east.vpc_cidr
  public_subnets   = var.us_east.public_subnets
  private_subnets  = var.us_east.private_subnets
  azs              = var.us_east.availability_zones
  eks_cluster_name = var.us_east.eks_cluster_name
}

module "europe_eks" {
  source = "./eks"

  providers = {
    aws = aws.europe
  }

  eks_cluster_name      = var.europe.eks_cluster_name
  subnet_ids            = module.europe_vpc.private_subnet_ids
  cluster_admin_iam_arn = var.europe.cluster_admin_iam_arn
}

module "us_east_eks" {
  source = "./eks"

  providers = {
    aws = aws.us_east
  }

  eks_cluster_name      = var.us_east.eks_cluster_name
  subnet_ids            = module.us_east_vpc.private_subnet_ids
  cluster_admin_iam_arn = var.us_east.cluster_admin_iam_arn
}
