#!/bin/bash

s3_url=$1
ec2_type=t2.micro

# launch ec2 instance
instance_id=$(aws ec2 run-instances --image-id ami-0c11b26d --security-group-ids sg-98b474ff --count 1 --instance-type $ec2_type --key-name $(uname -n) --output text --query 'Instances[*].InstanceId')
echo instance_id=$instance_id

# wait for booting
while state=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" = "pending"; do
  sleep 1; echo -n '.'
done; echo " $state"

# get ip
ip_address=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo ip_address=$ip_address

aws ec2 get-console-output --instance-id $instance_id --output text | perl -ne "print if /BEGIN SSH .* FINGERPRINTS/../END SSH .* FINGERPRINTS/"

sleep 60

# ssh
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $(uname -n).pem ec2-user@$ip_address  "sudo curl -sSL https://get.docker.com/ | sh; sudo usermod -aG docker ec2-user; sudo /etc/init.d/docker restart" | tee output1.txt

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $(uname -n).pem ec2-user@$ip_address  "docker pull jrottenberg/ffmpeg" | tee output2.txt

# https://s3-ap-northeast-1.amazonaws.com/bssff-test/ec2_1min.mxf
echo Downloading ... $1
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $(uname -n).pem ec2-user@$ip_address  "wget -q $1"

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $(uname -n).pem ec2-user@$ip_address  "time docker run -v /home/ec2-user:/content jrottenberg/ffmpeg -i /content/ec2_1min.mxf -vf \"yadif=0:-1:0,scale=1920:1080\" -r 30 -c:v libx264 -pix_fmt yuv420p -profile:v high -level 4.0 -b:v 5000K -c:a libfdk_aac -b:a 256K -movflags +faststart out.mp4" | tee output.txt


# terminate
aws ec2 terminate-instances --instance-ids "$instance_id" --output text --query "TerminatingInstances[*].CurrentState.Name"

# delete key pair
aws ec2 delete-key-pair --key-name $(uname -n)
