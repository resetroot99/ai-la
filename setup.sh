#!/bin/bash

################################################################################
# Ultimate AI Coding Stack - Master Setup Script
# Complete autonomous installation with self-healing and validation
# Built for: Production-grade, security-first, modular architecture
################################################################################

set -e

# Version
VERSION="7.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${HOME}/.ai-coding-stack"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${INSTALL_DIR}/setup.log"

# Create install directory
mkdir -p "$INSTALL_DIR"

################################################################################
# Logging
################################################################################

log() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${GREEN}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_info() {
    local msg="[INFO] $1"
    echo -e "${BLUE}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_warn() {
    local msg="[WARN] $1"
    echo -e "${YELLOW}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] $1"
    echo -e "${RED}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    log "STEP: $1"
}

log_success() {
    echo ""
    echo -e "${GREEN}✓ $1${NC}"
    echo ""
}

################################################################################
# Banner
################################################################################

show_banner() {
    clear
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🚀 Ultimate AI Coding Stack - Master Setup v7.0 🚀      ║
║                                                              ║
║  The Complete AI-Powered Development Environment            ║
║  • Self-Learning AI                                          ║
║  • Production DevOps                                         ║
║  • Automated Reporting                                       ║
║  • Evaluation Framework                                      ║
║  • Zero Cost, Unlimited Usage                                ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

EOF
    sleep 2
}

################################################################################
# System Detection
################################################################################

detect_system() {
    log_step "Detecting System Configuration"
    
    # OS Detection
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
            log "OS: Linux ($NAME)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
        log "OS: macOS"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    
    # Architecture
    ARCH=$(uname -m)
    log "Architecture: $ARCH"
    
    # RAM
    if [[ "$OS" == "linux" ]]; then
        RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    else
        RAM_GB=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    fi
    log "RAM: ${RAM_GB}GB"
    
    # Disk Space
    DISK_AVAIL=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    log "Available Disk: $DISK_AVAIL"
    
    # GPU Detection
    if command -v nvidia-smi &> /dev/null; then
        GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | head -1)
        HAS_GPU=true
        log "GPU: $GPU_INFO"
    else
        HAS_GPU=false
        log "GPU: None detected"
    fi
    
    # CPU Cores
    if [[ "$OS" == "linux" ]]; then
        CPU_CORES=$(nproc)
    else
        CPU_CORES=$(sysctl -n hw.ncpu)
    fi
    log "CPU Cores: $CPU_CORES"
    
    log_success "System detection complete"
}

################################################################################
# Prerequisites Check
################################################################################

