locals {
  syslog_name = "${var.syslog_hostname}-${random_string.random.result}"
}

resource "aws_instance" "syslog" {
  ami = data.aws_ami.latest-ubuntu.id

  instance_type = var.syslog_instance_type
  key_name      = var.ec2_key_pair

  security_groups = [aws_security_group.syslog.name]

  root_block_device {
    # size in GiB. Set high if you plan to perform Vault benchmark tests which 
    # can fill a disk quickly
    volume_size = 40
  }

  lifecycle {
    ignore_changes = [user_data, ami]
  }

  tags = {
    Name = local.syslog_name
  }

  user_data = templatefile("userdata/syslog-userdata.tpl", {
    hostname        = var.syslog_hostname
    slack_notif_url = var.slack_notif_url
  })

  depends_on = [random_string.random]

}

resource "aws_security_group" "syslog" {
  name        = local.syslog_name
  description = "Allow inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "73.166.0.0/16"]
  }

  ingress {
    description = "syslog"
    from_port   = 1500
    to_port     = 1600
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
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
    Name = local.syslog_name
  }
  depends_on = [random_string.random]
}
