# Quick Start Guide

Get up and running with the Ultimate AI Coding Stack in 5 minutes.

## Prerequisites

- **OS:** Linux, macOS, or Windows (WSL2)
- **RAM:** 8GB minimum (16GB+ recommended)
- **Disk:** 20GB free space
- **Software:** curl, git, jq (installer will check)

## Installation

### Option 1: Automated Install (Recommended)

```bash
# Download and run installer
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ultimate-ai-coding-stack/main/install.sh | bash
```

### Option 2: Manual Install

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/ultimate-ai-coding-stack.git
cd ultimate-ai-coding-stack

# Run installer
./install.sh
```

The installer will:
-  Check system requirements
-  Install Ollama
-  Download AI models (based on your RAM)
-  Install VSCode extensions
-  Configure everything automatically

## First Steps

### 1. Import Your Coding Patterns (Optional)

```bash
# From OpenAI storage
./scripts/memory-manager.sh import-openai ~/Downloads/openai-storage.json

# From your codebase
./scripts/memory-manager.sh analyze-codebase ~/projects/my-app

# From git history
./scripts/memory-manager.sh analyze-git ~/projects/my-app
```

### 2. Generate Personalized Config

```bash
# Generate Continue config from your patterns
./scripts/generate-continue-config.sh
```

### 3. Start a New Project

```bash
# Copy template
cp -r ~/.ai-coding-stack/templates/default-project/* ~/my-new-project/
cd ~/my-new-project

# Open in VSCode
code .
```

### 4. Configure Cline (One-time)

1. Open VSCode
2. Click Cline icon in sidebar
3. Click settings ()
4. Find "Custom Instructions"
5. Copy contents from: `~/.ai-coding-stack/memory-bank-instructions.md`
6. Paste and save

## Usage

### Using Continue (Chat & Autocomplete)

1. Press `Cmd/Ctrl + L` to open Continue chat
2. Ask questions or request code
3. Tab autocomplete works automatically

**Example prompts:**
```
"Create a React component for user authentication"
"Refactor this function to be more efficient"
"Add error handling to this API call"
```

### Using Cline (Autonomous Coding)

1. Click Cline icon in sidebar
2. Describe what you want to build
3. Cline will plan and execute across multiple files

**Example prompts:**
```
"Initialize memory bank for a SaaS project with Next.js and Supabase"
"Implement user authentication with email verification"
"Add a dashboard with charts showing user analytics"
```

### Custom Commands in Continue

- `/refactor` - Refactor code using your patterns
- `/review` - Code review based on your preferences
- `/test` - Generate tests matching your style
- `/explain` - Explain code

## Verify Installation

```bash
# Check Ollama is running
ollama list

# Check installed models
curl -s http://localhost:11434/api/tags | jq -r '.models[].name'

# Check VSCode extensions
code --list-extensions | grep -E "continue|claude-dev"

# View memory summary
./scripts/memory-manager.sh show
```

## Common Commands

```bash
# Import patterns
./scripts/memory-manager.sh import-json patterns.json

# Analyze codebase
./scripts/memory-manager.sh analyze-codebase /path/to/project

# Export patterns
./scripts/memory-manager.sh export

# Generate AI instructions
./scripts/memory-manager.sh generate-instructions

# Update Continue config
./scripts/generate-continue-config.sh

# Health check
cd ~/.ai-coding-stack && ./install.sh  # Re-run for health check
```

## Troubleshooting

### Ollama not responding

```bash
# Check if running
curl http://localhost:11434/api/tags

# Restart Ollama
killall ollama
ollama serve
```

### Models not found

```bash
# List installed models
ollama list

# Pull a model manually
ollama pull qwen2.5-coder:7b
```

### VSCode extensions not working

```bash
# Reinstall extensions
code --install-extension continue.continue --force
code --install-extension saoudrizwan.claude-dev --force

# Restart VSCode
```

### Memory import failed

```bash
# Validate JSON
jq empty your-file.json

# Check logs
tail -f ~/.ai-coding-stack/install.log
```

## Next Steps

1. **Read the full guide:** [docs/complete-guide.md](docs/complete-guide.md)
2. **Explore open-source tools:** [docs/opensource-tools.md](docs/opensource-tools.md)
3. **Customize your setup:** Edit `~/.continue/config.json`
4. **Join the community:** GitHub Discussions

## Getting Help

- **Documentation:** [docs/](docs/)
- **Issues:** [GitHub Issues](https://github.com/YOUR_USERNAME/ultimate-ai-coding-stack/issues)
- **Discussions:** [GitHub Discussions](https://github.com/YOUR_USERNAME/ultimate-ai-coding-stack/discussions)

---

**Happy coding with AI! **

