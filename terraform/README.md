---

### File 2: `TravelMemory/terraform/README.md`

```markdown
# Infrastructure Provisioning with Terraform

This directory contains the Terraform configuration files to set up the AWS networking perimeter and compute instances for the TravelMemory application.

---

## 📜 Provisioned Infrastructure

* **VPC:** Custom VPC with `10.0.0.0/16` CIDR block.
* **Subnets:**
  * Public Subnet: `10.0.1.0/24` (Web Host)
  * Private Subnet: `10.0.2.0/24` (Database Host)
* **Gateways:**
  * Internet Gateway (IGW) for incoming public HTTP/SSH traffic.
  * NAT Gateway in the public subnet enabling outbound internet access for private updates.
* **Security Groups:**
  * `web_sg`: Allows HTTP (80) from `0.0.0.0/0` and SSH (22) from admin IPs.
  * `db_sg`: Restricts SSH (22) and MongoDB (27017) strictly to `10.0.1.0/24` (Web Subnet).
* **EC2 Instances:**
  * `web_server`: Public Ubuntu 22.04 LTS instance (`65.0.3.141`).
  * `db_server`: Private Ubuntu 22.04 LTS instance (`10.0.2.141`).

---

## 📁 File Structure

* **`main.tf`:** Core infrastructure resources (VPC, Subnets, Gateways, Route Tables, SGs, EC2).
* **`variables.tf`:** Configurable parameters (AWS region, instance types, key name, CIDR blocks).
* **`outputs.tf`:** Exported outputs (Public IP of Web Server, Private IP of DB Server).
* **`.terraform.lock.hcl`:** Locked dependency versions for AWS provider stability.

---

## 💡 How to Run

1. **Initialize Working Directory:**
   ```bash
   terraform init

Validate Configuration:

terraform validate

Apply Configuration:

terraform apply -auto-approve

Teardown (When finished):

terraform destroy -auto-approve