#!/bin/bash

hostnamectl set-hostname "${hostname}"

echo "${syslog_ip}" > /tmp/syslog-ip

export DEBIAN_FRONTEND=noninteractive

# add hashi stuff
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

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
  vault \
  vim-nox \
  zstd

#sudo -u ubuntu bash -c 'pip install --upgrade pip; pip install -q boto3 hvac bpytop'

# add environment
cd /home/ubuntu
git clone https://github.com/jacobm3/gbin.git
chmod +x gbin/*

echo '. ~/gbin/jacobrc'  >> .bashrc
#echo 'set -o emacs' >> .bashrc
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

# Don't add stats or markers
options {
  time-reap(30);
  stats_freq(0);
  mark_freq(0);
};

# Vault audit logs
# Don't add hostname/syslog timestamps. Preserve raw JSON messages.
template t_imp {
  template("\$MSG\n");
  template_escape(no);
};

# Raw TCP input listening only on loopback interface
source s_vault_tcp {
         network(
           flags(no-parse)
           log-msg-size(268435456)
           ip(127.0.0.1)
           transport(tcp) 
           port(1515));
       };

# Vault server daemon logs
source s_file_daemon {
    file("/var/log/daemon.log");
};

# Send audit logs to log server on TCP/1515
# 4GB disk buffer, only used when log server is down
destination d_remote_audit {
    tcp("${syslog_ip}"
        port(1515)
        template(t_imp)
        disk-buffer(
            mem-buf-length(10000)
            disk-buf-size(4000000000)
            truncate-size-ratio(0.1)
        )
    );
};

# Send daemon logs to log server on TCP/1514
# 1GB disk buffer
destination d_remote_daemon {
    network("${syslog_ip}"
        port(1514)
        disk-buffer(
            mem-buf-length(10000)
            disk-buf-size(1000000000)
            truncate-size-ratio(0.1)
        )
    );
};

log { source(s_vault_tcp); destination(d_remote_audit); };
log { source(s_file_daemon); destination(d_remote_daemon); };

EOF

systemctl enable syslog-ng
systemctl restart syslog-ng


# start vault
systemctl enable vault
systemctl start vault
sleep 1

cat > /etc/profile.d/vault.sh <<EOF
export VAULT_ADDR=https://localhost:8200/
export VAULT_SKIP_VERIFY=1
EOF
. /etc/profile.d/vault.sh


# DANGER: simple init/unseal for demo purposes.
# Use cloud auto unseal or shamir+gpg for production.
# https://learn.hashicorp.com/tutorials/vault/pattern-unseal?in=vault/recommended-patterns
vault operator init -format=json -t 1 -n 1 > /etc/vault.d/.init.json
vault operator unseal $(jq -r .unseal_keys_b64[0] < /etc/vault.d/.init.json)
vault login -no-print $(jq -r .root_token < /etc/vault.d/.init.json) 
vault audit enable socket address=localhost:1515 socket_type=tcp hmac_accessor=false


cat >> /home/ubuntu/.bashrc <<'EOF'
echo
echo '#'
echo '# NOT FOR PRODUCTION USE'
echo '#' 
echo '# https://learn.hashicorp.com/tutorials/vault/pattern-unseal?in=vault/recommended-patterns'
echo '#'
echo '#'
echo '# Unseal:'
echo 'vault operator unseal $(jq -r .unseal_keys_b64[0] < /etc/vault.d/.init.json)'
echo '# Login:'
echo 'vault login $(jq -r .root_token < /etc/vault.d/.init.json)'
echo 
EOF

