# Production DevOps Integration

## Complete Development to Deployment Workflow

This guide integrates the AI coding stack with production-grade DevOps tools for shipping real applications.

##  Overview

Transform your AI coding stack into a **complete production pipeline**:

```
AI Code Generation → Git → CI/CD → Testing → Deployment → Monitoring
```

## 1. Git Integration

### Automatic Git Workflow

**AI-Powered Git Commands**

```bash
# Install Git integration
cat > ~/.continue/config.json << 'EOF'
{
  "customCommands": [
    {
      "name": "Smart Commit",
      "prompt": "Analyze the git diff and generate a conventional commit message with type, scope, and description. Then execute: git add -A && git commit -m '<message>'"
    },
    {
      "name": "Generate PR Description",
      "prompt": "Analyze git diff between current branch and main. Generate a comprehensive PR description with: summary, changes, testing done, and checklist."
    },
    {
      "name": "Code Review",
      "prompt": "Review the git diff for: bugs, security issues, performance problems, best practices violations. Provide actionable feedback."
    }
  ]
}
EOF
```

### Git Hooks with AI

**Pre-commit Hook (AI Code Review)**

```bash
# .git/hooks/pre-commit
#!/bin/bash

echo " Running AI code review..."

# Get staged changes
DIFF=$(git diff --cached)

# AI review via Ollama
REVIEW=$(curl -s http://localhost:11434/api/generate -d "{
  \"model\": \"qwen2.5-coder:32b\",
  \"prompt\": \"Review this code for bugs, security issues, and best practices:\n\n$DIFF\",
  \"stream\": false
}" | jq -r .response)

# Check for critical issues
if echo "$REVIEW" | grep -qi "critical\|security\|vulnerability"; then
    echo " AI found critical issues:"
    echo "$REVIEW"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo " AI review passed"
```

**Commit Message Generation**

```bash
# .git/hooks/prepare-commit-msg
#!/bin/bash

COMMIT_MSG_FILE=$1

# Get staged diff
DIFF=$(git diff --cached)

# Generate commit message
MSG=$(curl -s http://localhost:11434/api/generate -d "{
  \"model\": \"qwen2.5-coder:7b\",
  \"prompt\": \"Generate a conventional commit message for:\n\n$DIFF\n\nFormat: type(scope): description\",
  \"stream\": false
}" | jq -r .response)

# Prepend to commit message
echo "$MSG" > "$COMMIT_MSG_FILE.tmp"
cat "$COMMIT_MSG_FILE" >> "$COMMIT_MSG_FILE.tmp"
mv "$COMMIT_MSG_FILE.tmp" "$COMMIT_MSG_FILE"
```

### Branch Management

**AI-Powered Branch Strategy**

```bash
# Create feature branch with AI-generated name
ai-branch() {
    local description="$1"
    
    local branch_name=$(curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:7b\",
        \"prompt\": \"Generate a git branch name for: $description. Format: feature/short-kebab-case\",
        \"stream\": false
    }" | jq -r .response | head -1)
    
    git checkout -b "$branch_name"
    echo "Created branch: $branch_name"
}

# Usage
ai-branch "add user authentication with JWT"
# Creates: feature/add-jwt-authentication
```

## 2. CI/CD Integration

### GitHub Actions with AI

**.github/workflows/ai-review.yml**

```yaml
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Setup Ollama
        run: |
          curl -fsSL https://ollama.com/install.sh | sh
          ollama serve &
          sleep 5
          ollama pull qwen2.5-coder:7b
      
      - name: AI Code Review
        run: |
          DIFF=$(git diff origin/main...HEAD)
          
          REVIEW=$(curl -s http://localhost:11434/api/generate -d "{
            \"model\": \"qwen2.5-coder:7b\",
            \"prompt\": \"Review this PR for: bugs, security, performance, best practices:\n\n$DIFF\",
            \"stream\": false
          }" | jq -r .response)
          
          echo "##  AI Code Review" >> review.md
          echo "" >> review.md
          echo "$REVIEW" >> review.md
          
          gh pr comment ${{ github.event.pull_request.number }} --body-file review.md
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### GitLab CI with AI

**.gitlab-ci.yml**

```yaml
stages:
  - review
  - test
  - deploy

