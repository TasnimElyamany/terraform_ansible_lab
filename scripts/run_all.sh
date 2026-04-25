#!/bin/bash

set -e   # exit immediately on any error
set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # no color

log()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }


# DESTROY MODE
if [ "$1" == "destroy" ]; then
  warn "Destroying all infrastructure..."
  cd terraform && terraform destroy -auto-approve
  ok "All resources destroyed."
  exit 0
fi


# STEP 1: Start LocalStack

log "Starting LocalStack via Docker Compose..."
docker compose up -d localstack web-server

log "Waiting for LocalStack to be healthy..."
until curl -s http://localhost:4566/_localstack/health | grep -q '"ec2": "available"'; do
  echo -n "."
  sleep 3
done
echo ""
ok "LocalStack is ready."


# STEP 2: Create S3 bucket and DynamoDB table for remote state

log "Setting up Terraform remote state backend..."

awslocal s3api create-bucket \
  --bucket lab-terraform-state \
  --region us-east-1 2>/dev/null || warn "State bucket already exists"

awslocal s3api put-bucket-versioning \
  --bucket lab-terraform-state \
  --versioning-configuration Status=Enabled 2>/dev/null || true

awslocal dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1 2>/dev/null || warn "Lock table already exists"

ok "Remote state backend ready."


# STEP 3: Terraform

log "Running Terraform..."
cd terraform

log "terraform init..."
terraform init -reconfigure

log "terraform plan..."
terraform plan -out=tfplan

log "terraform apply..."
terraform apply tfplan

# Capture outputs
WEB_IP=$(terraform output -raw web_server_ip 2>/dev/null || echo "127.0.0.1")
ok "Terraform complete. Web server IP: ${WEB_IP}"


# STEP 4: Inject IP into Ansible inventory

cd ..
log "Updating Ansible inventory with server IP..."

cat > ansible/inventory/hosts.ini <<EOF
[webservers]
web1 ansible_host=127.0.0.1 ansible_port=2222 ansible_user=root ansible_ssh_pass=labpassword

[webservers:vars]
environment=dev
EOF

ok "Inventory updated."


# STEP 5: Wait for SSH

log "Waiting for SSH to become available..."
sleep 10


# STEP 6: Ansible

log "Running Ansible playbook..."
cd ansible

log "Dry run first (--check mode)..."
ansible-playbook playbook.yml --check || warn "Check mode had issues — proceeding anyway"

log "Applying playbook..."
ansible-playbook playbook.yml

ok "Ansible complete."

# DONE

echo ""
echo -e "${GREEN}  ✅ PIPELINE COMPLETE!${NC}"
echo -e "${GREEN}  Visit: http://localhost:8080${NC}"
