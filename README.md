# 🚀 Terraform + Ansible Lab
### DevOps / MLOps Track — Infrastructure as Code

---

## 🎯 Lab Objective

By the end of this lab you will:
- Provision simulated AWS infrastructure using **Terraform**
- Configure a web server automatically using **Ansible**
- Understand the difference between provisioning and configuration management
- Run a full end-to-end IaC pipeline on your local machine

---

## 🧰 Prerequisites

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

## 📁 Repository Structure

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

## 🚦 Part 1 — Environment Setup

Clone the repo and start the environment:

```bash
git clone <repo-url>
cd terraform-ansible-lab

# Start LocalStack (fake AWS) and the target web server
docker compose up -d

# Verify LocalStack is healthy
curl http://localhost:4566/_localstack/health
```

Create the S3 bucket and DynamoDB table for Terraform remote state:

```bash
# S3 bucket to store state file
awslocal s3api create-bucket --bucket lab-terraform-state --region us-east-1
awslocal s3api put-bucket-versioning \
  --bucket lab-terraform-state \
  --versioning-configuration Status=Enabled

# DynamoDB table for state locking
awslocal dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

---

## 🔵 Part 2 — Terraform

### Step 1: Initialize

```bash
cd terraform
terraform init
```

> **What just happened?** Terraform downloaded the AWS provider plugin and connected to the remote state backend.

### Step 2: Plan

```bash
terraform plan
```

> **Study the output carefully:**
> - `+` green = resource will be **created**
> - `~` yellow = resource will be **modified**
> - `-` red = resource will be **destroyed**

### Step 3: Apply

```bash
terraform apply
# Type 'yes' when prompted
```

### Step 4: Inspect State

```bash
# List all tracked resources
terraform state list

# Inspect a specific resource
terraform state show aws_instance.web_server

# See all outputs
terraform output
```

> **Key output:** Note the `web_server_ip` value — Ansible needs this.

### 🧪 Teaching Moment — Drift Detection

1. Go into LocalStack console or manually modify a tag
2. Run `terraform plan` again
3. Watch Terraform detect the difference between desired state and real state

---

## 🟠 Part 3 — Ansible

### Step 1: Test Connectivity

```bash
cd ../ansible
ansible all -m ping
```

You should see:
```
web1 | SUCCESS => { "ping": "pong" }
```

### Step 2: Dry Run

```bash
ansible-playbook playbook.yml --check
```

> This is Ansible's equivalent of `terraform plan` — shows what **would** change without making any changes.

### Step 3: Apply the Playbook

```bash
ansible-playbook playbook.yml
```

### Step 4: Verify

Open your browser and visit: **http://localhost:8080**

You should see the deployed web page showing server info.

### 🧪 Teaching Moment — Idempotency

Run the playbook again:

```bash
ansible-playbook playbook.yml
```

> **Notice:** Nothing changed. No services restarted. This is **idempotency** — the core principle of configuration management.

Now break it intentionally:

```bash
# Delete the web page manually
docker exec web-server rm /var/www/html/index.html

# Run playbook again
ansible-playbook playbook.yml
```

> Ansible detected the missing file and restored it automatically.

---

## 🔴 Part 4 — Full Pipeline

Run everything in one command:

```bash
cd ..
chmod +x scripts/run_all.sh
./scripts/run_all.sh
```

To tear everything down:

```bash
./scripts/run_all.sh destroy
docker compose down
```

---

## 🏆 Student Challenges

Work through these after completing the main lab:

### Level 1 — Easy
- Add a second EC2 instance in `main.tf` called `db_server`
- Tag it with `Role = "database"`
- Add its IP to a new `[dbservers]` group in the Ansible inventory

### Level 2 — Medium
- Create a new Ansible role called `monitoring`
- Install `htop` and `net-tools` on the server
- Add this role to the playbook **after** the webserver role

### Level 3 — Hard
- Create a `staging` Terraform workspace
- Deploy the same infrastructure to both `dev` and `staging`
- Use `terraform.workspace` in your tags to differentiate them

```bash
terraform workspace new staging
terraform workspace select staging
terraform apply
```

### Level 4 — MLOps Bonus
- Add a new Ansible role called `ml_env`
- Install Python 3.11, pip, and the following packages:
  ```
  scikit-learn
  mlflow
  pandas
  ```
- Verify MLflow is accessible at port 5000

---

## 🔑 Key Concepts Summary

| Concept | Tool | Example |
|---|---|---|
| Provision infrastructure | Terraform | Create EC2, S3, Security Groups |
| Track what exists | Terraform State | `terraform.tfstate` |
| Prevent concurrent edits | State Locking | DynamoDB lock table |
| Install & configure software | Ansible | Install Nginx, deploy HTML |
| Never re-do what's done | Idempotency | Run playbook 10x — same result |
| Reusable infrastructure | Modules | `module "web" { source = ... }` |
| Reusable configuration | Roles | `roles/webserver/` |

---

## 🐛 Troubleshooting

**LocalStack not starting:**
```bash
docker compose logs localstack
```

**Ansible can't connect:**
```bash
# Test SSH manually
ssh -p 2222 root@127.0.0.1  # password: labpassword
```

**Terraform backend error:**
```bash
# Make sure the S3 bucket exists first
awslocal s3 ls
```

**Port 8080 not showing the page:**
```bash
# Check if nginx is running inside the container
docker exec web-server service nginx status
```
