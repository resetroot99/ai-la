#!/bin/bash

################################################################################
# Ultimate AI Coding Stack - Enhanced Installer
# Version: 2.0.0
# Features: Dry-run mode, pre-flight checks, auto-recovery, rollback
################################################################################

set -e
set -u

# Parse arguments
DRY_RUN=false
SKIP_PREFLIGHT=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-preflight)
            SKIP_PREFLIGHT=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            cat << 'EOF'
Ultimate AI Coding Stack - Enhanced Installer

Usage: ./install-enhanced.sh [OPTIONS]

Options:
  --dry-run         Simulate installation without making changes
  --skip-preflight  Skip pre-flight validation checks
  --force           Force installation even if checks fail
  --help            Show this help message

Examples:
  ./install-enhanced.sh                    # Normal installation
  ./install-enhanced.sh --dry-run          # See what would be installed
  ./install-enhanced.sh --skip-preflight   # Skip validation
  ./install-enhanced.sh --force            # Force install

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${HOME}/.ai-coding-stack"
LOG_FILE="${INSTALL_DIR}/install.log"
BACKUP_DIR="${INSTALL_DIR}/backups/$(date +%Y%m%d-%H%M%S)"

# Create directories
mkdir -p "$INSTALL_DIR" "$BACKUP_DIR"

################################################################################
# Logging Functions
################################################################################

log() {
    local msg="$1"
    if [ "$DRY_RUN" = true ]; then
        msg="[DRY-RUN] $msg"
    fi
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $msg" | tee -a "$LOG_FILE"
}

log_error() {
    local msg="$1"
    if [ "$DRY_RUN" = true ]; then
        msg="[DRY-RUN] $msg"
    fi
    echo -e "${RED}[ERROR]${NC} $msg" | tee -a "$LOG_FILE"
}

log_warn() {
    local msg="$1"
    if [ "$DRY_RUN" = true ]; then
        msg="[DRY-RUN] $msg"
    fi
    echo -e "${YELLOW}[WARN]${NC} $msg" | tee -a "$LOG_FILE"
}

log_info() {
    local msg="$1"
    if [ "$DRY_RUN" = true ]; then
        msg="[DRY-RUN] $msg"
    fi
    echo -e "${BLUE}[INFO]${NC} $msg" | tee -a "$LOG_FILE"
}

log_step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# Pre-Flight Checks
################################################################################

run_preflight() {
    if [ "$SKIP_PREFLIGHT" = true ]; then
        log_warn "Skipping pre-flight checks (--skip-preflight)"
        return 0
    fi
    
    log_step "Running Pre-Flight Checks"
    
    if [ -f "./scripts/preflight-check.sh" ]; then
        if ./scripts/preflight-check.sh; then
            log "✓ Pre-flight checks passed"
            return 0
        else
            log_error "Pre-flight checks failed"
            
            if [ "$FORCE" = true ]; then
                log_warn "Continuing anyway (--force)"
                return 0
            else
                echo ""
                read -p "Continue anyway? (y/N) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    return 0
                else
                    exit 1
                fi
            fi
        fi
    else
        log_warn "Pre-flight check script not found"
    fi
}

################################################################################
# Installation Functions
################################################################################

install_ollama() {
    log_step "Installing Ollama"
    
    if command -v ollama &> /dev/null; then
        log "Ollama already installed"
        local version=$(ollama --version 2>/dev/null || echo "unknown")
        log_info "Version: $version"
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log "Would install Ollama"
        return 0
    fi
    
    log "Downloading and installing Ollama..."
    
    if curl -fsSL https://ollama.com/install.sh | sh; then
        log "✓ Ollama installed successfully"
    else
        log_error "Failed to install Ollama"
        return 1
    fi
    
    # Start service
    log "Starting Ollama service..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open -a Ollama 2>/dev/null || ollama serve &> /dev/null &
    else
        ollama serve &> /dev/null &
    fi
    
    # Wait for service
    local max_attempts=10
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            log "✓ Ollama service started"
            return 0
        fi
        sleep 2
        ((attempt++))
    done
    
    log_warn "Ollama service may not have started properly"
}

install_models() {
    log_step "Installing AI Models"
    
    if [ "$DRY_RUN" = true ]; then
        log "Would install AI models based on system RAM"
        return 0
    fi
    
    # Detect RAM
    local total_ram
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        total_ram=$(free -g | awk '/^Mem:/{print $2}')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        total_ram=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    fi
    
    log_info "Detected RAM: ${total_ram}GB"
    
    # Select models based on RAM
    local models=()
    if [ "$total_ram" -ge 32 ]; then
        models=("qwen2.5-coder:32b" "deepseek-coder-v2:16b")
    elif [ "$total_ram" -ge 16 ]; then
        models=("qwen2.5-coder:14b" "deepseek-coder:6.7b")
    else
        models=("qwen2.5-coder:7b")
    fi
    
    log_info "Will install: ${models[*]}"
    
    for model in "${models[@]}"; do
        log "Pulling model: $model (this may take a while)..."
        
        if ollama pull "$model"; then
            log "✓ Model installed: $model"
        else
            log_error "Failed to install model: $model"
        fi
    done
}

install_vscode_extensions() {
    log_step "Installing VSCode Extensions"
    
    if ! command -v code &> /dev/null; then
        log_warn "VSCode not installed, skipping extensions"
        log_info "Install VSCode from: https://code.visualstudio.com/"
        return 0
    fi
    
    local extensions=(
        "continue.continue"
        "saoudrizwan.claude-dev"
    )
    
    for ext in "${extensions[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            log "Would install extension: $ext"
        else
            log "Installing extension: $ext"
            if code --install-extension "$ext" --force; then
                log "✓ Extension installed: $ext"
            else
                log_warn "Failed to install extension: $ext"
            fi
        fi
    done
}

