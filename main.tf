data "aws_caller_identity" "current" {}

# -------------------------------------------------------------------
# IAM Role for KMS/Secrets Management
# -------------------------------------------------------------------
resource "aws_iam_role" "kms_secrets_admin" {
  name = "KMSSecretsAdminRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = data.aws_caller_identity.current.arn
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_kms_key" "secrets_kms_key" {
  description             = "KMS key for encrypting secrets"
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # 1. Root account full access (break-glass)
      {
        Sid       = "EnableRootPermissions",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*"
      },
      # 2. Admin role permissions (explicitly include PutKeyPolicy)
      {
        Sid       = "AllowAdminAccess",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.kms_secrets_admin.name}"},
        Action    = [
          "kms:PutKeyPolicy",  # Explicitly allow policy updates
          "kms:*"
        ],
        Resource  = "*"
      },
      # 3. Deny all others
      {
        Sid       = "DenyAllExceptRootAndAdmin",
        Effect    = "Deny",
        Principal = "*",
        Action    = "kms:*",
        Resource  = "*",
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = [
              "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:root",
              aws_iam_role.kms_secrets_admin.arn
            ]
          }
        }
      }
    ]
  })
}
# -------------------------------------------------------------------
# Secrets (Connection Strings) with Deny Rules
# -------------------------------------------------------------------
# NIC2 Connection String
resource "aws_secretsmanager_secret" "nic_connection" {
  name        = "NIC_Connection_String"
  kms_key_id  = aws_kms_key.secrets_kms_key.arn
  description = "NIC2 database connection string"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow client full CRUD
      {
        Sid    = "AllowClientCRUD",
        Effect = "Allow",
        Principal = { AWS = "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.kms_secrets_admin.name}"},
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

resource "aws_secretsmanager_secret" "fssa_common" {
  name        = "FSSA_COMMON"
  kms_key_id  = aws_kms_key.secrets_kms_key.arn
  description = "FSSA_COMMON database connection string"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow client full CRUD
      {
        Sid    = "AllowClientCRUD",
        Effect = "Allow",
       Principal = { AWS = "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.kms_secrets_admin.name}"},
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

resource "aws_secretsmanager_secret_version" "fssa_common_value" {
  secret_id     = aws_secretsmanager_secret.fssa_common.id
  secret_string = jsonencode({
    FSSA_COMMON = var.fdr_prod_connection_string
  })
}