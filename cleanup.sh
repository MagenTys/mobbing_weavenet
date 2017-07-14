#!/bin/bash


# Check that we have everything we need

if [ -z "$(which aws)" ]; then
    echo "error: Cannot find AWS-CLI, please make sure it's installed"
    exit 1
fi

REGION=$(aws configure list 2> /dev/null | grep region | awk '{ print $2 }')
if [ -z "$REGION" ]; then
    echo "error: Region not set, please make sure to run 'aws configure'"
    exit 1
fi

# if [ -n "$(aws ecs describe-clusters --clusters dockerweavesample-cluster --query 'failures' --output text)" ]; then
#     echo "error: ECS cluster dockerweavesample-cluster doesn't exist, nothing to clean up"
#     exit 1
# fi

# Delete service
echo -n "Deleting ECS Service (dockerweavesample-service) .. "
aws ecs update-service --cluster dockerweavesample-cluster --service  dockerweavesample-service --desired-count 0 > /dev/null
aws ecs delete-service --cluster dockerweavesample-cluster --service  dockerweavesample-service > /dev/null
echo "done"

# Task definition
echo -n "De-registering ECS Task Definition (dockerweavesample-task) .. "
REVISION=$(aws ecs describe-task-definition --task-definition dockerweavesample-task --query 'taskDefinition.revision' --output text)
aws ecs deregister-task-definition --task-definition "dockerweavesample-task:${REVISION}" > /dev/null
echo "done"

# Auto Scaling Group
echo -n "Deleting Auto Scaling Group (dockerweavesample-group) .. "
# Save Auto Scaling Group instances to wait for them to terminate
INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names dockerweavesample-group --query 'AutoScalingGroups[0].Instances[*].InstanceId' --output text)
aws autoscaling delete-auto-scaling-group --force-delete --auto-scaling-group-name dockerweavesample-group
echo "done"

# # Wait for instances to terminate
# echo -n "Waiting for instances to terminate (this may take a few minutes) .. "
# STATE="foo"
# while [ -n "$STATE" -a "$STATE" != "terminated terminated terminated" ]; do
#     STATE=$(aws ec2 describe-instances --instance-ids ${INSTANCE_IDS} --query 'Reservations[0].Instances[*].State.Name' --output text)
#     # Remove spacing
#     STATE=$(echo $STATE)
#     sleep 2
# done
# echo "done"

# Launch configuration
echo -n "Deleting Launch Configuration (weave-ecs-launch-configuration) .. "
aws autoscaling delete-launch-configuration --launch-configuration-name weave-ecs-launch-configuration
echo "done"

# IAM role
echo -n "Deleting weave-ecs-role IAM role (weave-ecs-role) .. "
aws iam remove-role-from-instance-profile --instance-profile-name weave-ecs-instance-profile --role-name weave-ecs-role
aws iam delete-instance-profile --instance-profile-name weave-ecs-instance-profile
aws iam delete-role-policy --role-name weave-ecs-role --policy-name weave-ecs-policy
aws iam delete-role --role-name weave-ecs-role
echo "done"


# Key pair
echo -n "Deleting Key Pair (dockerweavesample-key, deleting file dockerweavesample-key.pem) .. "
aws ec2 delete-key-pair --key-name dockerweavesample-key
rm -f dockerweavesample-key.pem
echo "done"

# Security group
echo -n "Deleting Security Group (dockerweavesample) .. "
GROUP_ID=$(aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName==`dockerweavesample`].GroupId' --output text)
aws ec2 delete-security-group --group-id "$GROUP_ID"
echo "done"

# Internet Gateway
echo -n "Deleting Internet gateway .. "
VPC_ID=$(aws ec2 describe-tags --filters Name=resource-type,Values=vpc,Name=tag:Name,Values=dockerweavesample-vpc --query 'Tags[0].ResourceId' --output text)
GW_ID=$(aws ec2 describe-tags --filters Name=resource-type,Values=internet-gateway,Name=tag:Name,Values=dockerweavesample --query 'Tags[0].ResourceId' --output text)
aws ec2 detach-internet-gateway --internet-gateway-id $GW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $GW_ID
echo "done"

# Subnet
echo -n "Deleting Subnet (dockerweavesample-subnet) .. "
SUBNET_ID=$(aws ec2 describe-tags --filters Name=resource-type,Values=subnet,Name=tag:Name,Values=dockerweavesample-subnet --query 'Tags[0].ResourceId' --output text)
aws ec2 delete-subnet --subnet-id $SUBNET_ID
echo "done"

# VPC
echo -n "Deleting VPC (dockerweavesample-vpc) .. "
aws ec2 delete-vpc --vpc-id $VPC_ID
echo "done"

# Cluster
echo -n "Deleting ECS cluster (dockerweavesample-cluster) .. "
aws ecs delete-cluster --cluster dockerweavesample-cluster > /dev/null
echo "done"
