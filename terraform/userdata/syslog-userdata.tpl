#!/bin/bash

hostnamectl set-hostname "${hostname}"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y
apt-get install -y \
  bzip2 \
  git \
  htop \
  iotop \
  jq \
  logrotate \
  net-tools \
  netcat \
  nmap \
  python3-pip \
  syslog-ng \
  sysstat \
  tree \
  unzip \
  vim-nox \
  zstd

#sudo -u ubuntu bash -c 'pip install --upgrade pip; pip install -q boto3 hvac bpytop'

# add personal environment
cd /home/ubuntu
git clone https://github.com/jacobm3/gbin.git
chmod +x gbin/*

echo '. ~/gbin/jacobrc'  >> .bashrc
ln -s gbin/jacobrc .jacobrc

sudo chown -R ubuntu:ubuntu /home/ubuntu

cd /home/ubuntu/gbin && cp pg ng /usr/local/bin

./vim.sh 

# add alert handler scripts
cd /home/ubuntu
git clone https://github.com/jacobm3/vault-syslog-ng-audit.git
cp vault-syslog-ng-audit/terraform/scripts/*.py /usr/local/bin
chmod +x /usr/local/bin/*.py

cat > /usr/local/etc/vault-log-handler.ini <<EOF
[slack]
url = ${slack_notif_url}
EOF



cp vault-syslog-ng-audit/terraform/scripts/syslog-server.vault.conf /etc/syslog-ng/conf.d/vault.conf
mkdir -p /var/log/vault/archive
systemctl restart syslog-ng

cd /etc/logrotate.d
cat > /etc/logrotate.d/vault-syslog-ng <<EOF
compress
compresscmd /usr/bin/zstd
compressext .zst
uncompresscmd /usr/bin/unzstd

/var/log/vault/audit
/var/log/vault/messages
{
        rotate 2300
        hourly
        dateext
        missingok
        olddir /var/log/vault/archive
        postrotate
                invoke-rc.d syslog-ng reload > /dev/null
        endscript
}
EOF

cat > /etc/cron.d/logrotate-vault <<EOF
0 * * * * root /usr/sbin/logrotate /etc/logrotate.d/vault-syslog-ng
EOF
