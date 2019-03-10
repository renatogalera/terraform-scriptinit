output "public_ip" {
  value = "${aws_instance.idwall.public_ip}"
}