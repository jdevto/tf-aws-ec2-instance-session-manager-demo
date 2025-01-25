# 🚀 AWS Session Manager Terraform Demo

This Terraform configuration deploys **Amazon Linux 2 and Amazon Linux 2023 EC2 instances** with **AWS Systems Manager (SSM) Session Manager**, allowing secure remote access **without SSH or public IPs**.

---

## **📌 Features**

✅ **EC2 instances in a private subnet** (no public IPs required)
✅ **Uses AWS Systems Manager Session Manager** for remote access
✅ **No need for SSH or key pairs** (AWS SSM Agent handles communication)
✅ **Secure IAM Role with `AmazonSSMManagedInstanceCore` policy**
✅ **NAT Gateway for outbound internet access** (for instance updates)
✅ **VPC, Private Subnet, Security Group, IAM Role configuration included**

---

## **📂 Project Structure**

```plaintext
.
├── main.tf                  # Terraform configuration (VPC, EC2, IAM, Security Groups)
└── README.md                # Documentation (this file)
```

---

## **🛠 Prerequisites**

Before deploying, ensure you have:

- **Terraform** installed ([Download](https://developer.hashicorp.com/terraform/downloads)).
- **AWS CLI** installed ([Setup Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)).
- **AWS Session Manager Plugin** installed ([Installation Guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)).
- **AWS Credentials** configured (`~/.aws/credentials` or environment variables).

### **🔹 AWS SSM Session Manager Requirements**

✅ **EC2 instances must have SSM Agent installed** (Amazon Linux 2 has it by default, Amazon Linux 2023 requires installation).
✅ **IAM Role must have `AmazonSSMManagedInstanceCore` policy attached**.
✅ **Instance must be in a VPC with outbound internet (via NAT Gateway) OR use AWS PrivateLink for SSM endpoints**.

---

## **🚀 Deployment Steps**

### **1️⃣ Clone the Repository (If Applicable)**

```sh
git clone git@github.com:jdevto/tf-aws-ec2-instance-session-manager-demo.git
```

### **2️⃣ Initialize Terraform**

```sh
terraform init
```

### **3️⃣ Preview Changes Before Applying**

```sh
terraform plan
```

### **4️⃣ Deploy EC2 Instances with AWS Session Manager**

```sh
terraform apply -auto-approve
```

---

## **🔹 Connecting to Instances via AWS Session Manager**

Once the deployment is complete, connect to the instances **without SSH** using the AWS CLI:

```sh
aws ssm start-session --target i-xxxxxxxxxxxxxxxxx
```

🔹 **Find your instance ID** in the AWS Console under **EC2 → Instances**.

You can also connect through the AWS Console:

1. Navigate to **AWS Systems Manager → Session Manager**.
2. Select the instance.
3. Click **Start Session**.

---

## **🛑 Cleanup**

To **destroy all resources** created by this demo, run:

```sh
terraform destroy -auto-approve
```

---

## **🔹 Troubleshooting AWS Session Manager Issues**

### **❌ Cannot Find Instance in Session Manager**

✅ Ensure the **IAM Role includes `AmazonSSMManagedInstanceCore`**.
✅ **SSM Agent must be running on the instance** (Amazon Linux 2023 requires manual installation).
✅ Instance must have **outbound internet via NAT Gateway** OR **AWS SSM VPC Endpoints**.

### **❌ "Session Manager Plugin Not Found" Error**

✅ Install the AWS Session Manager Plugin on your local machine:

#### **Debian/Ubuntu**

```sh
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
```

#### **Amazon Linux 2 & RHEL 7**

```sh
sudo yum install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm
```

#### **Amazon Linux 2023 & RHEL 8/9**

```sh
sudo dnf install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm
```

#### **Windows**

Download and install from: [AWS SSM Plugin for Windows](https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe).

#### **macOS**

```sh
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
```

Verify installation:

```sh
session-manager-plugin --version
```

---

## **📌 Notes**

- **Amazon Linux 2 has AWS SSM Agent pre-installed**, but **Amazon Linux 2023 requires manual installation** (handled in `user_data`).
- **No SSH key pairs are required**, improving security.
- **Outbound internet access is required for SSM Agent updates** (unless using AWS PrivateLink for SSM endpoints).
- **Ensure AWS Session Manager Plugin is installed** on your local machine before using `aws ssm start-session`.

---

## **📧 Need Help?**

If you have any issues, feel free to open an **issue** or reach out! 🚀
