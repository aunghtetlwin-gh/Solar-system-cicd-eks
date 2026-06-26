# Reads GitHub Actions OIDC TLS certificate for IAM provider trust.
data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

# Registers GitHub Actions as an OIDC identity provider in AWS.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.github_actions.certificates[0].sha1_fingerprint
  ]

  tags = {
    Name = "${var.project_name}-github-actions-oidc"
  }
}

# Creates the IAM role GitHub Actions can assume from the allowed repo and branch.
resource "aws_iam_role" "github_actions_eks_deploy" {
  name = "${var.cluster_name}-github-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:ref:refs/heads/${var.github_deploy_branch}"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-github-deploy-role"
  }
}

# Allows the GitHub Actions role to read EKS cluster connection details.
resource "aws_iam_role_policy" "github_actions_eks_describe" {
  name = "${var.cluster_name}-describe"
  role = aws_iam_role.github_actions_eks_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = var.cluster_arn
      }
    ]
  })
}

# Registers the GitHub Actions IAM role as an EKS cluster principal.
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.github_actions_eks_deploy.arn
  type          = "STANDARD"

  tags = {
    Name = "${var.cluster_name}-github-actions-access"
  }
}

# Grants the GitHub Actions IAM role cluster-admin access in EKS.
resource "aws_eks_access_policy_association" "github_actions_cluster_admin" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.github_actions_eks_deploy.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_actions]
}
