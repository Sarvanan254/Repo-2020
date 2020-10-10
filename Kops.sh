#! /bin/bash
sudo apt-get update
sleep 2

sudo curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
sudo chmod +x ./kops
sudo mv ./kops /usr/local/bin/

sudo curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
sudo chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

sudo apt install awscli -Y ##Pls add the respective IAM role or IAM user to your client machine
aws configure
sleep 4

export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

sudo aws s3api create-bucket --bucket awssarvan2009  --region ap-south-1 --create-bucket-configuration LocationConstraint=ap-south-1 && aws s3api put-bucket-versioning --bucket awssarvan2009  --versioning-configuration Status=Enabled

sleep 3
ssh-keygen
export NAME=sarvan.k8s.local
export KOPS_STATE_STORE=s3://awssarvan2009

kops create cluster --zones ap-south-1a ${NAME}
kops update cluster --name sarvan.k8s.local --yes
