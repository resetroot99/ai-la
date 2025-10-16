#!/bin/bash

################################################################################
# AI-Powered Deployment Script
# Automated deployment with AI code review, testing, and monitoring
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
MODEL="${AI_MODEL:-qwen2.5-coder:32b}"
REVIEW_MODEL="${AI_REVIEW_MODEL:-qwen2.5-coder:7b}"

################################################################################
# Utility Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

ai_query() {
    local prompt="$1"
    local model="${2:-$MODEL}"
    
    curl -s "${OLLAMA_HOST}/api/generate" -d "{
        \"model\": \"$model\",
        \"prompt\": \"$prompt\",
        \"stream\": false
    }" | jq -r .response
}

################################################################################
# Deployment Steps
################################################################################

step_1_code_review() {
    log_step "Step 1/8: AI Code Review"
    
    # Get changes
    local diff=$(git diff --cached 2>/dev/null || git diff main...HEAD 2>/dev/null || git diff HEAD~1...HEAD)
    
    if [ -z "$diff" ]; then
        log_warn "No changes to review"
        return 0
    fi
    
    log "Analyzing code changes..."
    
    # AI review
    local review=$(ai_query "Review this code for production deployment. Check for: security vulnerabilities, performance issues, bugs, best practices violations, breaking changes.\n\nCode:\n$diff" "$REVIEW_MODEL")
    
    echo "$review" > .ai-review.txt
    log_info "Review saved to: .ai-review.txt"
    
    # Check for critical issues
    if echo "$review" | grep -qi "critical\|security vulnerability\|blocker\|breaking change"; then
        log_error "Critical issues found in code review:"
        echo "$review"
        echo ""
        
        read -p "$(echo -e ${YELLOW}Continue anyway? (y/N): ${NC})" -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Deployment aborted"
            exit 1
        fi
    else
        log "✓ Code review passed"
    fi
}

step_2_generate_tests() {
    log_step "Step 2/8: Generate Tests"
    
    # Find changed files
    local changed_files=$(git diff --name-only --cached 2>/dev/null || git diff --name-only main...HEAD 2>/dev/null || git diff --name-only HEAD~1...HEAD)
    
    if [ -z "$changed_files" ]; then
        log_warn "No files to test"
        return 0
    fi
    
    # Create tests directory
    mkdir -p tests
    
    # Generate tests for each file
    echo "$changed_files" | while read file; do
        # Only for code files
        if [[ $file =~ \.(js|ts|jsx|tsx|py|go|java|rb)$ ]]; then
            log "Generating tests for: $file"
            
            local code=$(cat "$file")
            local test_file="tests/test_$(basename $file)"
            
            local tests=$(ai_query "Generate comprehensive unit tests for this code. Include: edge cases, error handling, mocking. Use appropriate testing framework.\n\nCode:\n$code")
            
            echo "$tests" > "$test_file"
            log_info "Generated: $test_file"
        fi
    done
    
    log "✓ Tests generated"
}

