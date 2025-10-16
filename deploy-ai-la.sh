#!/bin/bash

#############################################
# AI-LA Complete Deployment Script
# 
# This script installs and configures AI-LA
# on your local machine or server.
#
# Supports: macOS, Ubuntu, Debian, Fedora
#############################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.ai-la"
VSCODE_EXT_DIR="$HOME/.vscode/extensions/ai-la"
OLLAMA_MODEL="qwen2.5-coder:7b"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "$ID"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

install_dependencies() {
    local os=$(detect_os)
    
    print_header "Installing Dependencies"
    
    case $os in
        macos)
            print_info "Installing via Homebrew..."
            brew install python3 git curl || true
            ;;
        ubuntu|debian)
            print_info "Installing via apt..."
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip git curl
            ;;
        fedora)
            print_info "Installing via dnf..."
            sudo dnf install -y python3 python3-pip git curl
            ;;
        *)
            print_error "Unsupported OS: $os"
            exit 1
            ;;
    esac
    
    print_success "Dependencies installed"
}

install_ollama() {
    print_header "Installing Ollama"
    
    if check_command ollama; then
        print_info "Ollama already installed"
        return 0
    fi
    
    print_info "Downloading and installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    
    print_success "Ollama installed"
}

start_ollama() {
    print_header "Starting Ollama Service"
    
    # Check if Ollama is running
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        print_info "Ollama is already running"
        return 0
    fi
    
    print_info "Starting Ollama..."
    
    # Start Ollama in background
    if [[ $(detect_os) == "macos" ]]; then
        open -a Ollama || ollama serve &> /dev/null &
    else
        ollama serve &> /dev/null &
    fi
    
    # Wait for Ollama to start
    print_info "Waiting for Ollama to start..."
    for i in {1..30}; do
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            print_success "Ollama is running"
            return 0
        fi
        sleep 1
    done
    
    print_error "Ollama failed to start"
    return 1
}

download_model() {
    print_header "Downloading AI Model"
    
    print_info "Checking if model $OLLAMA_MODEL exists..."
    
    if ollama list | grep -q "$OLLAMA_MODEL"; then
        print_info "Model already downloaded"
        return 0
    fi
    
    print_info "Downloading $OLLAMA_MODEL (this may take a few minutes)..."
    ollama pull $OLLAMA_MODEL
    
    print_success "Model downloaded"
}

install_ai_la() {
    print_header "Installing AI-LA"
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Clone or update repository
    if [ -d "$INSTALL_DIR/.git" ]; then
        print_info "Updating AI-LA..."
        cd "$INSTALL_DIR"
        git pull origin main
    else
        print_info "Cloning AI-LA repository..."
        git clone https://github.com/resetroot99/ai-la.git "$INSTALL_DIR"
    fi
    
    cd "$INSTALL_DIR"
    
    # Install Python dependencies
    print_info "Installing Python dependencies..."
    pip3 install --user -r requirements.txt 2>/dev/null || pip3 install --user flask fastapi sqlalchemy requests
    
    print_success "AI-LA installed to $INSTALL_DIR"
}

setup_vscode_extension() {
    print_header "Setting Up VS Code Extension"
    
    if ! check_command code; then
        print_info "VS Code not found, skipping extension setup"
        return 0
    fi
    
    # Create extension directory
    mkdir -p "$VSCODE_EXT_DIR"
    
    # Copy extension files
    if [ -d "$INSTALL_DIR/vscode-extension" ]; then
        print_info "Copying VS Code extension..."
        cp -r "$INSTALL_DIR/vscode-extension/"* "$VSCODE_EXT_DIR/"
        
        # Install extension dependencies
        if [ -f "$VSCODE_EXT_DIR/package.json" ]; then
            cd "$VSCODE_EXT_DIR"
            if check_command pnpm; then
                pnpm install
            elif check_command npm; then
                npm install
            fi
        fi
        
        print_success "VS Code extension set up"
    else
        print_info "VS Code extension not found in repository"
    fi
}

