resource "aws_instance" "syslog" {
  ami = data.aws_ami.latest-ubuntu.id

  # arm64
  # t4g.nano: 2vpu, 512MB ram, ebs = $0.0042/hr = $0.10/day = $3/month
  # t4g.micro: 2vpu, 1GB ram, ebs = $0.0084/hr = $0.20/day = $6/month
  # t4g.medium: 2vpu, 4GB ram, ebs = $0.0336/hr = $0.81/day = $24/month
  # t4g.large: 2vpu, 8GB ram, ebs = $0.0672/hr = $1.61/day = $48/month

  # amd64
  # t3a.nano; 2 vcpu, 512MB ram, ebs = $0.0052/hr = $0.12/day = $3.70/month
  # t3a.large; 2 vcpu, 8GB ram, ebs = $1.80/day
  # m5d.large; 2 vcpu, 8GB ram, nvme = $2.70/day
  # m5d.xlarge; 4 vcpu, 16GB ram, nvme = $5.42/day
  # m6a.large; 2 vcpu, 8GB ram, ebs = $2.07/day
  # c6a.xlarge: 4 vcpu, 8GB ram, ebs = $3.67/day

  instance_type = var.syslog_instance_type
  key_name      = var.key_name

  security_groups = [aws_security_group.syslog.name]

  root_block_device {
    # size in GiB. Set high if you plan to perform Vault benchmark tests which 
    # can fill a disk quickly
    volume_size = 20
  }

  lifecycle {
    ignore_changes = [user_data, ami]
  }

  tags = {
    Name = var.syslog_hostname
  }

  user_data = templatefile("userdata/syslog-userdata.tpl", {
    hostname = var.syslog_hostname
  })

}

resource "aws_security_group" "syslog" {
  name        = var.syslog_hostname
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
    Name = var.syslog_hostname
  }
}