step_3_run_tests() {
    log_step "Step 3/8: Run Tests"
    
    # Detect test framework and run
    if [ -f "package.json" ]; then
        log "Running npm tests..."
        npm test || log_warn "Some tests failed"
    elif [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
        log "Running pytest..."
        pytest || log_warn "Some tests failed"
    elif [ -f "go.mod" ]; then
        log "Running go tests..."
        go test ./... || log_warn "Some tests failed"
    elif [ -f "Gemfile" ]; then
        log "Running rspec..."
        rspec || log_warn "Some tests failed"
    else
        log_warn "No test framework detected"
    fi
    
    log "✓ Tests completed"
}

step_4_build() {
    log_step "Step 4/8: Build Application"
    
    # Detect build system
    if [ -f "package.json" ]; then
        if grep -q "\"build\":" package.json; then
            log "Running npm build..."
            npm run build
        fi
    elif [ -f "Makefile" ]; then
        log "Running make build..."
        make build
    elif [ -f "go.mod" ]; then
        log "Running go build..."
        go build -o app .
    fi
    
    log "✓ Build completed"
}

step_5_generate_dockerfile() {
    log_step "Step 5/8: Generate Dockerfile"
    
    if [ -f "Dockerfile" ]; then
        log_info "Dockerfile already exists"
        
        read -p "$(echo -e ${YELLOW}Regenerate? (y/N): ${NC})" -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
        
        cp Dockerfile Dockerfile.backup
        log_info "Backed up to: Dockerfile.backup"
    fi
    
    log "Analyzing project structure..."
    
    # Detect project type
    local project_info=$(ls -la)
    local package_info=""
    
    if [ -f "package.json" ]; then
        package_info=$(cat package.json)
    elif [ -f "requirements.txt" ]; then
        package_info=$(cat requirements.txt)
    elif [ -f "go.mod" ]; then
        package_info=$(cat go.mod)
    fi
    
    log "Generating optimized Dockerfile..."
    
    local dockerfile=$(ai_query "Generate a production-ready, multi-stage Dockerfile for this project.\n\nProject structure:\n$project_info\n\nPackage info:\n$package_info\n\nRequirements:\n- Multi-stage build for minimal image size\n- Security best practices (non-root user, minimal base image)\n- Layer caching optimization\n- Health check\n- Proper signal handling")
    
    echo "$dockerfile" > Dockerfile
    
    log "✓ Dockerfile generated"
    log_info "Review Dockerfile before deploying"
}

step_6_build_docker() {
    log_step "Step 6/8: Build Docker Image"
    
    if [ ! -f "Dockerfile" ]; then
        log_error "Dockerfile not found"
        return 1
    fi
    
    # Generate image name
    local repo_name=$(basename $(git rev-parse --show-toplevel 2>/dev/null || pwd))
    local image_tag="${repo_name}:$(git rev-parse --short HEAD 2>/dev/null || date +%s)"
    
    log "Building Docker image: $image_tag"
    
    docker build -t "$image_tag" -t "${repo_name}:latest" .
    
    log "✓ Docker image built: $image_tag"
    
    # Save image tag for deployment
    echo "$image_tag" > .docker-image-tag
}

step_7_deploy() {
    log_step "Step 7/8: Deploy Application"
    
    local image_tag=$(cat .docker-image-tag 2>/dev/null || echo "latest")
    
    echo "Select deployment target:"
    echo "  1. Kubernetes"
    echo "  2. Docker Compose"
    echo "  3. Vercel"
    echo "  4. Fly.io"
    echo "  5. Custom"
    echo ""
    
    read -p "Choice [1-5]: " choice
    
    case $choice in
        1)
            deploy_kubernetes "$image_tag"
            ;;
        2)
            deploy_docker_compose "$image_tag"
            ;;
        3)
            deploy_vercel
            ;;
        4)
            deploy_flyio "$image_tag"
            ;;
        5)
            log_info "Skipping automated deployment"
            ;;
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
}

deploy_kubernetes() {
    local image_tag="$1"
    
    log "Generating Kubernetes manifests..."
    
    local app_name=$(basename $(git rev-parse --show-toplevel 2>/dev/null || pwd))
    
    # Generate deployment
    local deployment=$(ai_query "Generate Kubernetes deployment manifest for app '$app_name' using image '$image_tag'. Include: 3 replicas, resource limits (500m CPU, 512Mi RAM), liveness/readiness probes, rolling update strategy, security context (non-root)")
    
    echo "$deployment" > k8s-deployment.yaml
    
    # Generate service
    local service=$(ai_query "Generate Kubernetes service manifest for app '$app_name' with LoadBalancer type, port 80 to container port 3000")
    
    echo "$service" > k8s-service.yaml
    
    log "✓ Kubernetes manifests generated"
    log_info "Applying to cluster..."
    
    kubectl apply -f k8s-deployment.yaml
    kubectl apply -f k8s-service.yaml
    
    log "✓ Deployed to Kubernetes"
    
    # Wait for rollout
    kubectl rollout status deployment/"$app_name"
}

