#!/bin/bash

################################################################################
# Ultimate AI Coding Stack - Interactive Setup Wizard
# User-friendly guided installation with smart defaults
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${HOME}/.ai-coding-stack"
LOG_FILE="${INSTALL_DIR}/setup-wizard.log"

# User choices
INSTALL_OLLAMA="auto"
INSTALL_MODELS="auto"
INSTALL_VSCODE_EXTENSIONS="auto"
SETUP_MEMORY="yes"
IMPORT_PATTERNS="ask"

mkdir -p "$INSTALL_DIR"

################################################################################
# UI Functions
################################################################################

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🚀 Ultimate AI Coding Stack - Setup Wizard 🚀           ║
║                                                              ║
║     The easiest way to set up your AI coding environment    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

print_step() {
    echo ""
    echo -e "${BOLD}${CYAN}▶ $1${NC}"
    echo -e "${CYAN}$( printf '─%.0s' {1..60} )${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

ask_yes_no() {
    local question="$1"
    local default="${2:-y}"
    
    if [ "$default" = "y" ]; then
        local prompt="[Y/n]"
    else
        local prompt="[y/N]"
    fi
    
    while true; do
        read -p "$(echo -e ${CYAN}❓ $question $prompt: ${NC})" answer
        answer=${answer:-$default}
        
        case ${answer:0:1} in
            y|Y )
                return 0
                ;;
            n|N )
                return 1
                ;;
            * )
                echo "Please answer yes or no."
                ;;
        esac
    done
}

ask_choice() {
    local question="$1"
    shift
    local options=("$@")
    
    echo -e "${CYAN}❓ $question${NC}"
    echo ""
    
    for i in "${!options[@]}"; do
        echo -e "  ${BOLD}$((i+1)).${NC} ${options[$i]}"
    done
    echo ""
    
    while true; do
        read -p "$(echo -e ${CYAN}Enter choice [1-${#options[@]}]: ${NC})" choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            return $((choice-1))
        else
            echo "Invalid choice. Please enter a number between 1 and ${#options[@]}."
        fi
    done
}

show_progress() {
    local current=$1
    local total=$2
    local message="$3"
    
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] ${percent}%% - ${message}${NC}"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

################################################################################
# System Detection
################################################################################

detect_system() {
    print_step "Step 1/6: Detecting Your System"
    
    # OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS_NAME="$NAME"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        OS_NAME="macOS $(sw_vers -productVersion)"
    else
        OS="Unknown"
        OS_NAME="$OSTYPE"
    fi
    
    # RAM
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        RAM=$(free -g | awk '/^Mem:/{print $2}')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        RAM=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    fi
    
    # Disk
    DISK=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    
    # GPU
    if command -v nvidia-smi &> /dev/null; then
        GPU=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
        VRAM_GB=$(( VRAM / 1024 ))
    else
        GPU="None"
        VRAM_GB=0
    fi
    
    # Display results
    echo -e "${BOLD}System Information:${NC}"
    echo ""
    print_info "OS: $OS_NAME"
    print_info "RAM: ${RAM}GB"
    print_info "Disk Space: ${DISK}GB available"
    
    if [ "$GPU" != "None" ]; then
        print_info "GPU: $GPU (${VRAM_GB}GB VRAM)"
    else
        print_info "GPU: None detected (CPU mode)"
    fi
    
    echo ""
    
    # Recommendations
    if [ "$RAM" -ge 32 ]; then
        RECOMMENDED_MODEL="qwen2.5-coder:32b"
        PERFORMANCE="Excellent"
    elif [ "$RAM" -ge 16 ]; then
        RECOMMENDED_MODEL="qwen2.5-coder:14b"
        PERFORMANCE="Good"
    elif [ "$RAM" -ge 8 ]; then
        RECOMMENDED_MODEL="qwen2.5-coder:7b"
        PERFORMANCE="Adequate"
    else
        RECOMMENDED_MODEL="Cloud-based only"
        PERFORMANCE="Limited"
        print_warning "Your system has less than 8GB RAM. Local models may not work well."
        print_info "Consider using cloud-based models instead."
    fi
    
    if [ "$RECOMMENDED_MODEL" != "Cloud-based only" ]; then
        print_success "Recommended model: $RECOMMENDED_MODEL"
        print_info "Expected performance: $PERFORMANCE"
    fi
    
    echo ""
    read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})"
}

