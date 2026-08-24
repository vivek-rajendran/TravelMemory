variable "aws_region" {
  type        = string
  default     = "ap-south-1" # <-- 1. AWS REGION
  description = "AWS region"
}

variable "my_ip" {
  type        = string
  default     = "49.206.114.2/32" # <-- 2. AWS PUBLIC IP
  description = "Developer public IP with CIDR notation"
}

variable "key_name" {
  type        = string
  default     = "travelmemory-key" # <-- 3. AWS SSH KEY NAME
  description = "AWS Key Pair Name"
}

variable "ami_id" {
  type        = string
  default     = "" # <-- LEAVE BLANK (Dynamic lookup handles this)
  description = "Optional AMI ID override"
}