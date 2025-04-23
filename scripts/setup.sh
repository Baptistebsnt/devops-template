#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[!] $1${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root"
    exit 1
fi

# Check for required tools
required_tools=("docker" "docker-compose" "terraform" "aws")
for tool in "${required_tools[@]}"; do
    if ! command -v $tool &> /dev/null; then
        print_error "$tool is required but not installed"
        exit 1
    fi
done

# Create necessary directories
print_status "Creating project directories..."
mkdir -p terraform/{modules,environments/{dev,staging,prod}}
mkdir -p monitoring/{prometheus,grafana,logs,alerts}
mkdir -p scripts/{database,tests}

# Initialize Terraform
print_status "Initializing Terraform..."
cd terraform/environments/dev
terraform init
cd ../staging
terraform init
cd ../prod
terraform init
cd ../../..

# Set up monitoring stack
print_status "Setting up monitoring stack..."
cd monitoring
cp .env.example .env
docker-compose pull
docker-compose up -d
cd ..

# Configure AWS credentials
print_status "Configuring AWS credentials..."
if [ ! -f ~/.aws/credentials ]; then
    print_status "Please configure your AWS credentials:"
    aws configure
fi

# Create S3 bucket for Terraform state
print_status "Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
    --bucket devops-template-terraform-state \
    --region us-east-1 \
    --create-bucket-configuration LocationConstraint=us-east-1

# Create DynamoDB table for state locking
print_status "Creating DynamoDB table for state locking..."
aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Set up environment variables
print_status "Setting up environment variables..."
cat > .env << EOL
# Environment
ENVIRONMENT=dev
AWS_REGION=us-east-1

# Terraform
TF_VAR_aws_region=us-east-1
TF_VAR_environment=dev

# Monitoring
GRAFANA_ADMIN_PASSWORD=changeme
ELASTICSEARCH_HOST=elasticsearch
ELASTICSEARCH_PORT=9200
ELASTICSEARCH_USER=elastic
ELASTICSEARCH_PASSWORD=changeme
SLACK_API_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
EOL

print_status "Setup completed successfully!"
print_status "Please review and update the .env file with your specific values"
print_status "Next steps:"
print_status "1. Update the .env file with your credentials"
print_status "2. Run 'terraform plan' in each environment directory"
print_status "3. Run 'terraform apply' to create the infrastructure" 