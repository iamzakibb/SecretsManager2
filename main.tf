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




resource "aws_secretsmanager_secret" "fssa_common" {
  name        = "FSSA_COMMON"
  kms_key_id  = aws_kms_key.secrets_kms_key.arn
  description = "Contains FSSA_COMMON credentials"

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

resource "aws_secretsmanager_secret_version" "fssa_common_value" {
  secret_id = aws_secretsmanager_secret.fssa_common.id
  secret_string = jsonencode({
    
    FSSA_COMMON = {
      HostName = var.fssa_common_hostname
      UserName = var.fssa_common_username
      Password = var.fssa_common_password
    }
  })
}


resource "aws_secretsmanager_secret" "okta" {
  name        = "Okta_Credentials"
  kms_key_id  = aws_kms_key.secrets_kms_key.arn
  description = "Contains Okta  credentials"

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
  secret_id = aws_secretsmanager_secret.okta.id
  secret_string = jsonencode({
    Okta = {
      Domain                = var.okta_domain
      ClientId              = var.okta_client_id
      ClientSecret          = var.okta_client_secret
      AuthorizationLevelId  = var.okta_authorization_level_id
      CallbackPath          = var.okta_callback_path
    }
    
  })
}