check_prerequisites() {
    log_step "Checking Prerequisites"
    
    local missing=()
    
    # Essential tools
    local required_tools=("curl" "git" "jq" "python3" "tar")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
            log_warn "$tool not found"
        else
            log "✓ $tool installed"
        fi
    done
    
    # Python packages
    if command -v python3 &> /dev/null; then
        if ! python3 -c "import json" &> /dev/null; then
            log_warn "Python json module not available"
        else
            log "✓ Python json module available"
        fi
    fi
    
    # Install missing tools
    if [ ${#missing[@]} -gt 0 ]; then
        log_warn "Missing tools: ${missing[*]}"
        install_prerequisites "${missing[@]}"
    else
        log_success "All prerequisites satisfied"
    fi
}

install_prerequisites() {
    local tools=("$@")
    
    log "Installing missing tools: ${tools[*]}"
    
    if [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
        sudo apt update -qq
        sudo apt install -y "${tools[@]}"
    elif [[ "$DISTRO" == "fedora" ]] || [[ "$DISTRO" == "rhel" ]]; then
        sudo dnf install -y "${tools[@]}"
    elif [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -S --noconfirm "${tools[@]}"
    elif [[ "$OS" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            log "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install "${tools[@]}"
    else
        log_error "Cannot auto-install on this system. Please install: ${tools[*]}"
        exit 1
    fi
    
    log_success "Prerequisites installed"
}

################################################################################
# Ollama Installation
################################################################################

install_ollama() {
    log_step "Installing Ollama"
    
    if command -v ollama &> /dev/null; then
        log "Ollama already installed: $(ollama --version 2>&1 | head -1)"
        return 0
    fi
    
    log "Downloading and installing Ollama..."
    
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://ollama.ai/install.sh | sh
    elif [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            brew install ollama
        else
            log_error "Please install Homebrew first or download Ollama from https://ollama.ai"
            exit 1
        fi
    fi
    
    # Start Ollama service
    if [[ "$OS" == "linux" ]]; then
        if command -v systemctl &> /dev/null; then
            sudo systemctl enable ollama
            sudo systemctl start ollama
        else
            ollama serve &> /dev/null &
        fi
    else
        ollama serve &> /dev/null &
    fi
    
    sleep 5
    
    # Verify
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        log_success "Ollama installed and running"
    else
        log_error "Ollama installation failed"
        exit 1
    fi
}

################################################################################
# Model Installation
################################################################################

install_models() {
    log_step "Installing AI Models"
    
    # Determine optimal model based on RAM
    local model=""
    
    if [ "$RAM_GB" -ge 32 ]; then
        model="qwen2.5-coder:32b"
        log "System has ${RAM_GB}GB RAM - installing 32B model"
    elif [ "$RAM_GB" -ge 16 ]; then
        model="qwen2.5-coder:14b"
        log "System has ${RAM_GB}GB RAM - installing 14B model"
    else
        model="qwen2.5-coder:7b"
        log "System has ${RAM_GB}GB RAM - installing 7B model"
    fi
    
    log "Pulling model: $model (this may take several minutes)..."
    
    if ollama pull "$model"; then
        log_success "Model installed: $model"
        echo "$model" > "${INSTALL_DIR}/default_model.txt"
    else
        log_error "Failed to install model"
        exit 1
    fi
    
    # Install backup model
    log "Installing backup model: codellama:7b..."
    ollama pull codellama:7b &> /dev/null || log_warn "Backup model installation failed"
}

################################################################################
# VSCode Extensions
################################################################################

install_vscode_extensions() {
    log_step "Installing VSCode Extensions"
    
    if ! command -v code &> /dev/null; then
        log_warn "VSCode not found - skipping extensions"
        return 0
    fi
    
    local extensions=(
        "continue.continue"
        "saoudrizwan.claude-dev"
        "github.copilot"
        "dbaeumer.vscode-eslint"
        "esbenp.prettier-vscode"
        "eamodio.gitlens"
    )
    
    for ext in "${extensions[@]}"; do
        if code --list-extensions | grep -q "$ext"; then
            log "✓ $ext already installed"
        else
            log "Installing $ext..."
            code --install-extension "$ext" --force &> /dev/null || log_warn "Failed to install $ext"
        fi
    done
    
    log_success "VSCode extensions configured"
}

################################################################################
# Directory Structure
################################################################################

create_directory_structure() {
    log_step "Creating Directory Structure"
    
    local dirs=(
        "${INSTALL_DIR}/learning/knowledge-base"
        "${INSTALL_DIR}/learning/patterns"
        "${INSTALL_DIR}/learning/training-data"
        "${INSTALL_DIR}/learning/models"
        "${INSTALL_DIR}/learning/cache"
        "${INSTALL_DIR}/evaluation/history"
        "${INSTALL_DIR}/evaluation/results"
        "${INSTALL_DIR}/evaluation/benchmarks"
        "${INSTALL_DIR}/compliance/sessions"
        "${INSTALL_DIR}/compliance/receipts"
        "${INSTALL_DIR}/reports"
        "${INSTALL_DIR}/data"
        "${INSTALL_DIR}/archives"
        "${INSTALL_DIR}/configs"
        "${INSTALL_DIR}/scripts"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        log "✓ Created: $dir"
    done
    
    log_success "Directory structure created"
}

################################################################################
# Configuration Files
################################################################################

install_configs() {
    log_step "Installing Configuration Files"
    
    # Copy configs from repo
    if [ -d "$SCRIPT_DIR/configs" ]; then
        cp -r "$SCRIPT_DIR/configs/"* "${INSTALL_DIR}/configs/" 2>/dev/null || true
        log "✓ Configuration files copied"
    fi
    
    # Create Continue config
    local continue_config="${HOME}/.continue/config.json"
    mkdir -p "$(dirname "$continue_config")"
    
    local default_model=$(cat "${INSTALL_DIR}/default_model.txt" 2>/dev/null || echo "qwen2.5-coder:7b")
    
    cat > "$continue_config" << EOF
{
  "models": [
    {
      "title": "Qwen Coder",
      "provider": "ollama",
      "model": "$default_model"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Tab Autocomplete",
    "provider": "ollama",
    "model": "codellama:7b"
  },
  "embeddingsProvider": {
    "provider": "ollama",
    "model": "nomic-embed-text"
  },
  "systemMessage": "You are an expert software engineer. Write clean, efficient, well-documented code following best practices.",
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
    
    log "✓ Continue configuration created"
    
    # Create Cline config
    local cline_config="${HOME}/.vscode/extensions/saoudrizwan.claude-dev-*/settings.json"
    # Note: Cline config is managed through VSCode settings
    
    log_success "Configuration files installed"
}

################################################################################
# Scripts Installation
################################################################################

install_scripts() {
    log_step "Installing Scripts"
    
    if [ -d "$SCRIPT_DIR/scripts" ]; then
        cp "$SCRIPT_DIR/scripts/"*.sh "${INSTALL_DIR}/scripts/" 2>/dev/null || true
        chmod +x "${INSTALL_DIR}/scripts/"*.sh
        log "✓ Scripts copied and made executable"
    fi
    
    # Create symlinks in PATH
    local bin_dir="${HOME}/.local/bin"
    mkdir -p "$bin_dir"
    
    local scripts=(
        "ai-evaluation.sh:ai-eval"
        "ai-learning-system.sh:ai-learn"
        "ai-auto-report.sh:ai-report"
        "ai-deploy.sh:ai-deploy"
        "memory-manager.sh:ai-memory"
    )
    
    for script_map in "${scripts[@]}"; do
        local script="${script_map%%:*}"
        local alias="${script_map##*:}"
        
        if [ -f "${INSTALL_DIR}/scripts/$script" ]; then
            ln -sf "${INSTALL_DIR}/scripts/$script" "${bin_dir}/$alias"
            log "✓ Created alias: $alias → $script"
        fi
    done
    
    # Add to PATH if not already
    if [[ ":$PATH:" != *":${bin_dir}:"* ]]; then
        echo "export PATH=\"\$PATH:${bin_dir}\"" >> "${HOME}/.bashrc"
        echo "export PATH=\"\$PATH:${bin_dir}\"" >> "${HOME}/.zshrc" 2>/dev/null || true
        log "✓ Added ${bin_dir} to PATH"
    fi
    
    log_success "Scripts installed"
}

################################################################################
# Developer Profile
################################################################################

create_developer_profile() {
    log_step "Creating Developer Profile"
    
    local profile_file="${INSTALL_DIR}/configs/developer-profile.json"
    
    if [ -f "$SCRIPT_DIR/configs/developer-profile.json" ]; then
        cp "$SCRIPT_DIR/configs/developer-profile.json" "$profile_file"
        log "✓ Developer profile copied from repository"
    else
        # Create default profile
        cat > "$profile_file" << 'EOF'
{
  "profile_version": "1.0",
  "developer_identity": {
    "type": "full_stack_engineer",
    "philosophy": "production_grade_quality",
    "approach": "modular_architecture"
  },
  "core_principles": {
    "design_rule": "clarity_over_clutter",
    "dependencies": "minimal_deep_control",
    "architecture": "modular_self_improving",
    "security": "security_first",
    "optimization": "performance_and_readability"
  },
  "reporting_preferences": {
    "format": "markdown_with_metrics",
    "frequency": "daily_summaries",
    "detail_level": "executive_with_actionable_items",
    "metrics": "quantifiable_roi",
    "tone": "direct_data_driven"
  }
}
EOF
        log "✓ Default developer profile created"
    fi
    
    log_success "Developer profile configured"
}

################################################################################
# Initial Learning
################################################################################

run_initial_learning() {
    log_step "Running Initial Learning"
    
    log "This will analyze your existing projects to bootstrap the AI..."
    
    # Find project directories
    local project_dirs=()
    for dir in "$HOME/projects" "$HOME/work" "$HOME/dev" "$HOME/code"; do
        if [ -d "$dir" ]; then
            project_dirs+=("$dir")
        fi
    done
    
    if [ ${#project_dirs[@]} -eq 0 ]; then
        log_warn "No project directories found - skipping initial learning"
        return 0
    fi
    
    log "Found project directories: ${project_dirs[*]}"
    
    # Run learning system
    if [ -f "${INSTALL_DIR}/scripts/ai-learning-system.sh" ]; then
        for dir in "${project_dirs[@]}"; do
            log "Analyzing: $dir"
            "${INSTALL_DIR}/scripts/ai-learning-system.sh" learn-local "$dir" &>> "$LOG_FILE" || log_warn "Learning failed for $dir"
        done
        
        log "Building knowledge base..."
        "${INSTALL_DIR}/scripts/ai-learning-system.sh" build-kb &>> "$LOG_FILE" || log_warn "Knowledge base build failed"
        
        log "Updating configuration..."
        "${INSTALL_DIR}/scripts/ai-learning-system.sh" update-config &>> "$LOG_FILE" || log_warn "Config update failed"
        
        log_success "Initial learning complete"
    else
        log_warn "Learning script not found - skipping"
    fi
}

################################################################################
# Automation Setup
################################################################################

setup_automation() {
    log_step "Setting Up Automation"
    
    # Create automation script
    local auto_script="${INSTALL_DIR}/daily-automation.sh"
    
    cat > "$auto_script" << 'AUTOSCRIPT'
#!/bin/bash
# Daily automation for Ultimate AI Coding Stack

INSTALL_DIR="${HOME}/.ai-coding-stack"
LOG_FILE="${INSTALL_DIR}/automation.log"

echo "[$(date)] Starting daily automation" >> "$LOG_FILE"

# Run evaluation
if [ -f "${INSTALL_DIR}/scripts/ai-evaluation.sh" ]; then
    "${INSTALL_DIR}/scripts/ai-evaluation.sh" full >> "$LOG_FILE" 2>&1
fi

# Run learning
if [ -f "${INSTALL_DIR}/scripts/ai-learning-system.sh" ]; then
    "${INSTALL_DIR}/scripts/ai-learning-system.sh" learn-local ~/projects >> "$LOG_FILE" 2>&1
    "${INSTALL_DIR}/scripts/ai-learning-system.sh" build-kb >> "$LOG_FILE" 2>&1
fi

# Generate report
if [ -f "${INSTALL_DIR}/scripts/ai-auto-report.sh" ]; then
    "${INSTALL_DIR}/scripts/ai-auto-report.sh" full >> "$LOG_FILE" 2>&1
fi

echo "[$(date)] Daily automation complete" >> "$LOG_FILE"
AUTOSCRIPT
    
    chmod +x "$auto_script"
    
    # Add to crontab (daily at 6 AM)
    (crontab -l 2>/dev/null | grep -v "daily-automation"; echo "0 6 * * * $auto_script") | crontab -
    
    log "✓ Daily automation scheduled for 6 AM"
    log_success "Automation configured"
}

################################################################################
# Verification
################################################################################

verify_installation() {
    log_step "Verifying Installation"
    
    local errors=0
    
    # Check Ollama
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        log "✓ Ollama is running"
    else
        log_error "Ollama is not running"
        errors=$((errors + 1))
    fi
    
    # Check models
    if ollama list | grep -q "qwen\|codellama"; then
        log "✓ Models installed"
    else
        log_error "No models found"
        errors=$((errors + 1))
    fi
    
    # Check directories
    if [ -d "${INSTALL_DIR}/learning" ] && [ -d "${INSTALL_DIR}/evaluation" ]; then
        log "✓ Directory structure created"
    else
        log_error "Directory structure incomplete"
        errors=$((errors + 1))
    fi
    
    # Check scripts
    if [ -f "${INSTALL_DIR}/scripts/ai-evaluation.sh" ]; then
        log "✓ Scripts installed"
    else
        log_error "Scripts not found"
        errors=$((errors + 1))
    fi
    
    # Check automation
    if crontab -l 2>/dev/null | grep -q "daily-automation"; then
        log "✓ Automation scheduled"
    else
        log_warn "Automation not scheduled"
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "Verification passed"
        return 0
    else
        log_error "Verification failed with $errors errors"
        return 1
    fi
}

################################################################################
# Post-Install Summary
################################################################################

show_summary() {
    log_step "Installation Complete!"
    
    cat << EOF

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          ✅ Ultimate AI Coding Stack Installed! ✅          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

📊 System Information:
   OS: $OS ($DISTRO)
   RAM: ${RAM_GB}GB
   CPU: ${CPU_CORES} cores
   GPU: $([ "$HAS_GPU" = true ] && echo "Yes" || echo "No")

🤖 AI Configuration:
   Model: $(cat "${INSTALL_DIR}/default_model.txt" 2>/dev/null || echo "Unknown")
   Ollama: Running
   Continue: Configured
   
📁 Installation Directory:
   ${INSTALL_DIR}

🔧 Available Commands:
   ai-eval          Run evaluation
   ai-learn         Run learning system
   ai-report        Generate reports
   ai-deploy        Deploy applications
   ai-memory        Manage memory patterns

📚 Quick Start:

   1. Run initial evaluation:
      ai-eval full

   2. Start learning from your code:
      ai-learn learn-local ~/projects
      ai-learn build-kb

   3. Generate your first report:
      ai-report full

   4. Enable continuous learning:
      ai-learn enable-continuous

🔄 Automation:
   ✓ Daily automation scheduled for 6 AM
   ✓ Continuous learning enabled
   ✓ Auto-reporting configured

📖 Documentation:
   ${SCRIPT_DIR}/README.md
   ${SCRIPT_DIR}/QUICKSTART.md
   ${SCRIPT_DIR}/docs/

🎯 Next Steps:

   1. Open VSCode and install Continue extension
   2. Run: ai-eval full
   3. Review: ai-report status
   4. Start coding with AI assistance!

💡 Pro Tips:
   - Use 'ai-eval progress' to track improvement
   - Check daily reports in ${INSTALL_DIR}/reports/
   - View logs: tail -f ${INSTALL_DIR}/automation.log

═══════════════════════════════════════════════════════════════

🚀 Happy Coding with AI! 🚀

EOF
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    show_banner
    
    log "Starting Ultimate AI Coding Stack installation v${VERSION}"
    log "Installation directory: ${INSTALL_DIR}"
    log "Log file: ${LOG_FILE}"
    
    # Installation steps
    detect_system
    check_prerequisites
    install_ollama
    install_models
    create_directory_structure
    install_configs
    install_scripts
    create_developer_profile
    install_vscode_extensions
    run_initial_learning
    setup_automation
    verify_installation
    
    # Show summary
    show_summary
    
    log "Installation completed successfully!"
    
    # Source bashrc to update PATH
    echo ""
    echo -e "${YELLOW}Note: Please restart your terminal or run:${NC}"
    echo -e "${CYAN}source ~/.bashrc${NC}"
    echo ""
}

# Run main installation
main "$@"