create_cli_wrapper() {
    print_header "Creating CLI Wrapper"
    
    local cli_path="$HOME/.local/bin/ai-la"
    mkdir -p "$HOME/.local/bin"
    
    cat > "$cli_path" << 'EOF'
#!/bin/bash
# AI-LA CLI Wrapper

INSTALL_DIR="$HOME/.ai-la"

case "$1" in
    analyze|archaeology)
        python3 "$INSTALL_DIR/code-archaeology-v2.py" "${2:-.}"
        ;;
    learn|adaptive)
        python3 "$INSTALL_DIR/adaptive-learning-v2.py" "${2:-.}"
        ;;
    generate|build)
        python3 "$INSTALL_DIR/ai-la-minimal.py" "$2"
        ;;
    chat|web)
        cd "$INSTALL_DIR/ai-la-chat-app"
        python3 app.py
        ;;
    help|--help|-h)
        echo "AI-LA - Autonomous AI Development Platform"
        echo ""
        echo "Usage:"
        echo "  ai-la analyze [path]     - Analyze codebase"
        echo "  ai-la learn [path]       - Learn coding style"
        echo "  ai-la generate <prompt>  - Generate code"
        echo "  ai-la chat               - Start web interface"
        echo "  ai-la help               - Show this help"
        echo ""
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run 'ai-la help' for usage"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$cli_path"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
    fi
    
    print_success "CLI wrapper created at $cli_path"
}

run_tests() {
    print_header "Running Tests"
    
    cd "$INSTALL_DIR"
    
    # Test Code Archaeology
    print_info "Testing Code Archaeology..."
    if python3 code-archaeology-v2.py . &> /tmp/ai-la-test-archaeology.log; then
        print_success "Code Archaeology works"
    else
        print_error "Code Archaeology failed (see /tmp/ai-la-test-archaeology.log)"
    fi
    
    # Test Adaptive Learning
    print_info "Testing Adaptive Learning..."
    if python3 adaptive-learning-v2.py . &> /tmp/ai-la-test-learning.log; then
        print_success "Adaptive Learning works"
    else
        print_error "Adaptive Learning failed (see /tmp/ai-la-test-learning.log)"
    fi
    
    # Test Code Generation
    print_info "Testing Code Generation..."
    if python3 ai-la-minimal.py "Build a simple REST API" &> /tmp/ai-la-test-generation.log; then
        print_success "Code Generation works"
    else
        print_error "Code Generation failed (see /tmp/ai-la-test-generation.log)"
    fi
}

print_usage_guide() {
    print_header "Installation Complete!"
    
    echo ""
    echo "AI-LA has been successfully installed!"
    echo ""
    echo "Quick Start:"
    echo ""
    echo "1. Analyze a codebase:"
    echo "   ai-la analyze /path/to/project"
    echo ""
    echo "2. Learn your coding style:"
    echo "   ai-la learn /path/to/your/code"
    echo ""
    echo "3. Generate code:"
    echo "   ai-la generate \"Build a REST API for user management\""
    echo ""
    echo "4. Start web interface:"
    echo "   ai-la chat"
    echo "   Then open: http://localhost:5001"
    echo ""
    echo "Documentation: https://github.com/resetroot99/ai-la"
    echo ""
    echo "Installation directory: $INSTALL_DIR"
    echo ""
    
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo -e "${YELLOW}Note: Please restart your terminal or run:${NC}"
        echo "  source ~/.bashrc  # or ~/.zshrc"
        echo ""
    fi
}

# Main installation flow
main() {
    clear
    print_header "AI-LA Installation"
    echo ""
    echo "This script will install AI-LA and its dependencies."
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
    
    echo ""
    
    # Installation steps
    install_dependencies
    install_ollama
    start_ollama
    download_model
    install_ai_la
    setup_vscode_extension
    create_cli_wrapper
    run_tests
    
    echo ""
    print_usage_guide
}

# Run main function
main

