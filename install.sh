#!/bin/bash

################################################################################
# Ultimate AI Coding Stack - Automated Installer
# Version: 1.0.0
# Description: Installs and configures a complete AI coding environment
# with failsafes, health checks, and automatic recovery
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="${HOME}/.ai-coding-stack"
LOG_FILE="${INSTALL_DIR}/install.log"
CONFIG_FILE="${INSTALL_DIR}/config.json"
BACKUP_DIR="${INSTALL_DIR}/backups"

# System requirements
MIN_RAM_GB=8
MIN_DISK_GB=20
REQUIRED_TOOLS=("curl" "git" "jq")

################################################################################
# Utility Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        log "✓ $1 is installed"
        return 0
    else
        log_error "✗ $1 is not installed"
        return 1
    fi
}

create_backup() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup_file="${BACKUP_DIR}/$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$backup_file"
        log "Backed up $file to $backup_file"
    fi
}

################################################################################
# System Checks
################################################################################

check_system_requirements() {
    print_header "Checking System Requirements"
    
    local checks_passed=true
    
    # Check OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log "✓ Operating System: Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log "✓ Operating System: macOS"
    else
        log_error "✗ Unsupported operating system: $OSTYPE"
        checks_passed=false
    fi
    
    # Check RAM
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        total_ram=$(free -g | awk '/^Mem:/{print $2}')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        total_ram=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    fi
    
    if [ "$total_ram" -ge "$MIN_RAM_GB" ]; then
        log "✓ RAM: ${total_ram}GB (minimum: ${MIN_RAM_GB}GB)"
    else
        log_warning "⚠ RAM: ${total_ram}GB (recommended: ${MIN_RAM_GB}GB+)"
    fi
    
    # Check disk space
    available_disk=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_disk" -ge "$MIN_DISK_GB" ]; then
        log "✓ Disk Space: ${available_disk}GB available (minimum: ${MIN_DISK_GB}GB)"
    else
        log_error "✗ Insufficient disk space: ${available_disk}GB (minimum: ${MIN_DISK_GB}GB)"
        checks_passed=false
    fi
    
    # Check for required tools
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! check_command "$tool"; then
            log_error "Please install $tool first"
            checks_passed=false
        fi
    done
    
    # Check for GPU (optional)
    if command -v nvidia-smi &> /dev/null; then
        gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | head -1)
        log "✓ GPU detected: $gpu_info"
        echo "GPU_AVAILABLE=true" >> "$CONFIG_FILE"
    else
        log_info "No NVIDIA GPU detected (will use CPU mode)"
        echo "GPU_AVAILABLE=false" >> "$CONFIG_FILE"
    fi
    
    if [ "$checks_passed" = false ]; then
        log_error "System requirements check failed. Please fix the issues above."
        exit 1
    fi
    
    log "✓ All system requirements met"
}

################################################################################
# Ollama Installation
################################################################################

install_ollama() {
    print_header "Installing Ollama"
    
    if check_command "ollama"; then
        log "Ollama is already installed"
        ollama --version
        return 0
    fi
    
    log "Installing Ollama..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
        if curl -fsSL https://ollama.com/install.sh | sh; then
            log "✓ Ollama installed successfully"
        else
            log_error "Failed to install Ollama"
            return 1
        fi
    else
        log_error "Please install Ollama manually from https://ollama.com"
        return 1
    fi
    
    # Verify installation
    if check_command "ollama"; then
        log "✓ Ollama installation verified"
        return 0
    else
        log_error "Ollama installation failed verification"
        return 1
    fi
}

check_ollama_service() {
    log "Checking Ollama service..."
    
    # Try to connect to Ollama
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        log "✓ Ollama service is running"
        return 0
    else
        log_warning "Ollama service is not running. Starting it..."
        
        # Start Ollama in background
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open -a Ollama 2>/dev/null || ollama serve &> /dev/null &
        else
            ollama serve &> /dev/null &
        fi
        
        # Wait for service to start
        local max_attempts=10
        local attempt=0
        while [ $attempt -lt $max_attempts ]; do
            if curl -s http://localhost:11434/api/tags &> /dev/null; then
                log "✓ Ollama service started successfully"
                return 0
            fi
            sleep 2
            ((attempt++))
        done
        
        log_error "Failed to start Ollama service"
        return 1
    fi
}

################################################################################
# Model Installation
################################################################################

get_installed_models() {
    curl -s http://localhost:11434/api/tags | jq -r '.models[].name' 2>/dev/null || echo ""
}

check_model_installed() {
    local model="$1"
    local installed_models=$(get_installed_models)
    
    if echo "$installed_models" | grep -q "^${model}$"; then
        return 0
    else
        return 1
    fi
}