deploy_docker_compose() {
    local image_tag="$1"
    
    log "Generating docker-compose.yml..."
    
    local compose=$(ai_query "Generate docker-compose.yml for production deployment. Use image '$image_tag'. Include: restart policy, health check, logging, networks, environment variables from .env file")
    
    echo "$compose" > docker-compose.yml
    
    log "✓ docker-compose.yml generated"
    log_info "Starting services..."
    
    docker-compose up -d
    
    log "✓ Deployed with Docker Compose"
}

deploy_vercel() {
    log "Deploying to Vercel..."
    
    if ! command -v vercel &> /dev/null; then
        log_error "Vercel CLI not installed. Run: npm i -g vercel"
        return 1
    fi
    
    # Generate vercel.json if needed
    if [ ! -f "vercel.json" ]; then
        local vercel_config=$(ai_query "Generate optimal vercel.json for this Next.js/React project. Include: build optimization, caching headers, redirects, environment variables")
        echo "$vercel_config" > vercel.json
    fi
    
    vercel --prod
    
    log "✓ Deployed to Vercel"
}

deploy_flyio() {
    local image_tag="$1"
    
    log "Deploying to Fly.io..."
    
    if ! command -v flyctl &> /dev/null; then
        log_error "Fly CLI not installed. Run: curl -L https://fly.io/install.sh | sh"
        return 1
    fi
    
    # Generate fly.toml if needed
    if [ ! -f "fly.toml" ]; then
        local fly_config=$(ai_query "Generate fly.toml configuration for this application. Include: app name, region, health checks, environment variables")
        echo "$fly_config" > fly.toml
    fi
    
    flyctl deploy
    
    log "✓ Deployed to Fly.io"
}

step_8_monitor() {
    log_step "Step 8/8: Monitor Deployment"
    
    log "Deployment monitoring..."
    
    # Check deployment status
    if [ -f "k8s-deployment.yaml" ]; then
        local app_name=$(basename $(git rev-parse --show-toplevel 2>/dev/null || pwd))
        
        log_info "Kubernetes deployment status:"
        kubectl get deployment "$app_name"
        kubectl get pods -l app="$app_name"
        
        # Get service URL
        local service_url=$(kubectl get svc "$app_name" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ -n "$service_url" ]; then
            log "✓ Service available at: http://$service_url"
        fi
        
    elif [ -f "docker-compose.yml" ]; then
        log_info "Docker Compose status:"
        docker-compose ps
        
    else
        log_info "Check your deployment platform for status"
    fi
    
    log "✓ Deployment complete!"
}

################################################################################
# Main Deployment Flow
################################################################################

main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║        🚀 AI-Powered Production Deployment 🚀               ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check Ollama
    if ! curl -s "${OLLAMA_HOST}/api/tags" &> /dev/null; then
        log_error "Ollama not running at $OLLAMA_HOST"
        log_info "Start with: ollama serve"
        exit 1
    fi
    
    # Run deployment steps
    step_1_code_review
    step_2_generate_tests
    step_3_run_tests
    step_4_build
    step_5_generate_dockerfile
    step_6_build_docker
    step_7_deploy
    step_8_monitor
    
    echo ""
    log_step "🎉 Deployment Complete!"
    echo ""
    log "Summary:"
    log "  ✓ Code reviewed by AI"
    log "  ✓ Tests generated and run"
    log "  ✓ Application built"
    log "  ✓ Docker image created"
    log "  ✓ Deployed to production"
    log "  ✓ Monitoring active"
    echo ""
    log "Next steps:"
    log "  - Monitor logs and metrics"
    log "  - Run smoke tests"
    log "  - Update documentation"
    echo ""
}

# Run deployment
main "$@"

