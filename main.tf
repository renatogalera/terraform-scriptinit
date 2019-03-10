module "desafio" {
  source = "terraform/mod/desafio/"
  key_name = "${var.key_name}"
  public_key_path = "${var.public_key_path}"
  ssh-range = "${var.ssh-range}"
  aws_region = "${var.aws_region}"
  ami = "${var.ami}"
  instance_name = "${var.instance_name}"
 
}

output "public_ip" {
  value = "${module.desafio.public_ip}"
} 

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
