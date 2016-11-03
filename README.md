# 測試 AWS EC2 機器轉檔效能


## 前製作業

### 取得 Access Key ID 和 Secret Access Key

1. [IAM](https://console.aws.amazon.com/iam/home) 建立 User 並給他相對應的權限
1. 拿到 User 的 Secret Credentials

註: [AWS 參考文件](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html)

### 安裝 AWS CLI

```bash
$ pip install awscli
```
更詳細的步驟，可以參考 [AWS CLI 安裝手冊](http://docs.aws.amazon.com/cli/latest/userguide/installing.html#install-with-pip)


### 設定 AWS CLI

```bash
$ aws configure
AWS Access Key ID [None]: AWS_ACCESS_KEY_ID
AWS Secret Access Key [None]: AWS_SECRECT_ACCESS_KEY
Default region name [None]: ap-northeast-1
Default output format [None]: ENTER
```

### 建立 Security Group 開啟 ssh 登入

```bash
$ aws ec2 create-security-group --group-name devenv-sg --description "security group for development environment in EC2"
$ aws ec2 authorize-security-group-ingress --group-name devenv-sg --protocol tcp --port 22 --cidr 0.0.0.0/0
```

### 0.5 上傳測試檔

1. 上傳測試檔到 [S3](https://console.aws.amazon.com/s3/home)
1. 取得公開下載網址

---

## 1. 啟動

```
$ ./run.sh MEDIA_ON_S3_URL
```

---

## 附錄

### Launch EC2 instance

#### Create a Key Pair for the EC2 Instance

```bash
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

#### Delete a Key Pair for the EC2 Instance

```bash
$ aws ec2 delete-key-pair --key-name MyKeyPair
```
