output "elastic_ip" {
  value = aws_eip.wikijs.public_ip
}
