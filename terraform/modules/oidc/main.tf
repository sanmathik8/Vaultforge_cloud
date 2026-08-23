variable "github_repo" { type = string }

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = distinct([
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a21f81e57653b4247502c91cf8e9ed3ffc34",
    data.tls_certificate.github.certificates[0].sha1_fingerprint
  ])
}

# Role for the CI workflow (push to ECR only)
resource "aws_iam_role" "ecr_push" {
  name = "vault-forge-ci-ecr-push"
  tags = { Project = "VaultForge", ManagedBy = "Terraform" }
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:sanmathik8@180301003/Vaultforge_cloud@1319752793:*",
            "repo:sanmathik8@180301003/VaultForge_cloud@1319752793:*"
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "ecr_push" {
  name = "ecr-push"
  role = aws_iam_role.ecr_push.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages",
        "tag:GetResources"
      ]
      Resource = "*"
    }]
  })
}

# Role for the CD workflow (deploy to ECS Fargate)
resource "aws_iam_role" "eks_deploy" {
  name = "vault-forge-cd-ecs-deploy"
  tags = { Project = "VaultForge", ManagedBy = "Terraform" }
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:sanmathik8@180301003/Vaultforge_cloud@1319752793:*",
            "repo:sanmathik8@180301003/VaultForge_cloud@1319752793:*"
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "eks_deploy" {
  name = "ecs-deploy"
  role = aws_iam_role.eks_deploy.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:ListServices",
          "ecs:ListClusters",
          "elbv2:DescribeLoadBalancers",
          "elbv2:DescribeTargetGroups",
          "tag:GetResources"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [
          "arn:aws:iam::*:role/vault-forge-ecs-execution-role",
          "arn:aws:iam::*:role/vault-forge-ecs-task-role"
        ]
      }
    ]
  })
}

# Role for Terraform IaC Bootstrap workflow (infra-bootstrap.yml)
resource "aws_iam_role" "terraform_bootstrap" {
  name = "vault-forge-terraform-bootstrap"
  tags = { Project = "VaultForge", ManagedBy = "Terraform" }
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:sanmathik8@180301003/Vaultforge_cloud@1319752793:*",
            "repo:sanmathik8@180301003/VaultForge_cloud@1319752793:*"
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "terraform_bootstrap" {
  name = "terraform-bootstrap"
  role = aws_iam_role.terraform_bootstrap.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:*", "dynamodb:*", "ecr:*", "ecs:*", "iam:*", "ec2:*", "elasticloadbalancing:*", "cloudwatch:*", "logs:*", "application-autoscaling:*", "tag:GetResources"]
      Resource = "*"
    }]
  })
}

output "ecr_push_role_arn" { value = aws_iam_role.ecr_push.arn }
output "eks_deploy_role_arn" { value = aws_iam_role.eks_deploy.arn }
output "terraform_role_arn" { value = aws_iam_role.terraform_bootstrap.arn }
