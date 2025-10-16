# AI-LA Practical Usage Guide

## Quick Start (5 Minutes)

### Installation

```bash
# Download and run the deployment script
curl -fsSL https://raw.githubusercontent.com/resetroot99/ai-la/main/deploy-ai-la.sh | bash
```

That's it! The script handles everything automatically.

### First Use

```bash
# Restart your terminal, then:

# 1. Analyze your codebase
ai-la analyze ~/my-project

# 2. Learn your coding style
ai-la learn ~/my-project

# 3. Generate code
ai-la generate "Build a REST API for task management"

# 4. Start web interface
ai-la chat
```

---

## Detailed Usage

### 1. Code Archaeology - Understanding Existing Code

**What it does:** Analyzes your codebase to understand architecture, detect APIs, find security issues, and extract business logic.

**Basic usage:**

```bash
ai-la analyze /path/to/project
```

**Example output:**

```
Files analyzed: 56
API endpoints: 29
Security issues: 9 (1 critical)
Performance issues: 1
Business rules: 13
Quality score: 73.8/100 (Grade C)

Recommendations:
- Fix 9 security issues immediately
- Address 1 performance concerns
- Refactor 12 large files (>500 lines)
```

**Practical use cases:**

**Understanding a new codebase:**
```bash
# Just joined a team? Understand the codebase instantly
ai-la analyze ~/work/legacy-app

# AI-LA will tell you:
# - What framework it uses
# - All API endpoints
# - Database structure
# - Security issues
# - Code quality
```

**Before refactoring:**
```bash
# Know what you're dealing with
ai-la analyze ~/my-app

# AI-LA identifies:
# - Complex functions to simplify
# - Security vulnerabilities to fix
# - Performance bottlenecks
# - Technical debt
```

**Code review automation:**
```bash
# Analyze pull request changes
ai-la analyze ~/my-app/feature-branch

# AI-LA catches:
# - Security issues
# - Performance problems
# - Code quality issues
```

---

### 2. Adaptive Learning - Learning Your Style

**What it does:** Learns your coding style from existing code so AI-LA generates code that looks like you wrote it.

**Basic usage:**

```bash
ai-la learn /path/to/your/code
```

**Example output:**

```
Learned developer profile:
- Naming: snake_case
- Indentation: 4 spaces
- Quotes: single
- Line length: 88
- Comments: detailed
- Type hints: Yes
- Test style: pytest
- Confidence: 100%
```

**Practical use cases:**

**Personal projects:**
```bash
# Learn from your existing code
ai-la learn ~/my-projects

# Now AI-LA generates code in YOUR style
ai-la generate "Add user authentication"
# → Code matches your conventions perfectly
```

**Team projects:**
```bash
# Learn team conventions
ai-la learn ~/work/team-repo

# AI-LA adapts to team style
# Everyone's generated code looks consistent
```

**Multiple projects:**
```bash
# Learn from specific project
ai-la learn ~/work/project-a

# Generate code for that project
ai-la generate "Add payment processing"

# Later, switch to different project
ai-la learn ~/work/project-b

# AI-LA adapts to new style
```

---

### 3. Code Generation - Building Applications

**What it does:** Generates production-ready code based on natural language descriptions.

**Basic usage:**

```bash
ai-la generate "Your description here"
```

**Practical examples:**

**Simple API:**
```bash
ai-la generate "Build a REST API for task management with CRUD operations"

# Generates:
# - Flask/FastAPI application
# - Database models
# - API endpoints
# - Tests
# - Documentation
```

**With authentication:**
```bash
ai-la generate "Build a user authentication system with JWT tokens"

# Generates:
# - User model
# - Registration endpoint
# - Login endpoint
# - JWT token generation
# - Protected routes
# - Tests
```

**Microservice:**
```bash
ai-la generate "Build a payment processing microservice with Stripe integration"

# Generates:
# - Service architecture
# - Stripe integration
# - Webhook handling
# - Error handling
# - Tests
# - Docker configuration
```

**Full-stack app:**
```bash
ai-la generate "Build a blog platform with posts, comments, and user profiles"

# Generates:
# - Backend API
# - Database schema
# - Frontend components (if configured)
# - Authentication
# - Tests
# - Deployment config
```

---

### 4. Web Interface - Interactive Development

**What it does:** Provides a web-based chat interface for interactive development.

**Start the interface:**

```bash
ai-la chat
```

Then open: http://localhost:5001

**Features:**

- Real-time code generation
- TECP cryptographic verification
- Project management
- Analytics dashboard
- History tracking

**Practical workflow:**

1. Open web interface
2. Type: "Build a REST API for e-commerce"
3. Watch AI-LA generate code in real-time
4. See TECP receipts for verification
5. Download generated code
6. Deploy to production

---

## Real-World Workflows

### Workflow 1: Starting a New Project

```bash
# 1. Generate initial structure
ai-la generate "Build a SaaS application with user management and billing"

# 2. Review generated code
cd generated_app/
ls -la

# 3. Run tests
pytest

# 4. Start development server
python app.py

# 5. Deploy
docker-compose up
```

**Time: 5 minutes** (vs hours manually)

---

### Workflow 2: Adding Features to Existing Project

```bash
# 1. Analyze existing code
ai-la analyze ~/my-app

# 2. Learn existing style
ai-la learn ~/my-app

# 3. Generate new feature
ai-la generate "Add email notification system with templates"

# 4. AI-LA generates code matching your style
# 5. Copy generated code into your project
# 6. Run tests
# 7. Commit
```

