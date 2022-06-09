#!/bin/bash 

echo -n "State: "
aws ec2 describe-instances --instance-ids $(terraform output --raw vault_instance_id) \
 | jq -r ".Reservations[] | .Instances[] | .State.Name"

aws ec2 describe-instances --query "Reservations[].Instances[].[Tags[?Key=='Name'],InstanceId,State.Name]"  | jq