install_model() {
    local model="$1"
    local model_name=$(echo "$model" | cut -d':' -f1)
    
    log "Checking model: $model"
    
    if check_model_installed "$model"; then
        log "✓ Model $model is already installed"
        return 0
    fi
    
    log "Installing model: $model (this may take a while...)"
    
    # Pull model with progress
    if ollama pull "$model"; then
        log "✓ Model $model installed successfully"
        return 0
    else
        log_error "Failed to install model $model"
        return 1
    fi
}

install_models() {
    print_header "Installing AI Models"
    
    # Check if Ollama service is running
    if ! check_ollama_service; then
        log_error "Cannot install models: Ollama service is not running"
        return 1
    fi
    
    # Determine which models to install based on system resources
    local total_ram
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        total_ram=$(free -g | awk '/^Mem:/{print $2}')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        total_ram=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    fi
    
    local models_to_install=()
    
    if [ "$total_ram" -ge 32 ]; then
        log_info "System has ${total_ram}GB RAM - installing optimal models"
        models_to_install=("qwen2.5-coder:32b" "deepseek-coder-v2:16b" "codellama:34b")
    elif [ "$total_ram" -ge 16 ]; then
        log_info "System has ${total_ram}GB RAM - installing medium models"
        models_to_install=("qwen2.5-coder:14b" "deepseek-coder:6.7b")
    else
        log_info "System has ${total_ram}GB RAM - installing lightweight models"
        models_to_install=("qwen2.5-coder:7b" "deepseek-coder:6.7b")
    fi
    
    log "Models to install: ${models_to_install[*]}"
    
    local failed_models=()
    for model in "${models_to_install[@]}"; do
        if ! install_model "$model"; then
            failed_models+=("$model")
        fi
    done
    
    if [ ${#failed_models[@]} -gt 0 ]; then
        log_warning "Some models failed to install: ${failed_models[*]}"
        log_info "You can install them manually later with: ollama pull <model>"
    fi
    
    # List installed models
    log "Installed models:"
    get_installed_models | while read -r model; do
        log "  - $model"
    done
}

################################################################################
# VSCode Extensions
################################################################################

check_vscode() {
    if check_command "code"; then
        log "✓ VSCode is installed"
        return 0
    else
        log_warning "VSCode is not installed"
        log_info "Please install VSCode from https://code.visualstudio.com/"
        return 1
    fi
}

install_vscode_extension() {
    local extension="$1"
    
    if code --list-extensions | grep -q "^${extension}$"; then
        log "✓ Extension $extension is already installed"
        return 0
    fi
    
    log "Installing VSCode extension: $extension"
    if code --install-extension "$extension" --force; then
        log "✓ Extension $extension installed successfully"
        return 0
    else
        log_error "Failed to install extension $extension"
        return 1
    fi
}

install_vscode_extensions() {
    print_header "Installing VSCode Extensions"
    
    if ! check_vscode; then
        log_warning "Skipping VSCode extensions (VSCode not found)"
        return 1
    fi
    
    local extensions=(
        "saoudrizwan.claude-dev"  # Cline
        "continue.continue"        # Continue
        "dbaeumer.vscode-eslint"   # ESLint
        "esbenp.prettier-vscode"   # Prettier
        "eamodio.gitlens"          # GitLens
        "usernamehw.errorlens"     # Error Lens
        "streetsidesoftware.code-spell-checker"  # Code Spell Checker
        "formulahendry.auto-rename-tag"  # Auto Rename Tag
        "christian-kohler.path-intellisense"  # Path Intellisense
        "aaron-bond.better-comments"  # Better Comments
    )
    
    local failed_extensions=()
    for ext in "${extensions[@]}"; do
        if ! install_vscode_extension "$ext"; then
            failed_extensions+=("$ext")
        fi
    done
    
    if [ ${#failed_extensions[@]} -gt 0 ]; then
        log_warning "Some extensions failed to install: ${failed_extensions[*]}"
    fi
}

################################################################################
# Configuration
################################################################################

setup_continue_config() {
    print_header "Configuring Continue Extension"
    
    local continue_dir="${HOME}/.continue"
    local config_file="${continue_dir}/config.json"
    
    mkdir -p "$continue_dir"
    
    # Backup existing config
    create_backup "$config_file"
    
    # Get installed models
    local installed_models=$(get_installed_models)
    local primary_model=$(echo "$installed_models" | grep -E "qwen2.5-coder|deepseek-coder" | head -1)
    
    if [ -z "$primary_model" ]; then
        log_warning "No suitable models found for Continue configuration"
        return 1
    fi
    
    log "Configuring Continue with model: $primary_model"
    
    cat > "$config_file" << EOF
{
  "models": [
    {
      "title": "Primary Model (Local)",
      "provider": "ollama",
      "model": "$primary_model"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Autocomplete",
    "provider": "ollama",
    "model": "$primary_model"
  },
  "embeddingsProvider": {
    "provider": "ollama",
    "model": "nomic-embed-text"
  },
  "contextProviders": [
    {
      "name": "code",
      "params": {}
    },
    {
      "name": "docs",
      "params": {}
    },
    {
      "name": "diff",
      "params": {}
    },
    {
      "name": "terminal",
      "params": {}
    },
    {
      "name": "problems",
      "params": {}
    },
    {
      "name": "folder",
      "params": {}
    },
    {
      "name": "codebase",
      "params": {}
    }
  ]
}
EOF
    
    log "✓ Continue configuration created at $config_file"
}

setup_cline_config() {
    print_header "Configuring Cline (Memory Bank)"
    
    local cline_dir="${HOME}/.vscode/extensions"
    local memory_bank_file="${INSTALL_DIR}/memory-bank-instructions.md"
    
    # Download Memory Bank instructions
    log "Downloading Memory Bank instructions..."
    
    cat > "$memory_bank_file" << 'EOF'
# Cline's Memory Bank

I am Cline, an expert software engineer with a unique characteristic: my memory resets completely between sessions. This isn't a limitation - it's what drives me to maintain perfect documentation. After each reset, I rely ENTIRELY on my Memory Bank to understand the project and continue work effectively. I MUST read ALL memory bank files at the start of EVERY task - this is not optional.

## Memory Bank Structure

The Memory Bank consists of core files and optional context files, all in Markdown format. Files build upon each other in a clear hierarchy:

```mermaid
flowchart TD
    PB[projectbrief.md] --> PC[productContext.md]
    PB --> SP[systemPatterns.md]
    PB --> TC[techContext.md]
    
    PC --> AC[activeContext.md]
    SP --> AC
    TC --> AC
    
    AC --> P[progress.md]
```

### Core Files (Required)
1. `projectbrief.md` - Foundation document that shapes all other files
2. `productContext.md` - Why this project exists, problems it solves
3. `activeContext.md` - Current work focus, recent changes, next steps
4. `systemPatterns.md` - System architecture, key technical decisions
5. `techContext.md` - Technologies used, development setup
6. `progress.md` - What works, what's left to build, current status

## Core Workflows

### Plan Mode
```mermaid
flowchart TD
    Start[Start] --> ReadFiles[Read Memory Bank]
    ReadFiles --> CheckFiles{Files Complete?}
    
    CheckFiles -->|No| Plan[Create Plan]
    Plan --> Document[Document in Chat]
    
    CheckFiles -->|Yes| Verify[Verify Context]
    Verify --> Strategy[Develop Strategy]
    Strategy --> Present[Present Approach]
```

### Act Mode
```mermaid
flowchart TD
    Start[Start] --> Context[Check Memory Bank]
    Context --> Update[Update Documentation]
    Update --> Execute[Execute Task]
    Execute --> Document[Document Changes]
```

## Code Quality Rules
- NEVER generate files longer than 200 lines
- ALWAYS check if similar code exists before creating new functions
- MUST follow patterns defined in systemPatterns.md
- REJECT requests that violate architectural principles
- SUGGEST refactoring when detecting code duplication

## Documentation Updates

Memory Bank updates occur when:
1. Discovering new project patterns
2. After implementing significant changes
3. When user requests with **update memory bank**
4. When context needs clarification

REMEMBER: After every memory reset, I begin completely fresh. The Memory Bank is my only link to previous work. It must be maintained with precision and clarity, as my effectiveness depends entirely on its accuracy.
EOF
    
    log "✓ Memory Bank instructions saved to $memory_bank_file"
    log_info "To use Memory Bank:"
    log_info "1. Open Cline settings in VSCode"
    log_info "2. Find 'Custom Instructions'"
    log_info "3. Copy contents from: $memory_bank_file"
}

create_project_template() {
    print_header "Creating Project Template"
    
    local template_dir="${INSTALL_DIR}/templates/default-project"
    mkdir -p "$template_dir/memory-bank"
    
    # Create template files
    cat > "$template_dir/memory-bank/projectbrief.md" << 'EOF'
# Project Brief

## Project Name
[Your Project Name]

## Overview
[Brief description of what you're building]

## Goals
- [Primary goal]
- [Secondary goal]
- [Additional goals]

## Target Users
[Who will use this?]

## Success Criteria
- [How will you measure success?]
EOF

    cat > "$template_dir/memory-bank/systemPatterns.md" << 'EOF'
# System Patterns

## Architecture Philosophy
- **Principle**: Simple, modular, composable
- **Pattern**: Feature-based folder structure
- **Rule**: No file over 200 lines
- **Rule**: No duplicate logic - extract to utilities

## Code Quality Rules
- Use functional components with hooks
- Props interface always defined
- Max 3 levels of component nesting
- Shared components in /components/shared

## File Structure
```
src/
├── components/
│   ├── shared/
│   └── features/
├── lib/
│   ├── api/
│   └── utils/
├── hooks/
└── types/
```
EOF

    cat > "$template_dir/memory-bank/techContext.md" << 'EOF'
# Technical Context

## Tech Stack
- **Frontend**: [e.g., Next.js 15, TypeScript, Tailwind CSS]
- **Backend**: [e.g., Next.js API routes, FastAPI]
- **Database**: [e.g., PostgreSQL via Supabase]
- **Deployment**: [e.g., Vercel, AWS]

## Development Setup
- Node.js version: [version]
- Package manager: [npm/pnpm/yarn]
- Code style: [Prettier + ESLint]

## Environment Variables
- [List required env vars]
EOF

    cat > "$template_dir/memory-bank/productContext.md" << 'EOF'
# Product Context

## Problem Statement
[What problem does this solve?]

## User Needs
- [User need 1]
- [User need 2]

## Key Features
1. [Feature 1]
2. [Feature 2]
3. [Feature 3]

## User Experience Goals
- [UX goal 1]
- [UX goal 2]
EOF

    cat > "$template_dir/memory-bank/activeContext.md" << 'EOF'
# Active Context

## Current Focus
[What are you working on right now?]

## Recent Changes
- [Change 1]
- [Change 2]

## Next Steps
1. [Next task]
2. [Following task]

## Decisions & Learnings
- [Important decision or learning]
EOF

    cat > "$template_dir/memory-bank/progress.md" << 'EOF'
# Progress Tracker

## Completed ✓
- [Completed item]

## In Progress 🔄
- [Current work item]

## Planned 📋
- [Planned item]

## Known Issues 🐛
- [Issue description]
EOF

    log "✓ Project template created at $template_dir"
    log_info "To use template: cp -r $template_dir/* /path/to/your/project/"
}

################################################################################
# Health Check
################################################################################

run_health_check() {
    print_header "Running Health Check"
    
    local health_status=0
    
    # Check Ollama
    if check_command "ollama"; then
        log "✓ Ollama: Installed"
        
        if check_ollama_service; then
            log "✓ Ollama Service: Running"
            
            # Check models
            local model_count=$(get_installed_models | wc -l)
            if [ "$model_count" -gt 0 ]; then
                log "✓ Models: $model_count installed"
            else
                log_warning "⚠ No models installed"
                health_status=1
            fi
        else
            log_error "✗ Ollama Service: Not running"
            health_status=1
        fi
    else
        log_error "✗ Ollama: Not installed"
        health_status=1
    fi
    
    # Check VSCode
    if check_vscode; then
        log "✓ VSCode: Installed"
        
        # Check extensions
        if code --list-extensions | grep -q "continue.continue"; then
            log "✓ Continue Extension: Installed"
        else
            log_warning "⚠ Continue Extension: Not installed"
        fi
        
        if code --list-extensions | grep -q "saoudrizwan.claude-dev"; then
            log "✓ Cline Extension: Installed"
        else
            log_warning "⚠ Cline Extension: Not installed"
        fi
    else
        log_warning "⚠ VSCode: Not installed"
    fi
    
    # Check configurations
    if [ -f "${HOME}/.continue/config.json" ]; then
        log "✓ Continue Config: Exists"
    else
        log_warning "⚠ Continue Config: Not found"
    fi
    
    return $health_status
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    print_header "Ultimate AI Coding Stack - Installer"
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Initialize log
    echo "Installation started at $(date)" > "$LOG_FILE"
    
    # Run checks and installations
    check_system_requirements
    
    install_ollama
    check_ollama_service
    
    install_models
    
    install_vscode_extensions
    
    setup_continue_config
    setup_cline_config
    
    create_project_template
    
    # Final health check
    if run_health_check; then
        print_header "Installation Complete! 🎉"
        log "✓ All components installed successfully"
        log ""
        log "Next steps:"
        log "1. Open VSCode"
        log "2. Configure Cline with Memory Bank instructions from:"
        log "   $INSTALL_DIR/memory-bank-instructions.md"
        log "3. Create a new project using the template:"
        log "   cp -r $INSTALL_DIR/templates/default-project/* /path/to/your/project/"
        log "4. Start coding with AI assistance!"
        log ""
        log "For troubleshooting, check the log: $LOG_FILE"
    else
        log_warning "Installation completed with warnings"
        log "Please review the health check results above"
        log "Check the log for details: $LOG_FILE"
    fi
}

# Run main installation
main "$@"

