# 測試 AWS EC2 機器轉檔效能


## 0. 前製作業

### 0.1 取得 Access Key ID 和 Secret Access Key

1. IAM 建立 User 並給他相對應的權限
1. 拿到 User 的 Secret Credentials

### 0.2 安裝 AWS CLI

```
$ pip install awscli
```

### 0.3 設定 AWS CLI

```
$ aws configure
AWS Access Key ID [None]: AWS_ACCESS_KEY_ID
AWS Secret Access Key [None]: AWS_SECRECT_ACCESS_KEY
Default region name [None]: ap-northeast-1
Default output format [None]: ENTER
```

### 0.4 上傳測試檔

1. 上傳測試檔到 `S3`
1. 取得公開下載網址

---

## 1. 啟動

```
$ ./run.sh
```

---

## 附錄

### Launch EC2 instance

#### Create a Security Group, Key Pair, and Role for the EC2 Instance

```basg
$ aws ec2 create-security-group --group-name devenv-sg --description "security group for development environment in EC2"
{
    "GroupId": "sg-98b474ff"
}
$ aws ec2 authorize-security-group-ingress --group-name devenv-sg --protocol tcp --port 22 --cidr 0.0.0.0/0
$ aws ec2 create-key-pair --key-name MyKeyPair --query "KeyMaterial" --output text > MyKeyPair.pem
```

#### Launching an Instance

```bash
$ aws ec2 run-instances --image-id ami-0c11b26d --security-group-ids sg-98b474ff --count 1 --instance-type t2.micro --key-name MyKeyPair 
```

#### Connect to your instance

```bash
$ aws ec2 describe-instances --instance-ids i-a518e53b --query "Reservations[0].Instances[0].PublicIpAddress"
"52.199.86.109"
$ ssh -i MyKeyPair.pem ubuntu@52.199.86.109
```

#### Terminating Your Instance

```bash
$ aws ec2 terminate-instances --instance-ids i-a518e53b
{                                              
    "TerminatingInstances": [                  
        {                                      
            "CurrentState": {                  
                "Code": 32,                    
                "Name": "shutting-down"        
            },                                 
            "PreviousState": {                 
                "Code": 16,                    
                "Name": "running"              
            },                                 
            "InstanceId": "i-a518e53b"         
        }                                      
    ]                                          
}                                              
```