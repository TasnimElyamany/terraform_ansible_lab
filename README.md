# Terraform + Ansible Lab
### DevOps / MLOps Track — Infrastructure as Code

---

## Lab Objective

By the end of this lab you will:
- Provision simulated AWS infrastructure using **Terraform**
- Configure a web server automatically using **Ansible**
- Understand the difference between provisioning and configuration management
- Run a full end-to-end IaC pipeline on your local machine

---

## Prerequisites

Make sure these are installed before the lab:

| Tool | Install |
|---|---|
| Docker Desktop | https://docs.docker.com/get-docker/ |
| Terraform CLI | https://developer.hashicorp.com/terraform/install |
| Ansible | `pip install ansible` |
| awslocal | `pip install awscli-local` |
| sshpass | `sudo apt install sshpass` (Linux) or `brew install hudochenkov/sshpass/sshpass` (Mac) |

Verify everything is installed:
```bash
docker --version
terraform --version
ansible --version
awslocal --version
```

---

## Repository Structure

```
terraform-ansible-lab/
├── docker-compose.yml          # Spins up LocalStack + a target server
├── terraform/
│   ├── main.tf                 # Core infrastructure definition
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Exposed values (IPs, IDs)
│   └── backend.tf              # Remote state configuration
├── ansible/
│   ├── ansible.cfg             # Ansible settings
│   ├── inventory/
│   │   └── hosts.ini           # Target servers list
│   ├── playbook.yml            # Main playbook
│   └── roles/
│       └── webserver/
│           ├── tasks/main.yml      # What to do
│           ├── handlers/main.yml   # Triggered actions
│           ├── templates/
│           │   ├── index.html.j2   # Dynamic web page
│           │   └── nginx.conf.j2   # Nginx config
│           └── vars/main.yml       # Role variables
└── scripts/
    └── run_all.sh              # Full pipeline in one command
```

---


