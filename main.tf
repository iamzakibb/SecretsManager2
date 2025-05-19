data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  current_user_arn = data.aws_caller_identity.current.arn
}

resource "aws_kms_key" "secrets_kms_key" {
  description             = "KMS key for encrypting secrets"
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Root account full access
      {
        Sid       = "EnableRootPermissions",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*"
      },
      
      {
        Sid       = "Allow  CRUD",
        Effect    = "Allow",
        Principal = { AWS = data.aws_caller_identity.current.arn }, 
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource  = "*"
      },
      {
      Sid       = "AllowDMSDecryptAccess",
      Effect    = "Allow",
      Principal ={ AWS = data.aws_caller_identity.current.arn },
      Action    = ["kms:Decrypt", "kms:DescribeKey"],
      Resource  = "*"
    },
    
      # Security boundary
      {
        Sid       = "DenyExternalAccess",
        Effect    = "Deny",
        Principal = "*",
        Action    = "kms:*",
        Resource  = "*",
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = [
              "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:root",
              data.aws_caller_identity.current.arn  # Deny everyone except root and  current user
            ]
          }
        }
      }
    ]
  })
}

# -------------------------------------------------------------------
# Secrets (Connection Strings)
# -------------------------------------------------------------------
# NIC2 Connection String
resource "aws_secretsmanager_secret" "nic_connection" {
  name        = "NIC_Connection_String"
  kms_key_id  = aws_kms_key.secrets_kms_key.arn
  description = "NIC2 database connection string"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow    full CRUD
      {
        Sid    = "Allow  CRUD",
        Effect = "Allow",
        Principal = { AWS = data.aws_caller_identity.current.arn },
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_secretsmanager_secret_version" "nic_connection_value" {
  secret_id     = aws_secretsmanager_secret.nic_connection.id
  secret_string = jsonencode({
    NIC2 = var.nic2_connection_string
  })
}

# FDR_PROD Connection String
resource "aws_secretsmanager_secret" "fdr_prod" {
  name        = "FDR"
  kms_key_id  = aws_kms_key.secrets_kms_key.arn
  description = "FDR database connection string"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow    full CRUD
      {
        Sid    = "Allow  CRUD",
        Effect = "Allow",
        Principal = { AWS = data.aws_caller_identity.current.arn },
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_secretsmanager_secret_version" "fdr_prod_value" {
  secret_id     = aws_secretsmanager_secret.fdr_prod.id
  secret_string = jsonencode({
    FDR_PROD = var.fdr_prod_connection_string
  })
}