ai-review:
  stage: review
  image: ubuntu:22.04
  script:
    - curl -fsSL https://ollama.com/install.sh | sh
    - ollama serve &
    - sleep 5
    - ollama pull qwen2.5-coder:7b
    - |
      DIFF=$(git diff $CI_MERGE_REQUEST_DIFF_BASE_SHA...$CI_COMMIT_SHA)
      REVIEW=$(curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:7b\",
        \"prompt\": \"Review: $DIFF\",
        \"stream\": false
      }" | jq -r .response)
      echo "$REVIEW" > review.txt
  artifacts:
    paths:
      - review.txt
  only:
    - merge_requests
```

### AI-Generated Tests

**Auto-generate tests in CI**

```yaml
# .github/workflows/generate-tests.yml
name: Generate Tests

on:
  push:
    branches: [main, develop]

jobs:
  generate-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Ollama
        run: |
          curl -fsSL https://ollama.com/install.sh | sh
          ollama serve &
          ollama pull qwen2.5-coder:32b
      
      - name: Generate Tests
        run: |
          for file in $(git diff --name-only HEAD~1 HEAD | grep '\.py$\|\.js$\|\.ts$'); do
            CODE=$(cat "$file")
            
            TESTS=$(curl -s http://localhost:11434/api/generate -d "{
              \"model\": \"qwen2.5-coder:32b\",
              \"prompt\": \"Generate comprehensive unit tests for:\n\n$CODE\",
              \"stream\": false
            }" | jq -r .response)
            
            echo "$TESTS" > "tests/test_$(basename $file)"
          done
      
      - name: Create PR
        run: |
          git checkout -b auto-tests-$(date +%s)
          git add tests/
          git commit -m "test: auto-generated tests"
          git push origin HEAD
          gh pr create --title "Auto-generated tests" --body "AI-generated tests"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 3. Deployment Integration

### Vercel Deployment

**AI-Optimized Deployment**

```bash
# Install Vercel CLI
npm i -g vercel

# AI deployment script
cat > deploy-ai.sh << 'EOF'
#!/bin/bash

echo " AI-powered deployment starting..."

# AI analyzes project and suggests deployment config
PROJECT_TYPE=$(curl -s http://localhost:11434/api/generate -d "{
  \"model\": \"qwen2.5-coder:7b\",
  \"prompt\": \"Analyze this project structure and determine type (Next.js, React, Node.js, etc):\n\n$(ls -la)\",
  \"stream\": false
}" | jq -r .response)

echo "Detected: $PROJECT_TYPE"

# Generate vercel.json
VERCEL_CONFIG=$(curl -s http://localhost:11434/api/generate -d "{
  \"model\": \"qwen2.5-coder:32b\",
  \"prompt\": \"Generate optimal vercel.json for $PROJECT_TYPE with: build optimization, caching, redirects, headers\",
  \"stream\": false
}" | jq -r .response)

echo "$VERCEL_CONFIG" > vercel.json

# Deploy
vercel --prod
EOF

chmod +x deploy-ai.sh
```

### Docker Integration

**AI-Generated Dockerfiles**

```bash
# Generate optimized Dockerfile
ai-docker() {
    local project_type="$1"
    
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Generate a production-ready, multi-stage Dockerfile for $project_type with: security best practices, layer caching, minimal image size\",
        \"stream\": false
    }" | jq -r .response > Dockerfile
    
    echo " Dockerfile generated"
}

# Generate docker-compose.yml
ai-compose() {
    local services="$1"
    
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Generate docker-compose.yml for: $services. Include: health checks, networks, volumes, environment variables\",
        \"stream\": false
    }" | jq -r .response > docker-compose.yml
    
    echo " docker-compose.yml generated"
}

# Usage
ai-docker "Node.js Express API with PostgreSQL"
ai-compose "Next.js frontend, Express API, PostgreSQL, Redis"
```

### Kubernetes Deployment

**AI-Generated K8s Manifests**

```bash
# Generate Kubernetes manifests
ai-k8s() {
    local app_name="$1"
    local replicas="${2:-3}"
    
    # Generate deployment
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Generate Kubernetes deployment manifest for $app_name with $replicas replicas. Include: resource limits, health checks, rolling updates, security context\",
        \"stream\": false
    }" | jq -r .response > k8s-deployment.yaml
    
    # Generate service
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Generate Kubernetes service manifest for $app_name with LoadBalancer type\",
        \"stream\": false
    }" | jq -r .response > k8s-service.yaml
    
    # Generate ingress
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Generate Kubernetes ingress manifest for $app_name with TLS and rate limiting\",
        \"stream\": false
    }" | jq -r .response > k8s-ingress.yaml
    
    echo " Kubernetes manifests generated"
}

# Deploy
ai-k8s "my-app" 5
kubectl apply -f k8s-*.yaml
```

