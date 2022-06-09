#!/bin/bash -x 

aws ec2 start-instances --instance-ids $(terraform output -json | jq  -r '.vault_instance_id.value + " " + .syslog_instance_id.value')
#aws ec2 start-instances --instance-ids $(terraform output --raw vault_instance_id) $(terraform output --raw syslog_instance_id)

sleep 5

terraform refresh
