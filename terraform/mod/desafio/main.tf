provider "aws" {
    region = "${var.aws_region}"
  }

 resource "aws_instance" "idwall" {
  ami                    = "${var.ami}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.idwall.id}"]
  key_name               = "${var.key_name}"

provisioner "file" {
    source      = "./conf/docker"
    destination = "/tmp"
        connection {
          type = "ssh"
          user = "centos"
      }

  }

provisioner "file" {
    source      = "./conf/conf-install.sh"
    destination = "/tmp/conf-install.sh"
        connection {
          type = "ssh"
          user = "centos"
      }

  }

provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/conf-install.sh",
      "sudo /tmp/conf-install.sh args",
    ]
    connection {
          type = "ssh"
          user = "centos"
      }
}
  
    tags {
      Name = "${var.instance_name}"
    }
  }
  
  resource "aws_security_group" "idwall" {
    name = "${var.instance_name}"
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["${var.ssh-range}"]
  }

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

}

# 
