#!/bin/bash

################################################################################
# Pre-Flight Validation
# Validates system before installation to prevent failures
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Requirements
MIN_RAM_GB=8
MIN_DISK_GB=20
RECOMMENDED_RAM_GB=16

# Checks
CRITICAL_FAILURES=0
WARNINGS=0

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((CRITICAL_FAILURES++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

check_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

################################################################################
# System Checks
################################################################################

check_os() {
    print_header "Operating System"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        check_pass "Linux detected"
        
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            check_info "Distribution: $NAME $VERSION"
        fi
        
        if command -v apt &> /dev/null; then
            check_info "Package manager: apt (Debian/Ubuntu)"
        elif command -v yum &> /dev/null; then
            check_info "Package manager: yum (RHEL/CentOS)"
        elif command -v dnf &> /dev/null; then
            check_info "Package manager: dnf (Fedora)"
        elif command -v pacman &> /dev/null; then
            check_info "Package manager: pacman (Arch)"
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        check_pass "macOS detected"
        
        local macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
        check_info "macOS version: $macos_version"
        
        if command -v brew &> /dev/null; then
            check_info "Homebrew is installed"
        else
            check_warn "Homebrew not found (recommended for macOS)"
            check_info "Install from: https://brew.sh"
        fi
        
    else
        check_fail "Unsupported operating system: $OSTYPE"
        check_info "Supported: Linux, macOS"
    fi
}

check_ram() {
    print_header "Memory (RAM)"
    
    local total_ram
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        total_ram=$(free -g | awk '/^Mem:/{print $2}')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        total_ram=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    fi
    
    if [ "$total_ram" -ge "$RECOMMENDED_RAM_GB" ]; then
        check_pass "RAM: ${total_ram}GB (recommended: ${RECOMMENDED_RAM_GB}GB+)"
        check_info "Can run: Qwen 2.5 Coder 32B, DeepSeek V2 16B"
    elif [ "$total_ram" -ge "$MIN_RAM_GB" ]; then
        check_pass "RAM: ${total_ram}GB (minimum: ${MIN_RAM_GB}GB)"
        check_warn "Limited to smaller models (7B-14B)"
        check_info "Can run: Qwen 2.5 Coder 7B, DeepSeek 6.7B"
    else
        check_fail "RAM: ${total_ram}GB (minimum: ${MIN_RAM_GB}GB required)"
        check_info "Upgrade RAM or use cloud-based models only"
    fi
}

check_disk() {
    print_header "Disk Space"
    
    local available_disk=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$available_disk" -ge 50 ]; then
        check_pass "Disk space: ${available_disk}GB (plenty of space)"
    elif [ "$available_disk" -ge "$MIN_DISK_GB" ]; then
        check_pass "Disk space: ${available_disk}GB (minimum: ${MIN_DISK_GB}GB)"
        check_warn "Limited space for multiple large models"
    else
        check_fail "Disk space: ${available_disk}GB (minimum: ${MIN_DISK_GB}GB required)"
        check_info "Free up disk space before installation"
    fi
    
    # Check home directory is writable
    if [ -w "$HOME" ]; then
        check_pass "Home directory is writable"
    else
        check_fail "Home directory is not writable: $HOME"
    fi
}

check_gpu() {
    print_header "GPU (Optional)"
    
    if command -v nvidia-smi &> /dev/null; then
        local gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -1)
        if [ -n "$gpu_info" ]; then
            check_pass "NVIDIA GPU detected: $gpu_info"
            
            local vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
            local vram_gb=$(( vram / 1024 ))
            
            if [ "$vram_gb" -ge 24 ]; then
                check_info "Can run: 32B+ models on GPU (fast)"
            elif [ "$vram_gb" -ge 16 ]; then
                check_info "Can run: 16B models on GPU (fast)"
            elif [ "$vram_gb" -ge 8 ]; then
                check_info "Can run: 7B models on GPU (fast)"
            else
                check_warn "GPU VRAM: ${vram_gb}GB (limited)"
            fi
        fi
    else
        check_info "No NVIDIA GPU detected (will use CPU)"
        check_info "CPU inference is slower but works fine"
    fi
}

check_dependencies() {
    print_header "Required Dependencies"
    
    local required=("curl" "git" "jq")
    local missing=()
    
    for cmd in "${required[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            local version=$($cmd --version 2>&1 | head -1 || echo "installed")
            check_pass "$cmd: $version"
        else
            check_fail "$cmd: not installed"
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        check_info "Install missing dependencies:"
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt &> /dev/null; then
                echo "  sudo apt update && sudo apt install -y ${missing[*]}"
            elif command -v yum &> /dev/null; then
                echo "  sudo yum install -y ${missing[*]}"
            elif command -v dnf &> /dev/null; then
                echo "  sudo dnf install -y ${missing[*]}"
            elif command -v pacman &> /dev/null; then
                echo "  sudo pacman -S ${missing[*]}"
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  brew install ${missing[*]}"
        fi
    fi
}

check_network() {
    print_header "Network Connectivity"
    
    # Check internet connection
    if curl -s --connect-timeout 5 https://ollama.com &> /dev/null; then
        check_pass "Internet connection: OK"
    else
        check_fail "Cannot reach ollama.com"
        check_info "Internet connection required for installation"
    fi
    
    # Check GitHub access
    if curl -s --connect-timeout 5 https://github.com &> /dev/null; then
        check_pass "GitHub access: OK"
    else
        check_warn "Cannot reach github.com"
        check_info "May affect git operations"
    fi
}

check_existing_installations() {
    print_header "Existing Installations"
    
    # Check Ollama
    if command -v ollama &> /dev/null; then
        local ollama_version=$(ollama --version 2>/dev/null || echo "unknown")
        check_info "Ollama already installed: $ollama_version"
        
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            check_pass "Ollama service is running"
            
            local model_count=$(curl -s http://localhost:11434/api/tags | jq -r '.models | length' 2>/dev/null || echo "0")
            if [ "$model_count" -gt 0 ]; then
                check_info "Ollama has $model_count model(s) installed"
            fi
        else
            check_warn "Ollama installed but service not running"
        fi
    else
        check_info "Ollama not installed (will be installed)"
    fi
    
    # Check VSCode
    if command -v code &> /dev/null; then
        local vscode_version=$(code --version 2>/dev/null | head -1 || echo "unknown")
        check_info "VSCode already installed: $vscode_version"
    else
        check_info "VSCode not installed (manual installation recommended)"
    fi
    
    # Check existing config
    if [ -f "${HOME}/.continue/config.json" ]; then
        check_info "Continue config exists (will be backed up)"
    fi
    
    if [ -d "${HOME}/.ai-coding-stack" ]; then
        check_info "Previous installation detected at ~/.ai-coding-stack"
        check_warn "Existing data will be preserved"
    fi
}

check_shell() {
    print_header "Shell Environment"
    
    check_info "Shell: $SHELL"
    check_info "User: $USER"
    check_info "Home: $HOME"
    
    # Check shell config files
    local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    for config in "${shell_configs[@]}"; do
        if [ -f "$config" ]; then
            check_info "Found: $(basename "$config")"
        fi
    done
}

################################################################################
# Recommendations
################################################################################

provide_recommendations() {
    print_header "Recommendations"
    
    local total_ram
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        total_ram=$(free -g | awk '/^Mem:/{print $2}')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        total_ram=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    fi
    
    echo "Based on your system (${total_ram}GB RAM):"
    echo ""
    
    if [ "$total_ram" -ge 32 ]; then
        echo "✓ Recommended models:"
        echo "  - qwen2.5-coder:32b (primary)"
        echo "  - deepseek-coder-v2:16b (backup)"
        echo "  - codellama:34b (autocomplete)"
        echo ""
        echo "  Installation command:"
        echo "  ollama pull qwen2.5-coder:32b"
        echo "  ollama pull deepseek-coder-v2:16b"
        
    elif [ "$total_ram" -ge 16 ]; then
        echo "✓ Recommended models:"
        echo "  - qwen2.5-coder:14b (primary)"
        echo "  - deepseek-coder:6.7b (backup)"
        echo ""
        echo "  Installation command:"
        echo "  ollama pull qwen2.5-coder:14b"
        echo "  ollama pull deepseek-coder:6.7b"
        
    else
        echo "✓ Recommended models:"
        echo "  - qwen2.5-coder:7b (primary)"
        echo "  - deepseek-coder:6.7b (backup)"
        echo ""
        echo "  Installation command:"
        echo "  ollama pull qwen2.5-coder:7b"
        echo "  ollama pull deepseek-coder:6.7b"
    fi
    
    echo ""
    echo "Optional enhancements:"
    
    if ! command -v code &> /dev/null; then
        echo "  - Install VSCode: https://code.visualstudio.com/"
    fi
    
    if ! command -v nvidia-smi &> /dev/null; then
        echo "  - Consider GPU for faster inference"
    fi
    
    if [ "$total_ram" -lt "$RECOMMENDED_RAM_GB" ]; then
        echo "  - Upgrade RAM to ${RECOMMENDED_RAM_GB}GB+ for better performance"
    fi
}

################################################################################
# Summary
################################################################################

print_summary() {
    print_header "Pre-Flight Check Summary"
    
    if [ "$CRITICAL_FAILURES" -eq 0 ]; then
        echo -e "${GREEN}✓ System is ready for installation!${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Run: ./install.sh"
        echo "  2. Follow the installation prompts"
        echo "  3. Configure VSCode extensions"
        echo ""
        
        if [ "$WARNINGS" -gt 0 ]; then
            echo -e "${YELLOW}Note: $WARNINGS warning(s) detected${NC}"
            echo "Installation will proceed but some features may be limited"
            echo ""
        fi
        
        return 0
    else
        echo -e "${RED}✗ $CRITICAL_FAILURES critical issue(s) found${NC}"
        echo ""
        echo "Please fix the issues above before installation"
        echo ""
        return 1
    fi
}

################################################################################
# Main
################################################################################

main() {
    echo "════════════════════════════════════════════════════════════"
    echo "  Ultimate AI Coding Stack - Pre-Flight Check"
    echo "════════════════════════════════════════════════════════════"
    
    check_os
    check_ram
    check_disk
    check_gpu
    check_dependencies
    check_network
    check_existing_installations
    check_shell
    
    echo ""
    provide_recommendations
    echo ""
    print_summary
}

main "$@"

