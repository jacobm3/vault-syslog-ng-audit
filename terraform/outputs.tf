output "vault_public_ip" {
  value = aws_instance.vault.public_ip
}

output "vault_instance_id" {
  value = aws_instance.vault.id
}

output "syslog_public_ip" {
  value = aws_instance.syslog.public_ip
}

output "syslog_instance_id" {
  value = aws_instance.syslog.id
}
