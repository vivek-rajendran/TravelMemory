# TravelMemory MERN Application — AWS Automated Deployment

This repository contains the infrastructure-as-code (IaC) and configuration management scripts to deploy the **TravelMemory** MERN-stack application on AWS using **Terraform** and **Ansible**.

---

## 🏗️ Architecture Overview

The application is deployed inside a dedicated AWS Virtual Private Cloud (VPC) with high network security isolation:

* **Public Subnet (`10.0.1.0/24`):** Hosts the **Web Server** running Nginx as a reverse proxy, the React frontend build, and Node.js/Express backend managed via PM2.
* **Private Subnet (`10.0.2.0/24`):** Hosts the **MongoDB Database Server**, completely isolated from direct public internet access.
* **Bastion / ProxyJump:** Administrative SSH access to the DB server is routed via ProxyJump through the Web Server.

---

## 📁 Repository Structure

```text
TravelMemory/
├── terraform/          # Infrastructure provisioning scripts (VPC, Subnets, EC2, SG)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── ansible/            # Configuration management playbooks & inventory
│   ├── inventory.ini
│   ├── setup-web.yml
│   ├── setup-db.yml
│   ├── deploy-app.yml
│   └── README.md
├── backend/            # Express.js backend source code
├── frontend/           # React.js frontend source code
└── README.md           # Main documentation file

🚀 Quick Deployment Guide
Prerequisites
AWS CLI installed and authenticated with AWS credentials.

Terraform installed.

Ansible installed on local control node.

SSH key pair created (travelmemory-key).

Step 1: Provision Infrastructure (Terraform)

cd terraform
terraform init
terraform apply -auto-approve

Step 2: Configure & Deploy Stack (Ansible)

cd ../ansible
eval $(ssh-agent -s)
ssh-add ~/.ssh/travelmemory-key

# Verify inventory connectivity
ansible all -m ping

# Run playbooks
ansible-playbook setup-web.yml
ansible-playbook setup-db.yml
ansible-playbook deploy-app.yml

🌐 Verification
Access the deployed application at:

[http://65.0.3.141](http://65.0.3.141)