## 4. Terminal Integration

### Warp Terminal with AI

**Install Warp (AI-native terminal)**

```bash
# macOS
brew install --cask warp

# Linux (download from warp.dev)
```

**Configure AI workflows**

```bash
# ~/.warp/workflows/ai-deploy.yaml
name: AI Deploy
command: |
  echo " Starting AI deployment..."
  ./deploy-ai.sh
description: Deploy with AI optimization
```

### Tmux with AI

**AI-powered tmux sessions**

```bash
# ~/.tmux.conf
bind-key C-a run-shell "tmux split-window -h 'ollama run qwen2.5-coder:7b'"

# AI command suggestion
bind-key C-s run-shell "tmux display-popup -E 'ai-suggest-command'"
```

**AI command suggestion script**

```bash
# ~/bin/ai-suggest-command
#!/bin/bash

read -p "What do you want to do? " task

COMMAND=$(curl -s http://localhost:11434/api/generate -d "{
  \"model\": \"qwen2.5-coder:7b\",
  \"prompt\": \"Generate a single terminal command for: $task. Output only the command, no explanation.\",
  \"stream\": false
}" | jq -r .response)

echo "Suggested: $COMMAND"
read -p "Execute? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    eval "$COMMAND"
fi
```

### Zsh/Bash Integration

**AI-powered shell functions**

```bash
# ~/.zshrc or ~/.bashrc

# AI command explanation
explain() {
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:7b\",
        \"prompt\": \"Explain this command: $*\",
        \"stream\": false
    }" | jq -r .response
}

# AI fix last command
fix() {
    local last_cmd=$(fc -ln -1)
    local error="$1"
    
    local fixed=$(curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:7b\",
        \"prompt\": \"Fix this command that failed with '$error': $last_cmd\",
        \"stream\": false
    }" | jq -r .response)
    
    echo "Fixed: $fixed"
    eval "$fixed"
}

# AI generate script
genscript() {
    local description="$*"
    
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Generate a bash script for: $description. Include error handling and comments.\",
        \"stream\": false
    }" | jq -r .response > script.sh
    
    chmod +x script.sh
    echo " Generated: script.sh"
}
```

## 5. Server Management

### SSH with AI

**AI-powered server management**

```bash
# ~/bin/ai-ssh
#!/bin/bash

SERVER="$1"
TASK="$2"

# Generate commands for task
COMMANDS=$(curl -s http://localhost:11434/api/generate -d "{
  \"model\": \"qwen2.5-coder:32b\",
  \"prompt\": \"Generate bash commands to $TASK on Ubuntu server. Include error handling.\",
  \"stream\": false
}" | jq -r .response)

echo "Will execute on $SERVER:"
echo "$COMMANDS"
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh "$SERVER" "$COMMANDS"
fi

# Usage
# ai-ssh user@server "setup nginx with SSL for domain.com"
```

### Infrastructure as Code

**AI-Generated Terraform**

```bash
# Generate Terraform config
ai-terraform() {
    local infrastructure="$1"
    
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Generate Terraform configuration for: $infrastructure. Include: provider, resources, variables, outputs, best practices\",
        \"stream\": false
    }" | jq -r .response > main.tf
    
    echo " Terraform config generated"
    terraform fmt
    terraform validate
}

# Usage
ai-terraform "AWS ECS cluster with ALB, RDS PostgreSQL, ElastiCache Redis"
```

**AI-Generated Ansible**

```bash
# Generate Ansible playbook
ai-ansible() {
    local task="$1"
    
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Generate Ansible playbook for: $task. Include: handlers, variables, error handling, idempotency\",
        \"stream\": false
    }" | jq -r .response > playbook.yml
    
    echo " Ansible playbook generated"
    ansible-playbook --syntax-check playbook.yml
}

# Usage
ai-ansible "deploy Node.js app with PM2, Nginx, SSL"
```

## 6. Monitoring & Observability

### AI-Powered Log Analysis

```bash
# Analyze logs with AI
ai-logs() {
    local log_file="$1"
    local lines="${2:-100}"
    
    local logs=$(tail -n "$lines" "$log_file")
    
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Analyze these logs for: errors, patterns, security issues, performance problems:\n\n$logs\",
        \"stream\": false
    }" | jq -r .response
}

# Usage
ai-logs /var/log/nginx/error.log 200
```

