#!/bin/bash -x

aws ec2 stop-instances --instance-ids $(terraform output --raw vault_instance_id) $(terraform output --raw syslog_instance_id)
