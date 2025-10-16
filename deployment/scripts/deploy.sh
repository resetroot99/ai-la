#!/bin/bash
# AI-LA Complete Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-production}
AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME="ai-la-cluster"

echo -e "${GREEN}AI-LA Deployment Script${NC}"
echo -e "${GREEN}Environment: ${ENVIRONMENT}${NC}"
echo ""

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    command -v terraform >/dev/null 2>&1 || { echo -e "${RED}terraform is required${NC}"; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}kubectl is required${NC}"; exit 1; }
    command -v aws >/dev/null 2>&1 || { echo -e "${RED}aws cli is required${NC}"; exit 1; }
    command -v docker >/dev/null 2>&1 || { echo -e "${RED}docker is required${NC}"; exit 1; }
    
    echo -e "${GREEN}All prerequisites met${NC}"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    echo -e "${YELLOW}Deploying infrastructure with Terraform...${NC}"
    
    cd ../terraform
    
    terraform init
    terraform plan -out=tfplan
    
    read -p "Apply Terraform plan? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        terraform apply tfplan
        echo -e "${GREEN}Infrastructure deployed${NC}"
    else
        echo -e "${RED}Deployment cancelled${NC}"
        exit 1
    fi
    
    # Save outputs
    terraform output -json > outputs.json
    
    cd ../scripts
}

# Configure kubectl
configure_kubectl() {
    echo -e "${YELLOW}Configuring kubectl...${NC}"
    
    aws eks update-kubeconfig \
        --region ${AWS_REGION} \
        --name ${CLUSTER_NAME}
    
    kubectl cluster-info
    echo -e "${GREEN}kubectl configured${NC}"
}

# Create Kubernetes namespace
create_namespace() {
    echo -e "${YELLOW}Creating Kubernetes namespace...${NC}"
    
    kubectl create namespace ai-la --dry-run=client -o yaml | kubectl apply -f -
    
    echo -e "${GREEN}Namespace created${NC}"
}

# Create secrets
create_secrets() {
    echo -e "${YELLOW}Creating Kubernetes secrets...${NC}"
    
    # Generate JWT secret
    JWT_SECRET=$(openssl rand -base64 32)
    
    # Get database URL from Terraform output
    DB_ENDPOINT=$(cd ../terraform && terraform output -raw rds_endpoint)
    DB_PASSWORD=$(cd ../terraform && terraform output -raw db_password)
    DATABASE_URL="postgresql://ailaadmin:${DB_PASSWORD}@${DB_ENDPOINT}/aila"
    
    # Get Redis URL
    REDIS_ENDPOINT=$(cd ../terraform && terraform output -raw redis_endpoint)
    REDIS_URL="redis://${REDIS_ENDPOINT}:6379"
    
    # Prompt for Stripe API key
    read -p "Enter Stripe API key: " STRIPE_API_KEY
    
    # Create secret
    kubectl create secret generic ai-la-secrets \
        --from-literal=database-url="${DATABASE_URL}" \
        --from-literal=redis-url="${REDIS_URL}" \
        --from-literal=jwt-secret="${JWT_SECRET}" \
        --from-literal=stripe-api-key="${STRIPE_API_KEY}" \
        --namespace=ai-la \
        --dry-run=client -o yaml | kubectl apply -f -
    
    echo -e "${GREEN}Secrets created${NC}"
}

# Build and push Docker images
build_images() {
    echo -e "${YELLOW}Building Docker images...${NC}"
    
    # API Gateway
    docker build -t registry.ai-la.dev/ai-la-api:latest ../../ai-la-chat-app
    docker push registry.ai-la.dev/ai-la-api:latest
    
    # Inference Service
    docker build -t registry.ai-la.dev/ai-la-inference:latest ../../
    docker push registry.ai-la.dev/ai-la-inference:latest
    
    # TECP Service
    docker build -t registry.ai-la.dev/ai-la-tecp:latest ../../
    docker push registry.ai-la.dev/ai-la-tecp:latest
    
    echo -e "${GREEN}Images built and pushed${NC}"
}

# Deploy to Kubernetes
deploy_kubernetes() {
    echo -e "${YELLOW}Deploying to Kubernetes...${NC}"
    
    kubectl apply -f ../kubernetes/api-deployment.yaml
    
    echo -e "${GREEN}Kubernetes deployment complete${NC}"
}

# Wait for deployments
wait_for_deployments() {
    echo -e "${YELLOW}Waiting for deployments to be ready...${NC}"
    
    kubectl wait --for=condition=available --timeout=300s \
        deployment/ai-la-api \
        deployment/ai-la-inference \
        deployment/ai-la-tecp \
        -n ai-la
    
    echo -e "${GREEN}All deployments ready${NC}"
}

# Run database migrations
run_migrations() {
    echo -e "${YELLOW}Running database migrations...${NC}"
    
    # Get a pod name
    POD=$(kubectl get pods -n ai-la -l app=ai-la-api -o jsonpath='{.items[0].metadata.name}')
    
    # Run migrations
    kubectl exec -n ai-la ${POD} -- python -m alembic upgrade head
    
    echo -e "${GREEN}Migrations complete${NC}"
}

# Verify deployment
verify_deployment() {
    echo -e "${YELLOW}Verifying deployment...${NC}"
    
    # Get service endpoints
    kubectl get services -n ai-la
    kubectl get ingress -n ai-la
    
    # Check pod status
    kubectl get pods -n ai-la
    
    # Test API health
    API_URL=$(kubectl get ingress -n ai-la ai-la-ingress -o jsonpath='{.spec.rules[0].host}')
    
    echo -e "${YELLOW}Testing API health at https://${API_URL}/health${NC}"
    curl -f https://${API_URL}/health || echo -e "${RED}Health check failed${NC}"
    
    echo -e "${GREEN}Deployment verified${NC}"
}

# Main deployment flow
main() {
    check_prerequisites
    
    echo -e "${YELLOW}Starting deployment...${NC}"
    
    deploy_infrastructure
    configure_kubectl
    create_namespace
    create_secrets
    build_images
    deploy_kubernetes
    wait_for_deployments
    run_migrations
    verify_deployment
    
    echo -e "${GREEN}Deployment complete!${NC}"
    echo -e "${GREEN}API URL: https://api.ai-la.dev${NC}"
    echo -e "${GREEN}Web App: https://app.ai-la.dev${NC}"
}

# Run main function
main