################################################################################
# Installation Options
################################################################################

choose_installation_mode() {
    print_step "Step 2/6: Choose Installation Mode"
    
    echo -e "${BOLD}Select your installation preference:${NC}"
    echo ""
    
    ask_choice "What would you like to install?" \
        "🚀 Full Installation (Recommended) - Everything you need" \
        "⚡ Quick Setup - Minimal installation, get started fast" \
        "🎯 Custom - Choose exactly what to install" \
        "👀 Preview Only - See what would be installed (dry-run)"
    
    local mode=$?
    
    case $mode in
        0)
            INSTALL_MODE="full"
            INSTALL_OLLAMA="yes"
            INSTALL_MODELS="yes"
            INSTALL_VSCODE_EXTENSIONS="yes"
            SETUP_MEMORY="yes"
            ;;
        1)
            INSTALL_MODE="quick"
            INSTALL_OLLAMA="yes"
            INSTALL_MODELS="minimal"
            INSTALL_VSCODE_EXTENSIONS="ask"
            SETUP_MEMORY="yes"
            ;;
        2)
            INSTALL_MODE="custom"
            configure_custom_installation
            ;;
        3)
            INSTALL_MODE="preview"
            DRY_RUN=true
            ;;
    esac
    
    echo ""
}

configure_custom_installation() {
    echo ""
    echo -e "${BOLD}Custom Installation Configuration:${NC}"
    echo ""
    
    # Ollama
    if ask_yes_no "Install Ollama (AI model server)?" "y"; then
        INSTALL_OLLAMA="yes"
        
        # Models
        if ask_yes_no "Download AI models?" "y"; then
            ask_choice "Which models?" \
                "Recommended for my system ($RECOMMENDED_MODEL)" \
                "Smallest model (7B - fastest download)" \
                "Largest model (32B - best quality)" \
                "Let me choose later"
            
            case $? in
                0) INSTALL_MODELS="recommended" ;;
                1) INSTALL_MODELS="smallest" ;;
                2) INSTALL_MODELS="largest" ;;
                3) INSTALL_MODELS="skip" ;;
            esac
        else
            INSTALL_MODELS="skip"
        fi
    else
        INSTALL_OLLAMA="no"
        INSTALL_MODELS="skip"
    fi
    
    # VSCode
    if command -v code &> /dev/null; then
        if ask_yes_no "Install VSCode extensions?" "y"; then
            INSTALL_VSCODE_EXTENSIONS="yes"
        else
            INSTALL_VSCODE_EXTENSIONS="no"
        fi
    else
        INSTALL_VSCODE_EXTENSIONS="skip"
    fi
    
    # Memory
    if ask_yes_no "Set up developer memory system?" "y"; then
        SETUP_MEMORY="yes"
    else
        SETUP_MEMORY="no"
    fi
}

################################################################################
# Installation Summary
################################################################################

show_installation_summary() {
    print_step "Step 3/6: Installation Summary"
    
    echo -e "${BOLD}What will be installed:${NC}"
    echo ""
    
    if [ "$INSTALL_OLLAMA" = "yes" ]; then
        print_success "Ollama AI server"
    else
        print_info "Ollama: Skipped"
    fi
    
    if [ "$INSTALL_MODELS" != "skip" ]; then
        case $INSTALL_MODELS in
            "recommended")
                print_success "AI Model: $RECOMMENDED_MODEL (recommended)"
                ;;
            "smallest")
                print_success "AI Model: qwen2.5-coder:7b (smallest)"
                ;;
            "largest")
                print_success "AI Model: qwen2.5-coder:32b (largest)"
                ;;
            "minimal")
                print_success "AI Model: qwen2.5-coder:7b (quick setup)"
                ;;
            "yes")
                print_success "AI Model: $RECOMMENDED_MODEL"
                ;;
        esac
    else
        print_info "AI Models: Skipped"
    fi
    
    if [ "$INSTALL_VSCODE_EXTENSIONS" = "yes" ]; then
        print_success "VSCode Extensions: Continue + Cline"
    elif [ "$INSTALL_VSCODE_EXTENSIONS" = "skip" ]; then
        print_info "VSCode Extensions: VSCode not installed"
    else
        print_info "VSCode Extensions: Skipped"
    fi
    
    if [ "$SETUP_MEMORY" = "yes" ]; then
        print_success "Developer Memory System"
    else
        print_info "Memory System: Skipped"
    fi
    
    echo ""
    print_info "Installation directory: $INSTALL_DIR"
    print_info "Log file: $LOG_FILE"
    
    echo ""
    
    if [ "$INSTALL_MODE" = "preview" ]; then
        print_warning "PREVIEW MODE: No changes will be made"
    fi
    
    echo ""
    
    if ! ask_yes_no "Proceed with installation?" "y"; then
        echo ""
        print_info "Installation cancelled. Run this script again to start over."
        exit 0
    fi
}

