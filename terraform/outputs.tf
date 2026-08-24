output "web_server_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of Web Server"
}

output "db_server_private_ip" {
  value       = aws_instance.db.private_ip
  description = "Private IP of MongoDB Server"
}