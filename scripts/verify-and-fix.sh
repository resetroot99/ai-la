#!/bin/bash

################################################################################
# Installation Verification and Auto-Fix
# Verifies installation and automatically fixes common issues
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="${HOME}/.ai-coding-stack"
LOG_FILE="${INSTALL_DIR}/verify.log"

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

################################################################################
# Verification Functions
################################################################################

verify_ollama() {
    log "Verifying Ollama installation..."
    
    if ! command -v ollama &> /dev/null; then
        log_error "Ollama is not installed"
        
        read -p "Install Ollama now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Installing Ollama..."
            curl -fsSL https://ollama.com/install.sh | sh
            
            if command -v ollama &> /dev/null; then
                log "✓ Ollama installed successfully"
            else
                log_error "Ollama installation failed"
                return 1
            fi
        else
            return 1
        fi
    else
        log "✓ Ollama is installed"
    fi
    
    # Check service
    if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
        log_warn "Ollama service is not running"
        
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
        
        log_error "Failed to start Ollama service"
        return 1
    else
        log "✓ Ollama service is running"
    fi
}

verify_models() {
    log "Verifying AI models..."
    
    local models=$(curl -s http://localhost:11434/api/tags 2>/dev/null | jq -r '.models[].name' || echo "")
    
    if [ -z "$models" ]; then
        log_warn "No models installed"
        
        # Determine appropriate model based on RAM
        local total_ram
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            total_ram=$(free -g | awk '/^Mem:/{print $2}')
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            total_ram=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
        fi
        
        local recommended_model
        if [ "$total_ram" -ge 32 ]; then
            recommended_model="qwen2.5-coder:32b"
        elif [ "$total_ram" -ge 16 ]; then
            recommended_model="qwen2.5-coder:14b"
        else
            recommended_model="qwen2.5-coder:7b"
        fi
        
        log_info "Recommended model for your system: $recommended_model"
        
        read -p "Install $recommended_model now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Pulling model: $recommended_model (this may take a while)..."
            if ollama pull "$recommended_model"; then
                log "✓ Model installed successfully"
            else
                log_error "Model installation failed"
                return 1
            fi
        else
            log_info "You can install models later with: ollama pull <model>"
            return 1
        fi
    else
        log "✓ Found installed models:"
        while IFS= read -r model; do
            log_info "  - $model"
        done <<< "$models"
    fi
}

verify_vscode() {
    log "Verifying VSCode installation..."
    
    if ! command -v code &> /dev/null; then
        log_warn "VSCode is not installed"
        log_info "Install VSCode from: https://code.visualstudio.com/"
        log_info "VSCode is optional but recommended"
        return 1
    else
        log "✓ VSCode is installed"
    fi
}

verify_extensions() {
    log "Verifying VSCode extensions..."
    
    if ! command -v code &> /dev/null; then
        log_warn "VSCode not available, skipping extension check"
        return 1
    fi
    
    local required_extensions=(
        "continue.continue"
        "saoudrizwan.claude-dev"
    )
    
    local missing_extensions=()
    
    for ext in "${required_extensions[@]}"; do
        if code --list-extensions 2>/dev/null | grep -q "^${ext}$"; then
            log "✓ Extension installed: $ext"
        else
            log_warn "Extension missing: $ext"
            missing_extensions+=("$ext")
        fi
    done
    
    if [ ${#missing_extensions[@]} -gt 0 ]; then
        read -p "Install missing extensions now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for ext in "${missing_extensions[@]}"; do
                log "Installing extension: $ext"
                if code --install-extension "$ext" --force; then
                    log "✓ Extension installed: $ext"
                else
                    log_error "Failed to install: $ext"
                fi
            done
        fi
    fi
}

verify_continue_config() {
    log "Verifying Continue configuration..."
    
    local config_file="${HOME}/.continue/config.json"
    
    if [ ! -f "$config_file" ]; then
        log_warn "Continue config not found"
        
        read -p "Generate Continue config now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -f "./scripts/generate-continue-config.sh" ]; then
                log "Generating Continue configuration..."
                if ./scripts/generate-continue-config.sh; then
                    log "✓ Continue config generated"
                else
                    log_error "Failed to generate Continue config"
                    return 1
                fi
            else
                log_error "generate-continue-config.sh not found"
                return 1
            fi
        fi
    else
        log "✓ Continue config exists"
        
        # Validate JSON
        if jq empty "$config_file" 2>/dev/null; then
            log "✓ Continue config is valid JSON"
            
            # Check for models
            local models=$(jq -r '.models[]?.model // empty' "$config_file" 2>/dev/null)
            if [ -n "$models" ]; then
                log "✓ Models configured in Continue"
            else
                log_warn "No models configured in Continue"
            fi
        else
            log_error "Continue config is invalid JSON"
            
            read -p "Regenerate Continue config? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Backup broken config
                mv "$config_file" "${config_file}.broken"
                
                if ./scripts/generate-continue-config.sh; then
                    log "✓ Continue config regenerated"
                else
                    log_error "Failed to regenerate Continue config"
                    return 1
                fi
            fi
        fi
    fi
}

verify_memory_system() {
    log "Verifying Memory System..."
    
    local memory_dir="${INSTALL_DIR}/memory"
    
    if [ ! -d "$memory_dir" ]; then
        log_info "Creating memory directory..."
        mkdir -p "$memory_dir"
        log "✓ Memory directory created"
    else
        log "✓ Memory directory exists"
    fi
    
    # Check for memory files
    local file_count=$(find "$memory_dir" -type f 2>/dev/null | wc -l)
    if [ "$file_count" -gt 0 ]; then
        log "✓ Memory system has $file_count file(s)"
    else
        log_info "Memory system is empty (this is normal for new installations)"
    fi
}

verify_templates() {
    log "Verifying project templates..."
    
    local template_dir="${INSTALL_DIR}/templates/default-project"
    
    if [ ! -d "$template_dir" ]; then
        log_warn "Project template not found"
        
        read -p "Create project template now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p "$template_dir/memory-bank"
            
            # Create template files (simplified versions)
            cat > "$template_dir/memory-bank/projectbrief.md" << 'EOF'
# Project Brief

## Project Name
[Your Project Name]

## Overview
[Brief description of what you're building]

## Goals
- [Primary goal]
- [Secondary goal]

## Target Users
[Who will use this?]
EOF
            
            log "✓ Project template created"
        fi
    else
        log "✓ Project template exists"
    fi
}

################################################################################
# Health Check
################################################################################

run_health_check() {
    log "Running comprehensive health check..."
    
    local issues=0
    
    # Test Ollama API
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        log "✓ Ollama API responding"
    else
        log_error "Ollama API not responding"
        ((issues++))
    fi
    
    # Test model inference (if models exist)
    local model=$(curl -s http://localhost:11434/api/tags 2>/dev/null | jq -r '.models[0].name' 2>/dev/null)
    if [ -n "$model" ] && [ "$model" != "null" ]; then
        log "Testing model inference with: $model"
        
        local response=$(timeout 30 curl -s http://localhost:11434/api/generate -d '{
            "model": "'"$model"'",
            "prompt": "print hello",
            "stream": false
        }' 2>/dev/null | jq -r '.response' 2>/dev/null)
        
        if [ -n "$response" ] && [ "$response" != "null" ]; then
            log "✓ Model inference working"
        else
            log_warn "Model inference test failed (may be slow or timing out)"
        fi
    fi
    
    # Check disk space
    local available_disk=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_disk" -ge 10 ]; then
        log "✓ Sufficient disk space: ${available_disk}GB"
    else
        log_warn "Low disk space: ${available_disk}GB"
    fi
    
    return $issues
}

################################################################################
# Rollback
################################################################################

rollback_installation() {
    log_warn "Rolling back installation..."
    
    read -p "This will remove all installed components. Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Rollback cancelled"
        return 0
    fi
    
    # Backup important data
    if [ -d "${INSTALL_DIR}/memory" ]; then
        local backup_dir="${HOME}/ai-stack-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        cp -r "${INSTALL_DIR}/memory" "$backup_dir/"
        log "Memory data backed up to: $backup_dir"
    fi
    
    # Remove installation directory
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        log "✓ Removed installation directory"
    fi
    
    # Remove Continue config (with backup)
    if [ -f "${HOME}/.continue/config.json" ]; then
        mv "${HOME}/.continue/config.json" "${HOME}/.continue/config.json.backup"
        log "✓ Continue config backed up"
    fi
    
    log "Rollback complete"
    log_info "To reinstall, run: ./install.sh"
}

################################################################################
# Main
################################################################################

show_menu() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  Installation Verification & Fix"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "1. Run full verification"
    echo "2. Verify and fix Ollama"
    echo "3. Verify and fix models"
    echo "4. Verify and fix VSCode extensions"
    echo "5. Verify and fix Continue config"
    echo "6. Run health check"
    echo "7. Rollback installation"
    echo "8. Exit"
    echo ""
    read -p "Select option (1-8): " choice
    
    case $choice in
        1)
            verify_ollama
            verify_models
            verify_vscode
            verify_extensions
            verify_continue_config
            verify_memory_system
            verify_templates
            run_health_check
            ;;
        2)
            verify_ollama
            ;;
        3)
            verify_models
            ;;
        4)
            verify_vscode
            verify_extensions
            ;;
        5)
            verify_continue_config
            ;;
        6)
            run_health_check
            ;;
        7)
            rollback_installation
            ;;
        8)
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    show_menu
}

# Create log directory
mkdir -p "$INSTALL_DIR"

if [ $# -eq 0 ]; then
    # Interactive mode
    show_menu
else
    # Non-interactive mode
    case "$1" in
        --verify-all)
            verify_ollama
            verify_models
            verify_vscode
            verify_extensions
            verify_continue_config
            verify_memory_system
            verify_templates
            ;;
        --health-check)
            run_health_check
            ;;
        --rollback)
            rollback_installation
            ;;
        *)
            echo "Usage: $0 [--verify-all|--health-check|--rollback]"
            exit 1
            ;;
    esac
fi

