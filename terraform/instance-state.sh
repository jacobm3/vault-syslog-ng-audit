#!/bin/bash 

echo -n "State: "
aws ec2 describe-instances --instance-ids \
$(terraform output -json | jq  -r '.vault_instance_id.value + " " + .syslog_instance_id.value') \
 | jq -r ".Reservations[] | .Instances[] | .State.Name"

#aws ec2 describe-instances --query "Reservations[].Instances[].[Tags[?Key=='Name'],InstanceId,State.Name]"  | jq