################################################################################
# Installation
################################################################################

run_installation() {
    print_step "Step 4/6: Installing Components"
    
    local total_steps=5
    local current_step=0
    
    # Step 1: Ollama
    ((current_step++))
    show_progress $current_step $total_steps "Installing Ollama..."
    
    if [ "$INSTALL_OLLAMA" = "yes" ] && [ "$DRY_RUN" != true ]; then
        if ! command -v ollama &> /dev/null; then
            curl -fsSL https://ollama.com/install.sh | sh &>> "$LOG_FILE"
            
            # Start service
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open -a Ollama 2>/dev/null || ollama serve &> /dev/null &
            else
                ollama serve &> /dev/null &
            fi
            
            sleep 3
        fi
    fi
    
    # Step 2: Models
    ((current_step++))
    show_progress $current_step $total_steps "Downloading AI models..."
    
    if [ "$INSTALL_MODELS" != "skip" ] && [ "$DRY_RUN" != true ]; then
        local model_to_install
        
        case $INSTALL_MODELS in
            "recommended") model_to_install="$RECOMMENDED_MODEL" ;;
            "smallest") model_to_install="qwen2.5-coder:7b" ;;
            "largest") model_to_install="qwen2.5-coder:32b" ;;
            "minimal") model_to_install="qwen2.5-coder:7b" ;;
            "yes") model_to_install="$RECOMMENDED_MODEL" ;;
        esac
        
        ollama pull "$model_to_install" &>> "$LOG_FILE" &
        MODEL_PID=$!
    fi
    
    # Step 3: VSCode Extensions
    ((current_step++))
    show_progress $current_step $total_steps "Installing VSCode extensions..."
    
    if [ "$INSTALL_VSCODE_EXTENSIONS" = "yes" ] && [ "$DRY_RUN" != true ]; then
        code --install-extension continue.continue --force &>> "$LOG_FILE"
        code --install-extension saoudrizwan.claude-dev --force &>> "$LOG_FILE"
    fi
    
    # Step 4: Memory System
    ((current_step++))
    show_progress $current_step $total_steps "Setting up memory system..."
    
    if [ "$SETUP_MEMORY" = "yes" ] && [ "$DRY_RUN" != true ]; then
        mkdir -p "${INSTALL_DIR}/memory"
        
        if [ -f "./configs/memory-schema.json" ]; then
            cp "./configs/memory-schema.json" "${INSTALL_DIR}/memory/"
        fi
        
        if [ -f "./configs/memory-example.json" ]; then
            cp "./configs/memory-example.json" "${INSTALL_DIR}/memory/"
        fi
    fi
    
    # Step 5: Configuration
    ((current_step++))
    show_progress $current_step $total_steps "Generating configuration..."
    
    if [ "$DRY_RUN" != true ]; then
        # Wait for model download
        if [ -n "$MODEL_PID" ]; then
            wait $MODEL_PID 2>/dev/null || true
        fi
        
        # Generate Continue config
        if [ -f "./scripts/generate-continue-config.sh" ]; then
            ./scripts/generate-continue-config.sh &>> "$LOG_FILE"
        fi
    fi
    
    echo ""
    echo ""
}

################################################################################
# Import Patterns
################################################################################

