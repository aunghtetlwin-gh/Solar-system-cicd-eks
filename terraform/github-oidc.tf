# 1. Requests a GitHub OIDC token.
# 2. Sends it to AWS STS.
# 3. AWS validates the audience.
# 4. AWS validates repository and branch.
# 5. AWS allows the deployment role to be assumed.
# 6. AWS returns temporary credentials.
# 7. Later AWS CLI and kubectl commands use those credentials.

# ## Resources Created

# The file creates five AWS resources:

# aws_iam_openid_connect_provider.github_actions
# aws_iam_role.github_actions_eks_deploy
# aws_iam_role_policy.github_actions_eks_describe
# aws_eks_access_entry.github_actions
# aws_eks_access_policy_association.github_actions_cluster_admin

# It also reads one data source:

# data.tls_certificate.github_actions

# ## Why OIDC Is Better Than AWS Keys

# Without OIDC, you might store these in GitHub:

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# Those credentials are long-lived and must be rotated manually.

# With OIDC:

# - no permanent AWS keys in GitHub
# - temporary credentials per workflow run
# - credentials expire automatically
# - trust is restricted to your repository
# - trust is restricted to main
# - the role can be revoked centrally in AWS

# That is why OIDC is the preferred CI/CD authentication method.

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com" #GitHub’s OIDC endpoint and reads its TLS certificate information.
}

##  Register GitHub As An AWS Identity Provider(Create IAM OIDC provider in AWS for GitHub Actions, allowing GitHub to authenticate with AWS using OIDC tokens)
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

# This prevents:

# - another GitHub repository from assuming the role
# - another GitHub user from using the role
# - a feature branch from deploying
# - a pull request workflow from deploying
# - a fork from deploying

# This is one of the most important security restrictions.

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

# eks:DescribeCluster  (EKS API endpoint / cluster certificate /cluster metadata) 
resource "aws_iam_role_policy" "github_actions_eks_describe" {
  name = "${var.cluster_name}-describe"
  role = aws_iam_role.github_actions_eks_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster" #
        ]
        Resource = aws_eks_cluster.main.arn
      }
    ]
  })
}

## Register The Role With EKS 
##(This creates an EKS access entry for the GitHub Actions role, allowing it to be associated with EKS access policies. 
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.github_actions_eks_deploy.arn
  type          = "STANDARD" ##Without this, GitHub might successfully authenticate to AWS but receive a Kubernetes error(Unauthorized or Forbidden).

  tags = {
    Name = "${var.cluster_name}-github-actions-access"
  }
}

resource "aws_eks_access_policy_association" "github_actions_cluster_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.github_actions_eks_deploy.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_actions]
}