**Time: 10 minutes** (vs hours manually)

---

### Workflow 3: Code Review and Security Audit

```bash
# 1. Analyze codebase
ai-la analyze ~/production-app

# 2. Review security issues
# AI-LA shows:
# - SQL injection risks
# - Hardcoded secrets
# - XSS vulnerabilities
# - Insecure dependencies

# 3. Fix issues
# 4. Re-analyze to verify
ai-la analyze ~/production-app

# 5. Quality score improved
```

**Time: 15 minutes** (vs days manually)

---

### Workflow 4: Team Onboarding

```bash
# New team member joins

# 1. Understand codebase
ai-la analyze ~/team-repo

# Output explains:
# - Architecture
# - All API endpoints
# - Database structure
# - Code patterns
# - Quality issues

# 2. Learn team style
ai-la learn ~/team-repo

# 3. Start contributing
ai-la generate "Add user profile page"

# Code matches team conventions automatically
```

**Time: 30 minutes** (vs weeks manually)

---

## Advanced Usage

### Custom Configuration

Create `~/.ai-la/config.json`:

```json
{
  "model": "qwen2.5-coder:32b",
  "style": {
    "naming": "snake_case",
    "indentation": 4,
    "quotes": "single",
    "line_length": 88
  },
  "features": {
    "tecp": true,
    "monitoring": true,
    "tests": true
  }
}
```

### Integration with VS Code

1. Open VS Code
2. Install AI-LA extension (if available)
3. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
4. Type "AI-LA"
5. Select command

**Commands:**
- AI-LA: Analyze Project
- AI-LA: Learn Style
- AI-LA: Generate Code
- AI-LA: Chat

### Integration with Git

Add pre-commit hook:

```bash
# .git/hooks/pre-commit
#!/bin/bash
ai-la analyze . --security-only
if [ $? -ne 0 ]; then
    echo "Security issues found! Commit blocked."
    exit 1
fi
```

### CI/CD Integration

**GitHub Actions:**

```yaml
name: AI-LA Security Scan
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install AI-LA
        run: curl -fsSL https://raw.githubusercontent.com/resetroot99/ai-la/main/deploy-ai-la.sh | bash
      - name: Security Scan
        run: ai-la analyze . --security-only
```

---

## Troubleshooting

### Ollama not starting

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# If not, start manually
ollama serve
```

### Model not found

```bash
# List installed models
ollama list

# Download model
ollama pull qwen2.5-coder:7b
```

### Python dependencies missing

```bash
# Install manually
pip3 install flask fastapi sqlalchemy requests
```

### VS Code extension not working

```bash
# Reinstall extension
rm -rf ~/.vscode/extensions/ai-la
bash deploy-ai-la.sh
```

---

## Performance Tips

### Faster Analysis

```bash
# Analyze specific directory only
ai-la analyze ~/my-app/src

# Skip tests directory
ai-la analyze ~/my-app --exclude tests
```

### Better Code Generation

```bash
# Provide more context
ai-la generate "Build a REST API for e-commerce with:
- Product catalog
- Shopping cart
- Checkout
- Payment processing (Stripe)
- Order management
- Email notifications"

# More detail = better code
```

### Team Collaboration

```bash
# Share learned profile
ai-la learn ~/team-repo --export team-style.json

# Team members import
ai-la learn --import team-style.json

# Everyone generates consistent code
```

---

## Best Practices

### 1. Always Analyze First

Before generating code for an existing project:

```bash
ai-la analyze ~/my-project
ai-la learn ~/my-project
ai-la generate "Add new feature"
```

### 2. Review Generated Code

AI-LA generates production-ready code, but always review:

```bash
# Generate
ai-la generate "Add authentication"

# Review
cd generated_app/
cat app.py
cat tests/test_app.py

# Test
pytest

# Deploy
```

### 3. Use TECP Verification

For critical code, verify with TECP:

```bash
# Generate with TECP
ai-la chat
# → Use web interface for TECP receipts

# Verify cryptographic proof
# → Check receipt hash and chain
```

### 4. Keep AI-LA Updated

```bash
# Update AI-LA
cd ~/.ai-la
git pull origin main

# Update model
ollama pull qwen2.5-coder:7b
```

---

## Cost Comparison

### AI-LA (Local)

- **Cost:** $0/month
- **Usage:** Unlimited
- **Privacy:** Complete (runs locally)
- **Speed:** Fast (local inference)

### Competitors

- **GitHub Copilot:** $10-19/month
- **Cursor:** $20/month
- **Replit Agent:** $20/month
- **Bolt.new:** $20/month

**Savings with AI-LA:** $240-480/year

---

## Support

### Documentation

- GitHub: https://github.com/resetroot99/ai-la
- Issues: https://github.com/resetroot99/ai-la/issues

### Community

- Discord: (coming soon)
- Reddit: r/aila (coming soon)

### Contributing

```bash
# Fork repository
# Make changes
# Submit pull request

# We welcome contributions!
```

---

## Summary

AI-LA is a complete autonomous development platform that:

1. **Understands your code** (Code Archaeology)
2. **Learns your style** (Adaptive Learning)
3. **Generates production-ready applications** (Code Generation)
4. **Costs $0** (runs locally)
5. **Works offline** (no internet required)

**Get started in 5 minutes:**

```bash
curl -fsSL https://raw.githubusercontent.com/resetroot99/ai-la/main/deploy-ai-la.sh | bash
ai-la generate "Build your first app"
```

**Welcome to autonomous development.**

