data "aws_caller_identity" "current" {}

# -------------------------------------------------------------------
# IAM Role for KMS/Secrets Management
# -------------------------------------------------------------------
resource "aws_iam_role" "kms_secrets_admin" {
  name = "KMSSecretsAdminRoleTestEnv"

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
  description             = "KMS key for encrypting secrets for test environment"
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
     
      {
        Sid       = "EnableRootPermissions",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*"
      },
      # 2. Admin role permissions 
      {
        Sid       = "AllowAdminAccess",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.kms_secrets_admin.name}"},
        Action    = ["kms:Decrypt", "kms:DescribeKey"],
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
              "arn:aws-us-gov:iam::${data.aws_caller_identity.current.account_id}:role/*"
            ]
          }
        }
      }
    ]
  })
}


resource "aws_secretsmanager_secret" "Okta_Creds" {
  name        = "Okta_Credentials"
  kms_key_id  = aws_kms_key.secrets_kms_key.arn
  description = "Contains Okta  credentials"
  recovery_window_in_days = 0

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
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

resource "aws_secretsmanager_secret_version" "okta_value" {
  secret_id = aws_secretsmanager_secret.Okta_Creds.id
  secret_string = jsonencode({
    Okta_Credentials = {
      Domain                = var.domain
      ClientId              = var.client_id
      ClientSecret          = var.client_secret
      AuthorizationLevelId  = var.authorization_level_id
      CallbackPath          = var.callback_path
    }
    
  })
}

