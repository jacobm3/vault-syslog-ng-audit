variable "vpc_id" { type = string }
variable "key_name" { type = string }

variable "vault_hostname" { type = string }
variable "vault_instance_type" { type = string }

variable "syslog_hostname" { type = string }
variable "syslog_instance_type" { type = string }

# The slack webhook url contains a sensitive auth key. 
# Set in the apply environment like this:
#
# export TF_VAR_slack_notif_url=https://hooks.slack.com/services/T01xxxxxxx/B03Kyyyy/fgxDIzzzzzz
#
variable "slack_notif_url" { type = string }

