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

# add environment
cd /home/ubuntu
git clone https://github.com/jacobm3/gbin.git
chmod +x gbin/*

echo '. ~/gbin/jacobrc'  >> .bashrc
ln -s gbin/jacobrc .jacobrc

sudo chown -R ubuntu:ubuntu /home/ubuntu

cd /home/ubuntu/gbin && cp pg ng /usr/local/bin

./vim.sh 

# Configure syslog-ng
cd /etc/syslog-ng
#mv syslog-ng.conf syslog-ng.conf.dist
mkdir -p /var/log/syslog-ng
touch /var/log/syslog-ng/messages /var/log/syslog-ng/audit
chmod 644 /var/log/syslog-ng/messages /var/log/syslog-ng/audit

tee /etc/syslog-ng/conf.d/vault.conf <<EOF
options {
    time-reap(10);
    mark-freq(0);
    keep-hostname(yes);
};

# Vault audit logs
template t_imp {
  template("\$MSG\n");
  template_escape(no);
};
source s_vault_tcp {
         network(
           flags(no-parse)
           log-msg-size(268435456)
           transport(tcp) port(1515));
       };
destination d_vault {
        file(
            "/var/log/syslog-ng/audit"
            template(t_imp)
            owner("root")
            group("root")
            perm(0644)
            ); };
# System messages
source s_messages_tcp { network(transport(tcp) port(1514)); };
destination d_vault_messages {
        file(
            "/var/log/syslog-ng/messages"
            owner("root")
            group("root")
            perm(0644)
            ); };
log { source(s_messages_tcp); destination(d_vault_messages); };
log { source(s_vault_tcp); destination(d_vault); };


destination d_prog_json { program("/usr/local/bin/vault-audit-log-handler.py" template("\$MSG\n") ); };
destination d_prog_syslog { program("/usr/local/bin/vault-server-log-handler.py" template("<\${PRI}>\${DATE} \${HOST} \${MESSAGE}\n") ); };

log { source(s_vault_tcp); destination(d_prog_json); };
log { source(s_messages_tcp); destination(d_prog_syslog); };


EOF

cd /etc/logrotate.d
tee /etc/logrotate.d/vault-syslog-ng <<EOF
delaycompress
compress
compresscmd /usr/bin/zstd
compressext .zst
uncompresscmd /usr/bin/unzstd

/var/log/syslog-ng/audit
/var/log/syslog-ng/messages
{
        rotate 93
        daily
        missingok
        notifempty
        postrotate
                invoke-rc.d syslog-ng reload > /dev/null
        endscript
}
EOF


systemctl restart syslog-ng