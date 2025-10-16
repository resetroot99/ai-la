#!/bin/bash

################################################################################
# Autonomous Development Platform - Installation Script
# Installs all open-source dependencies
################################################################################

set -e

echo "🤖 Installing Autonomous Development Platform..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.8+"
    exit 1
fi

echo -e "${BLUE}✓ Python found: $(python3 --version)${NC}"

# Install Aider (core autonomous coding tool)
echo ""
echo "📦 Installing Aider..."
pip3 install aider-chat --upgrade

# Install Python dependencies
echo ""
echo "📦 Installing Python dependencies..."
pip3 install -r requirements-autonomous.txt

# Check Ollama
if ! command -v ollama &> /dev/null; then
    echo ""
    echo "⚠️  Ollama not found. Installing..."
    curl -fsSL https://ollama.ai/install.sh | sh
fi

echo -e "${BLUE}✓ Ollama installed${NC}"

# Pull required models
echo ""
echo "🤖 Pulling AI models..."
ollama pull qwen2.5-coder:7b
ollama pull codellama:7b

# Check Docker
if ! command -v docker &> /dev/null; then
    echo ""
    echo "⚠️  Docker not found. Please install Docker:"
    echo "   https://docs.docker.com/get-docker/"
fi

# Make autonomous agent executable
chmod +x autonomous-agent.py

# Create symlink
INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"
ln -sf "$(pwd)/autonomous-agent.py" "${INSTALL_DIR}/autonomous-agent"

# Add to PATH if needed
if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
    echo "export PATH=\"\$PATH:${INSTALL_DIR}\"" >> "${HOME}/.bashrc"
    echo "export PATH=\"\$PATH:${INSTALL_DIR}\"" >> "${HOME}/.zshrc" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo "🚀 Quick Start:"
echo ""
echo "  autonomous-agent \"Build a secure REST API with JWT authentication\""
echo ""
echo "📚 Examples:"
echo ""
echo "  # Build a Next.js app"
echo "  autonomous-agent \"Create a Next.js dashboard with Supabase auth\""
echo ""
echo "  # Build a FastAPI backend"
echo "  autonomous-agent \"Build FastAPI microservice for user management\""
echo ""
echo "  # Build full-stack app"
echo "  autonomous-agent \"Create a task management app with React and PostgreSQL\""
echo ""
echo "💡 The agent will:"
echo "  1. Parse your description"
echo "  2. Design architecture"
echo "  3. Generate all code"
echo "  4. Set up infrastructure"
echo "  5. Deploy locally"
echo "  6. Run tests"
echo "  7. Learn from the process"
echo ""
echo "Note: Restart your terminal or run: source ~/.bashrc"
echo ""

