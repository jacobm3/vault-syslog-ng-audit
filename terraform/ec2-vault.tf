locals {
  vault_name = "${var.vault_hostname}-${random_string.random.result}"
}

resource "aws_instance" "vault" {
  ami = data.aws_ami.latest-ubuntu.id

  instance_type = var.vault_instance_type
  key_name      = var.key_name

  security_groups = [aws_security_group.vault.name]

  lifecycle {
    ignore_changes = [user_data, ami]
  }

  tags = {
    Name = local.vault_name
  }

  user_data = templatefile("userdata/vault-userdata.tpl", {
    hostname  = var.vault_hostname
    syslog_ip = aws_instance.syslog.private_ip
  })

  depends_on = [aws_instance.syslog]

}

resource "aws_security_group" "vault" {
  name        = local.vault_name
  description = "Allow vault inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "73.166.0.0/16"]
  }

  ingress {
    description = "vault"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["73.166.0.0/16"]
  }

  ingress {
    description = "icmp"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "73.166.0.0/16"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = local.vault_name
  }
}
