variable "key_name" {
  description = "The EC2 Key Pair."
  default     = "my-key"
}

variable "public_key_path" {
  description = "Endereço da public-key"
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh-range" {
  description = "Allow IP SSH"
  default = "200.204.0.10/32"
}

variable "aws_region" {
  description = "Região AWS Padrão."
  default = "us-east-1"
}

variable "ami" {
  description = "Centos7"
  default = "ami-02eac2c0129f6376b"
}

variable "instance_name" {
  description = "Nome da intância."
  default     = "idwall"
}