import_existing_patterns() {
    print_step "Step 5/6: Import Your Coding Patterns (Optional)"
    
    echo -e "${BOLD}Would you like to import your existing coding patterns?${NC}"
    echo ""
    print_info "This helps the AI learn your coding style and preferences"
    echo ""
    
    if ! ask_yes_no "Import patterns now?" "n"; then
        print_info "You can import patterns later with: ./scripts/memory-manager.sh"
        return 0
    fi
    
    echo ""
    ask_choice "What would you like to import?" \
        "📁 Analyze an existing codebase" \
        "🔧 Import from OpenAI storage" \
        "📋 Import from Cursor rules" \
        "⏭️  Skip for now"
    
    case $? in
        0)
            echo ""
            read -p "$(echo -e ${CYAN}Enter path to your codebase: ${NC})" codebase_path
            
            if [ -d "$codebase_path" ]; then
                print_info "Analyzing codebase..."
                ./scripts/memory-manager.sh analyze-codebase "$codebase_path" &>> "$LOG_FILE"
                print_success "Patterns imported from codebase"
            else
                print_error "Directory not found: $codebase_path"
            fi
            ;;
        1)
            echo ""
            read -p "$(echo -e ${CYAN}Enter path to OpenAI storage JSON: ${NC})" json_path
            
            if [ -f "$json_path" ]; then
                ./scripts/memory-manager.sh import-openai "$json_path" &>> "$LOG_FILE"
                print_success "Patterns imported from OpenAI"
            else
                print_error "File not found: $json_path"
            fi
            ;;
        2)
            echo ""
            read -p "$(echo -e ${CYAN}Enter path to .cursorrules file: ${NC})" cursor_path
            
            if [ -f "$cursor_path" ]; then
                ./scripts/memory-manager.sh import-cursor "$cursor_path" &>> "$LOG_FILE"
                print_success "Patterns imported from Cursor"
            else
                print_error "File not found: $cursor_path"
            fi
            ;;
        3)
            print_info "Skipped pattern import"
            ;;
    esac
    
    echo ""
}

################################################################################
# Completion
################################################################################

show_completion() {
    print_step "Step 6/6: Setup Complete! 🎉"
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "This was a preview. No changes were made."
        echo ""
        print_info "Run without --dry-run to perform actual installation"
        return 0
    fi
    
    print_success "Installation completed successfully!"
    echo ""
    
    echo -e "${BOLD}${GREEN}✓ What's installed:${NC}"
    echo ""
    
    if [ "$INSTALL_OLLAMA" = "yes" ]; then
        print_success "Ollama AI server running"
    fi
    
    if [ "$INSTALL_MODELS" != "skip" ]; then
        print_success "AI models ready to use"
    fi
    
    if [ "$INSTALL_VSCODE_EXTENSIONS" = "yes" ]; then
        print_success "VSCode extensions installed"
    fi
    
    if [ "$SETUP_MEMORY" = "yes" ]; then
        print_success "Memory system configured"
    fi
    
    echo ""
    echo -e "${BOLD}${CYAN}🚀 Next Steps:${NC}"
    echo ""
    
    echo -e "${BOLD}1. Restart VSCode${NC}"
    print_info "   Close and reopen VSCode to load extensions"
    echo ""
    
    echo -e "${BOLD}2. Configure Cline (one-time)${NC}"
    print_info "   • Open VSCode"
    print_info "   • Click Cline icon in sidebar"
    print_info "   • Click settings (⚙️)"
    print_info "   • Copy instructions from: ${INSTALL_DIR}/memory-bank-instructions.md"
    echo ""
    
    echo -e "${BOLD}3. Start coding!${NC}"
    print_info "   Create a new project:"
    echo -e "   ${CYAN}cp -r ${INSTALL_DIR}/templates/default-project/* ~/my-project/${NC}"
    echo -e "   ${CYAN}cd ~/my-project && code .${NC}"
    echo ""
    
    echo -e "${BOLD}📚 Useful Commands:${NC}"
    echo ""
    print_info "Verify installation:    ./scripts/verify-and-fix.sh"
    print_info "Import patterns:        ./scripts/memory-manager.sh"
    print_info "Update config:          ./scripts/generate-continue-config.sh"
    print_info "View logs:              tail -f $LOG_FILE"
    echo ""
    
    echo -e "${BOLD}${GREEN}Happy coding with AI! 🚀${NC}"
    echo ""
}

################################################################################
# Main Flow
################################################################################

main() {
    # Check if dry-run flag
    if [ "${1:-}" = "--dry-run" ]; then
        DRY_RUN=true
    fi
    
    print_banner
    
    detect_system
    choose_installation_mode
    show_installation_summary
    run_installation
    
    if [ "$DRY_RUN" != true ]; then
        import_existing_patterns
    fi
    
    show_completion
}

main "$@"

