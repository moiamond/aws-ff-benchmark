#!/bin/bash

s3_url=$1
ec2_type=t2.micro
logfile=log.txt

# create key pair
aws ec2 create-key-pair --key-name $(uname -n) --query "KeyMaterial" --output text > $(uname -n).pem
chmod 400 $(uname -n).pem
echo Create Key Pair ... $(uname -n).pem

# launch ec2 instance
instance_id=$(aws ec2 run-instances --image-id ami-0c11b26d --count 1 --instance-type $ec2_type --key-name $(uname -n) --output text --query 'Instances[*].InstanceId')
echo instance_id=$instance_id

# wait for booting
while state=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" = "pending"; do
  sleep 1; echo -n '.'
done; echo " $state"

# get ip
ip_address=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo ip_address=$ip_address

echo "Waiting for connection ..."
sleep 60

# Install docker
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $(uname -n).pem ec2-user@$ip_address  "sudo curl -sSL https://get.docker.com/ | sh; sudo usermod -aG docker ec2-user; sudo /etc/init.d/docker restart"

# Pull image
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $(uname -n).pem ec2-user@$ip_address  "docker pull jrottenberg/ffmpeg"

# Download content from url
echo Downloading ... $1
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $(uname -n).pem ec2-user@$ip_address  "wget -q $1 -O testclip"

##############################################################################################################
# Benchmark Begin

echo ------------------------------------------------------------------------ >> $logfile
echo [$(date +"%Y-%m-%d %H:%M:%S")] ec2 type: $ec2_type, content: $1 >> $logfile
echo [$(date +"%Y-%m-%d %H:%M:%S")] Begin Benchmark: >> $logfile
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $(uname -n).pem ec2-user@$ip_address  "time docker run -v /home/ec2-user:/content jrottenberg/ffmpeg -i /content/testclip -vf \"yadif=0:-1:0,scale=1920:1080\" -r 30 -c:v libx264 -pix_fmt yuv420p -profile:v high -level 4.0 -b:v 5000K -c:a libfdk_aac -b:a 256K -movflags +faststart out.mp4" 2>&1 | tee -a $logfile

echo [$(date +"%Y-%m-%d %H:%M:%S")] End >> $logfile
echo ------------------------------------------------------------------------ >> $logfile

# Benchmark End
##############################################################################################################

# terminate
aws ec2 terminate-instances --instance-ids "$instance_id" --output text --query "TerminatingInstances[*].CurrentState.Name"

# delete key pair
aws ec2 delete-key-pair --key-name $(uname -n)
rm -f $(uname -n).pem
echo Delete Key Pair ... $(uname -n).pem
