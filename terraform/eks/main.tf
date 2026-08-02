# ==================================================
# EKS CLUSTER IAM ROLE
# The role the EKS control plane itself assumes
# ==================================================

resource "aws_iam_role" "eks_cluster" {
  name = "${var.eks_cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.eks_cluster_name}-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ==================================================
# LOGGING
# CloudWatch log group for EKS control plane logs
# ==================================================

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = 30

  tags = {
    Name = "${var.eks_cluster_name}-cluster-logs"
  }
}

# ==================================================
# EKS CLUSTER
# The control plane itself
# ==================================================

resource "aws_eks_cluster" "this" {
  name                      = var.eks_cluster_name
  role_arn                  = aws_iam_role.eks_cluster.arn
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.public_access_cidrs
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks_cluster
  ]
}

# ==================================================
# CLUSTER ACCESS ENTRIES
# Grants an IAM principal admin access via EKS access API
# (in place of the old aws-auth configmap approach)
# ==================================================

resource "aws_eks_access_entry" "admin_access" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.cluster_admin_iam_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_access" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.cluster_admin_iam_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.admin_access
  ]
}

# ==================================================
# ARGO CD CLUSTER ACCESS
# Allows Argo CD to deploy and manage cluster-wide resources
# ==================================================

resource "aws_eks_access_policy_association" "argocd_cluster_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_iam_role.argocd_capability.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_capability.argocd
  ]
}

# ==================================================
# VPC CNI - POD IDENTITY
# IAM role assumed by the vpc-cni addon via EKS Pod
# Identity (replaces IRSA for this addon)
# ==================================================

resource "aws_iam_role" "vpc_cni_pod_identity" {
  name = "${var.eks_cluster_name}-vpc-cni-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.eks_cluster_name}-vpc-cni-role"
  }
}

resource "aws_iam_role_policy_attachment" "vpc_cni_pod_identity" {
  role       = aws_iam_role.vpc_cni_pod_identity.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "eks-pod-identity-agent"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_pod_identity_association" "vpc_cni" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "aws-node"
  role_arn        = aws_iam_role.vpc_cni_pod_identity.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.vpc_cni_pod_identity
  ]
}

# ==================================================
# AWS LOAD BALANCER CONTROLLER - POD IDENTITY
# ==================================================

resource "aws_iam_role" "load_balancer_controller" {
  name = "${var.eks_cluster_name}-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.eks_cluster_name}-load-balancer-controller-role"
  }
}

resource "aws_iam_policy" "load_balancer_controller" {
  name = "${var.eks_cluster_name}-load-balancer-controller-policy"

  policy = file(
    "${path.module}/policies/aws-load-balancer-controller-policy.json"
  )
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller" {
  role       = aws_iam_role.load_balancer_controller.name
  policy_arn = aws_iam_policy.load_balancer_controller.arn
}

resource "aws_eks_pod_identity_association" "load_balancer_controller" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.load_balancer_controller.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.load_balancer_controller
  ]
}

# ==================================================
# EKS WORKER NODE IAM ROLE
# EC2 worker nodes assume this role
# ==================================================

resource "aws_iam_role" "eks_nodes" {
  name = "${var.eks_cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.eks_cluster_name}-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_pull_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# ==================================================
# EKS NODE GROUP
# Managed node group backed by the worker role above
# ==================================================

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.eks_cluster_name}-node-group"

  node_role_arn = aws_iam_role.eks_nodes.arn
  subnet_ids    = var.subnet_ids

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    min_size     = 2
    max_size     = 4
    desired_size = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.ecr_pull_policy,
    aws_eks_pod_identity_association.vpc_cni
  ]

  tags = {
    Name = "${var.eks_cluster_name}-node-group"
  }
}

# ==================================================
# ARGO CD CAPABILITY - IAM ROLE
# Role assumed by the AWS-managed Argo CD capability
# (runs outside the cluster; not a pod, not IRSA/Pod Identity)
# ==================================================

resource "aws_iam_role" "argocd_capability" {
  name = "${var.eks_cluster_name}-argocd-capability-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.eks_cluster_name}-argocd-capability-role"
  }
}

# ==================================================
# ARGO CD CAPABILITY
# Fully AWS-managed Argo CD (runs outside your cluster,
# AWS handles upgrades/scaling). Requires AWS Identity
# Center already set up - local users aren't supported.
# ==================================================

resource "aws_eks_capability" "argocd" {
  cluster_name              = aws_eks_cluster.this.name
  capability_name           = "${var.eks_cluster_name}-argocd"
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.argocd_capability.arn
  delete_propagation_policy = "RETAIN"

  configuration {
    argo_cd {
      namespace = "argocd"

      aws_idc {
        idc_instance_arn = "arn:aws:sso:::instance/ssoins-6804b115f102656f"
        idc_region       = "eu-west-1"
      }

      rbac_role_mapping {
        role = "ADMIN"

        identity {
          id   = "c2c52424-5051-70d1-c35e-26cdd8cce530"
          type = "SSO_USER"
        }
      }
    }
  }

  depends_on = [
    aws_iam_role.argocd_capability
  ]

  tags = {
    Name = "${var.eks_cluster_name}-argocd"
  }
}