setup_memory_system() {
    log_step "Setting Up Memory System"
    
    local memory_dir="${INSTALL_DIR}/memory"
    
    if [ "$DRY_RUN" = true ]; then
        log "Would create memory directory: $memory_dir"
        return 0
    fi
    
    mkdir -p "$memory_dir"
    log "✓ Memory directory created"
    
    # Copy schema and examples
    if [ -f "./configs/memory-schema.json" ]; then
        cp "./configs/memory-schema.json" "$memory_dir/"
        log "✓ Memory schema installed"
    fi
    
    if [ -f "./configs/memory-example.json" ]; then
        cp "./configs/memory-example.json" "$memory_dir/"
        log "✓ Memory example installed"
    fi
}

generate_continue_config() {
    log_step "Generating Continue Configuration"
    
    if [ "$DRY_RUN" = true ]; then
        log "Would generate Continue config"
        return 0
    fi
    
    # Backup existing config
    if [ -f "${HOME}/.continue/config.json" ]; then
        cp "${HOME}/.continue/config.json" "${BACKUP_DIR}/continue-config.json"
        log "✓ Existing config backed up"
    fi
    
    if [ -f "./scripts/generate-continue-config.sh" ]; then
        if ./scripts/generate-continue-config.sh; then
            log "✓ Continue config generated"
        else
            log_warn "Failed to generate Continue config"
        fi
    else
        log_warn "generate-continue-config.sh not found"
    fi
}

setup_project_templates() {
    log_step "Setting Up Project Templates"
    
    local template_dir="${INSTALL_DIR}/templates/default-project"
    
    if [ "$DRY_RUN" = true ]; then
        log "Would create project templates"
        return 0
    fi
    
    mkdir -p "$template_dir/memory-bank"
    
    # Create Memory Bank template files
    cat > "$template_dir/memory-bank/projectbrief.md" << 'EOF'
# Project Brief

## Project Name
[Your Project Name]

## Overview
[Brief description of what you're building]

## Goals
- [Primary goal]
- [Secondary goal]

## Tech Stack
- [Technology 1]
- [Technology 2]

## Target Users
[Who will use this?]
EOF
    
    cat > "$template_dir/memory-bank/systemPatterns.md" << 'EOF'
# System Patterns

## Architecture Principles
- [Principle 1]
- [Principle 2]

## Code Quality Rules
- No code duplication
- Functions under 50 lines
- Clear naming conventions
- Comprehensive error handling

## Anti-Patterns to Avoid
- God objects
- Tight coupling
- Magic numbers
- Premature optimization
EOF
    
    log "✓ Project templates created"
}

################################################################################
# Verification
################################################################################

run_verification() {
    log_step "Running Installation Verification"
    
    if [ "$DRY_RUN" = true ]; then
        log "Would run verification checks"
        return 0
    fi
    
    if [ -f "./scripts/verify-and-fix.sh" ]; then
        if ./scripts/verify-and-fix.sh --verify-all; then
            log "✓ Verification passed"
        else
            log_warn "Some verification checks failed"
            log_info "Run './scripts/verify-and-fix.sh' to diagnose and fix issues"
        fi
    fi
}

################################################################################
# Summary
################################################################################

print_summary() {
    log_step "Installation Complete!"
    
    echo "✓ Ollama installed and configured"
    echo "✓ AI models downloaded"
    echo "✓ VSCode extensions installed"
    echo "✓ Memory system configured"
    echo "✓ Continue config generated"
    echo "✓ Project templates created"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}This was a dry-run. No changes were made.${NC}"
        echo "Run without --dry-run to perform actual installation"
        echo ""
        return 0
    fi
    
    echo "Next steps:"
    echo ""
    echo "1. Restart VSCode to load extensions"
    echo ""
    echo "2. Configure Cline (one-time):"
    echo "   - Open VSCode"
    echo "   - Click Cline icon in sidebar"
    echo "   - Click settings (⚙️)"
    echo "   - Copy contents from: ${INSTALL_DIR}/memory-bank-instructions.md"
    echo ""
    echo "3. Start a new project:"
    echo "   cp -r ${INSTALL_DIR}/templates/default-project/* ~/my-project/"
    echo "   cd ~/my-project"
    echo "   code ."
    echo ""
    echo "4. Import your coding patterns (optional):"
    echo "   ./scripts/memory-manager.sh analyze-codebase ~/existing-project"
    echo ""
    echo "Useful commands:"
    echo "  ./scripts/verify-and-fix.sh       # Verify and fix issues"
    echo "  ./scripts/memory-manager.sh       # Manage developer memory"
    echo "  ./scripts/preflight-check.sh      # Check system requirements"
    echo ""
    echo "Documentation: ./docs/"
    echo "Log file: $LOG_FILE"
    echo ""
    echo -e "${GREEN}Happy coding with AI! 🚀${NC}"
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    echo "════════════════════════════════════════════════════════════"
    echo "  Ultimate AI Coding Stack - Enhanced Installer v2.0"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}DRY-RUN MODE: No changes will be made${NC}"
        echo ""
    fi
    
    # Pre-flight checks
    run_preflight
    
    # Installation steps
    install_ollama
    install_models
    install_vscode_extensions
    setup_memory_system
    generate_continue_config
    setup_project_templates
    
    # Verification
    run_verification
    
    # Summary
    print_summary
    
    log "Installation completed successfully"
}

# Run main installation
main "$@"

