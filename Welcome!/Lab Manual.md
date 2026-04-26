# Terraform & Ansible Lab Manual
## I - If you don't have docker:
**option 1- install it**
```
Windows: https://docs.docker.com/desktop/install/windows-install/
Mac: https://docs.docker.com/desktop/install/mac-install/
Linux: (run the command) sudo apt install docker.io docker-compose
```

**option 2 -**
Github Codespaces
**option 3 -**
Killercoda -- virtual linux environment
***

## II - On ubuntu cmd:
### if you don't have it open your windows powershell as administrator and run 
``` powershell
wsl --install
```
### open ubuntu run:

#### 1- 
``` bash
#1- install pip
sudo apt update && sudo apt install -y python3-pip

# 2- install localstack 
curl -L -o localstack-cli.tar.gz https://github.com/localstack/localstack-cli/releases/download/v4.0.0/localstack-cli-4.0.0-linux-amd64-onefile.tar.gz

# 3- extract it
tar -xzf localstack-cli.tar.gz

# 4- move it to bin
sudo mv localstack /usr/local/bin/localstack
# 5- install awscli and ansible
pip3 install awscli-local
pip3 install ansible
 # or
 python3 -m pip install --upgrade pip
python3 -m pip install awscli-local
python3 -m pip install ansible
```

### 2- to verify 
``` Bash
localstack --version
ansible --version
awslocal --version

```


### 3- install terraform 
``` Bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```


then 
``` Bash
# 2. Add the repo to apt sources
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

then
```
# 3. Update and install
sudo apt update && sudo apt install terraform -y
```


### verify terraform
``` bash
terraform --version
```


## Environment Setup

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

## Terraform

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

### Teaching Moment — Drift Detection

1. Go into LocalStack console or manually modify a tag
2. Run `terraform plan` again
3. Watch Terraform detect the difference between desired state and real state

---

## Part 3 — Ansible

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

### Teaching Moment — Idempotency

Run the playbook again:

```bash
ansible-playbook playbook.yml
```

> **We should notice that :** Nothing changed. No services restarted. This is **idempotency** — the core principle of configuration management.

Now break it intentionally:

```bash
# Delete the web page manually
docker exec web-server rm /var/www/html/index.html

# Run playbook again
ansible-playbook playbook.yml
```

> Ansible detected the missing file and restored it automatically.

---

## Part 4 — Full Pipeline

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


## Troubleshooting

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