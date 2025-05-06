# 🚀 rancher-terraform-deployment

This Terraform project simplifies the deployment of **Rancher** on AWS. With just a few commands, you get a fully configured EC2 instance, VPC, security groups, and optional RKE2 and Cert-Manager installation. The setup is highly flexible, allowing you to deploy in any VPC and manage multiple environments effortlessly.

## ✨ Features
- 🔹 **One-click Rancher Deployment** – Automatically sets up Rancher on an EC2 instance.
- 🔹 **AWS Infrastructure as Code** – Creates a VPC, security groups, and inbound rules.
- 🔹 **Customizable Installation** – Toggle RKE2 and Cert-Manager installation.
- 🔹 **Multi-Workspace Support** – Deploy to different environments easily.
- 🔹 **Version Control** – Use the `prefix` variable to separate multiple environments.
- 🔹 **IP Retention for Seamless Migration** – Preserve critical IP configurations for reusability.

## 🛠 Prerequisites
Before you start, ensure you have:
- [Terraform installed](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- AWS credentials set up (Access Key & Secret Key)
- A valid SSH key pair for accessing the instance

## ⚙️ Configuration
Customize your infrastructure by editing `terraform.tfvars`:
```hcl
prefix              = "your-environment"
aws_region_instance = "us-west-2"
aws_region_s3       = "us-west-2"
vpc_cidr            = "10.2.0.0/16"
subnet_cidr         = "10.2.0.0/24"
aws_zone            = "us-west-2b"
ami_id              = "ami-87654321"
instance_type       = "t3.medium"
key_name            = "your-key"
root_volume_size    = 50
encryption_secret_key = ""
```

## 🚀 Deployment Steps
Get your Rancher setup running in minutes:
1. **Initialize Terraform**
   ```sh
   terraform init
   ```
2. **Validate the configuration**
   ```sh
   terraform validate
   ```
3. **Preview changes**
   ```sh
   terraform plan -var-file=terraform.tfvars
   ```
4. **Deploy Rancher**
   ```sh
   terraform apply -var-file=terraform.tfvars -auto-approve
   ```

## 🔥 IP Retention for Seamless Migration
To ensure your Rancher instance retains the same IP after redeployment, use the preserved instance configuration:
```sh
cp instance_preserve.tf.bk instance.tf
```
This ensures Rancher keeps the same IP address, making migration and reconfiguration seamless.

## 🧹 Cleaning Up
To tear down the infrastructure, simply run:
```sh
terraform destroy -var-file=terraform.tfvars -auto-approve
```

## 📌 Notes
- The `prefix` variable ensures you can manage multiple deployments easily.
- Terraform workspaces allow seamless multi-environment support.
- The `.bk` files help retain important configurations like static IPs for redeployment.

## 🌍 Working with Terraform Workspaces
To create and switch between Terraform workspaces, use:
```sh
terraform workspace new dev
terraform workspace select dev
```
Then apply changes within the selected workspace:
```sh
terraform apply -var-file=terraform.tfvars -auto-approve
```

## 📜 License
This project is licensed under the **MIT License**.

---

💡 **Pro Tip:** Use Terraform workspaces to manage different environments efficiently!


