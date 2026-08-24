---

### File 3: `TravelMemory/ansible/README.md`

```markdown
# Configuration Management & Deployment with Ansible

This directory contains the Ansible inventory and playbooks to configure the provisioned servers, install runtime environments, bind database interfaces, and deploy the TravelMemory application.

---

## 📋 File Inventory

* **`inventory.ini`:** Host definitions and SSH connection properties (including Bastion `ProxyJump` configuration).
* **`setup-web.yml`:** Installs Node.js (v18+), NPM, PM2, and Nginx on the Web Server.
* **`setup-db.yml`:** Installs and binds MongoDB Community Edition on the DB Server.
* **`deploy-app.yml`:** Clones the repository, configures `.env`, compiles React assets, sets up Nginx reverse proxy, and manages processes via PM2.

---

## 🔑 SSH Bastion (ProxyJump) Configuration

Because the DB server resides in a private subnet, Ansible uses SSH `ProxyJump` through the public Web server defined in `inventory.ini`:

```ini
[web]
web_server ansible_host=65.0.3.141 ansible_user=ubuntu

[db]
db_server ansible_host=10.0.2.141 ansible_user=ubuntu

[db:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyJump=ubuntu@65.0.3.141'

🚀 Execution Commands
Add SSH Key to Agent:

eval $(ssh-agent -s)
ssh-add ~/.ssh/travelmemory-key

Test Connectivity:

ansible all -m ping

Execute Deployment:

ansible-playbook setup-web.yml
ansible-playbook setup-db.yml
ansible-playbook deploy-app.yml

---

### Quick Git Commit Commands

To save these files to your repository immediately:

```bash
# Stage the new README files
git add README.md terraform/README.md ansible/README.md

# Commit
git commit -m "docs: add comprehensive README files for root, terraform, and ansible"

# Push to GitHub
git push origin feature/terraform_ansible_assignment