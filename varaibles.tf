# Okta Configuration
variable "okta_domain" {
  description = "Okta domain URL"
  type        = string
  sensitive   = true
}

variable "okta_client_id" {
  description = "Okta client ID"
  type        = string
  sensitive   = true
}

variable "okta_client_secret" {
  description = "Okta client secret"
  type        = string
  sensitive   = true
}

variable "okta_authorization_level_id" {
  description = "Okta authorization level ID"
  type        = string
  sensitive   = true
}

variable "okta_callback_path" {
  description = "Okta callback path"
  type        = string
  sensitive   = true
}

# FSSA_COMMON Configuration
variable "fssa_common_hostname" {
  description = "FSSA_COMMON database hostname"
  type        = string
  sensitive   = true
}

variable "fssa_common_username" {
  description = "FSSA_COMMON database username"
  type        = string
  sensitive   = true
}

variable "fssa_common_password" {
  description = "FSSA_COMMON database password"
  type        = string
  sensitive   = true
}
variable "nic2_connection_string" {
  description = "value for NIC2 database connection string"
  
}
variable "username" {
 
  type        = string
  sensitive   = true
}

variable "password" {
  
  type        = string
  sensitive   = true
}

variable "connection_string" {
  description = " connection string"
  type        = string
  sensitive   = true
}
variable "required_tags" {
  
}