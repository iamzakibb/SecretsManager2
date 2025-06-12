variable "fdr_prod_connection_string" {
  description = "value for FDR database connection string"
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