### Performance Analysis

```bash
# AI performance recommendations
ai-perf() {
    local app_type="$1"
    
    # Gather metrics
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    local mem=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
    local disk=$(df -h / | awk 'NR==2{print $5}')
    
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Analyze performance metrics for $app_type:\nCPU: $cpu\nMemory: $mem\nDisk: $disk\n\nProvide optimization recommendations.\",
        \"stream\": false
    }" | jq -r .response
}
```

## 7. Complete Production Workflow

### End-to-End Pipeline

```bash
#!/bin/bash
# production-pipeline.sh

set -e

echo " AI-Powered Production Pipeline"
echo "=================================="

# 1. Code Review
echo " Step 1: AI Code Review..."
DIFF=$(git diff main...HEAD)
REVIEW=$(curl -s http://localhost:11434/api/generate -d "{
  \"model\": \"qwen2.5-coder:32b\",
  \"prompt\": \"Review for production: $DIFF\",
  \"stream\": false
}" | jq -r .response)

if echo "$REVIEW" | grep -qi "critical\|blocker"; then
    echo " Critical issues found. Aborting."
    exit 1
fi

# 2. Generate Tests
echo " Step 2: Generating tests..."
for file in $(git diff --name-only main...HEAD); do
    if [[ $file =~ \.(js|ts|py)$ ]]; then
        CODE=$(cat "$file")
        TESTS=$(curl -s http://localhost:11434/api/generate -d "{
          \"model\": \"qwen2.5-coder:32b\",
          \"prompt\": \"Generate tests: $CODE\",
          \"stream\": false
        }" | jq -r .response)
        echo "$TESTS" > "tests/test_$(basename $file)"
    fi
done

# 3. Run Tests
echo " Step 3: Running tests..."
npm test || pytest || go test ./...

# 4. Build
echo " Step 4: Building..."
npm run build || make build

# 5. Generate Dockerfile
echo " Step 5: Generating Dockerfile..."
curl -s http://localhost:11434/api/generate -d "{
  \"model\": \"qwen2.5-coder:32b\",
  \"prompt\": \"Generate production Dockerfile for this project: $(ls -la)\",
  \"stream\": false
}" | jq -r .response > Dockerfile

# 6. Build Docker image
echo " Step 6: Building Docker image..."
docker build -t myapp:latest .

# 7. Deploy
echo " Step 7: Deploying..."
kubectl set image deployment/myapp myapp=myapp:latest

# 8. Monitor
echo " Step 8: Monitoring deployment..."
kubectl rollout status deployment/myapp

echo " Deployment complete!"
```

### VSCode Integration

**tasks.json with AI**

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "AI Deploy",
      "type": "shell",
      "command": "./production-pipeline.sh",
      "problemMatcher": []
    },
    {
      "label": "AI Code Review",
      "type": "shell",
      "command": "git diff | curl -s http://localhost:11434/api/generate -d @- | jq -r .response",
      "problemMatcher": []
    },
    {
      "label": "Generate Tests",
      "type": "shell",
      "command": "ai-generate-tests ${file}",
      "problemMatcher": []
    }
  ]
}
```

## 8. Database Integration

### AI-Powered Database Management

```bash
# Generate migrations
ai-migration() {
    local description="$1"
    
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Generate database migration for: $description. Include: up and down migrations, indexes, constraints\",
        \"stream\": false
    }" | jq -r .response > "migrations/$(date +%s)_${description// /_}.sql"
}

# Optimize queries
ai-optimize-query() {
    local query="$1"
    
    curl -s http://localhost:11434/api/generate -d "{
        \"model\": \"qwen2.5-coder:32b\",
        \"prompt\": \"Optimize this SQL query: $query. Explain improvements.\",
        \"stream\": false
    }" | jq -r .response
}
```

## Summary

### Complete DevOps Stack

 **Git Integration** - AI commits, reviews, branch management  
 **CI/CD** - GitHub Actions, GitLab CI with AI  
 **Deployment** - Vercel, Docker, Kubernetes with AI  
 **Terminal** - Warp, tmux, shell integration  
 **Servers** - SSH, Terraform, Ansible with AI  
 **Monitoring** - Log analysis, performance tuning  
 **Database** - Migrations, query optimization  

### Production Pipeline

```
Code → AI Review → Tests → Build → Docker → Deploy → Monitor
```

**All powered by AI, all automated, all production-ready.** 

