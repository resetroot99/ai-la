# Ultimate AI Coding Stack

**A complete, open-source AI-powered development environment with persistent memory and zero cost.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

---

## 🎯 What is This?

The Ultimate AI Coding Stack is a fully automated setup that gives you:

- **Persistent AI Memory** - Your AI assistant remembers your coding patterns, preferences, and project context across sessions
- **Zero Cost** - Uses local open-source models (or cheap APIs if you prefer)
- **No Vendor Lock-in** - Completely open-source and self-hosted
- **Better than Cursor** - More powerful context management and customization
- **Production Ready** - Includes failsafes, health checks, and automatic recovery

## ✨ Features

### 🧠 Persistent Memory System
- **Developer Behavior Learning** - Automatically learns your coding patterns from your codebase
- **Pattern Recognition** - Identifies and remembers your preferred architectures, naming conventions, and code styles
- **Import/Export** - Import patterns from OpenAI, Cursor, GitHub Copilot, or custom JSON
- **Git Analysis** - Learns from your commit history and work patterns
- **Cross-Project Memory** - Share learned patterns across all your projects

### 🤖 AI Models
- **Local Models** - Run powerful coding models on your machine (Qwen 2.5 Coder, DeepSeek Coder, Code Llama)
- **Hybrid Mode** - Use local models for routine tasks, cloud APIs for complex ones
- **Model Auto-Selection** - Automatically picks the best model based on your hardware
- **Unlimited Usage** - No rate limits when using local models

### 🛠️ Tools & Extensions
- **Cline** - Autonomous coding with Memory Bank integration
- **Continue** - Flexible chat interface with autocomplete
- **Tabby** - Self-hosted code completion server (optional)
- **VSCode Extensions** - Pre-configured quality tools (ESLint, Prettier, GitLens, etc.)

### 🔒 Safety & Reliability
- **Comprehensive Failsafes** - Checks system requirements, validates installations
- **Health Monitoring** - Continuous health checks for all components
- **Automatic Backups** - Backs up configurations before changes
- **Error Recovery** - Intelligent retry logic and fallback mechanisms

## 🚀 Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ultimate-ai-coding-stack/main/install.sh | bash
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/ultimate-ai-coding-stack.git
cd ultimate-ai-coding-stack

# Run the installer
./install.sh
```

The installer will:
1. ✅ Check system requirements
2. ✅ Install Ollama (if not present)
3. ✅ Download AI models (based on your RAM)
4. ✅ Install VSCode extensions
5. ✅ Configure Continue and Cline
6. ✅ Set up Memory Bank system
7. ✅ Run health checks

## 📋 System Requirements

### Minimum (Laptop)
- **RAM:** 8GB
- **Disk:** 20GB free space
- **OS:** Linux, macOS, or Windows (WSL2)
- **Models:** Qwen 2.5 Coder 7B, DeepSeek Coder 6.7B

### Recommended (Desktop)
- **RAM:** 32GB
- **Disk:** 50GB free space
- **GPU:** NVIDIA GPU with 16GB+ VRAM (optional but recommended)
- **Models:** Qwen 2.5 Coder 32B, DeepSeek Coder V2 16B

### Optimal (Workstation)
- **RAM:** 64GB+
- **GPU:** NVIDIA RTX 4090 or A100
- **Models:** All models including 70B variants

## 🧠 Developer Memory System

### Import Your Coding Patterns

```bash
# Import from OpenAI storage
./scripts/memory-manager.sh import-openai ~/Downloads/openai-storage.json

# Import from Cursor rules
./scripts/memory-manager.sh import-cursor ~/projects/my-app/.cursorrules

# Import from GitHub Copilot data
./scripts/memory-manager.sh import-copilot ~/Downloads/copilot-data.json

# Import custom JSON
./scripts/memory-manager.sh import-json ~/my-patterns.json
```

### Analyze Your Codebase

```bash
# Analyze a project to learn patterns
./scripts/memory-manager.sh analyze-codebase ~/projects/my-app

# Analyze git history
./scripts/memory-manager.sh analyze-git ~/projects/my-app
```

### Generate AI Instructions

```bash
# Generate personalized AI instructions from memory
./scripts/memory-manager.sh generate-instructions

# Generate personalized Continue config
./scripts/generate-continue-config.sh
```

### Export and Share

```bash
# Export all memory data
./scripts/memory-manager.sh export

# Export shareable patterns (anonymized)
./scripts/memory-manager.sh export-shareable
```

## 📁 Memory Data Format

The system uses a structured JSON format to store developer patterns:

```json
{
  "coding_patterns": [
    {
      "pattern_type": "naming_convention",
      "pattern": "Use descriptive, action-oriented function names",
      "context": "All JavaScript/TypeScript functions",
      "confidence": "high",
      "examples": ["async function fetchUserData(userId) { ... }"]
    }
  ],
  "preferences": {
    "languages": ["TypeScript", "Python"],
    "frameworks": ["Next.js", "FastAPI"],
    "code_style": {
      "indentation": "2_spaces",
      "quotes": "single",
      "semicolons": false
    }
  },
  "behaviors": {
    "testing_approach": "test_after",
    "documentation_style": "inline_comments"
  }
}
```

See [configs/memory-schema.json](configs/memory-schema.json) for the complete schema.

## 🎓 Usage

### Basic Workflow

1. **Initialize a project with Memory Bank:**
   ```bash
   cp -r ~/.ai-coding-stack/templates/default-project/* ~/my-new-project/
   cd ~/my-new-project
   ```

2. **Open in VSCode:**
   ```bash
   code .
   ```

3. **Start coding with AI:**
   - Use **Cline** for autonomous multi-file editing
   - Use **Continue** for chat and autocomplete
   - AI automatically follows your learned patterns

4. **Update memory after significant work:**
   ```bash
   ./scripts/memory-manager.sh analyze-codebase .
   ./scripts/generate-continue-config.sh
   ```

### Advanced Usage

#### Custom Memory Import

Create a JSON file with your patterns:

```json
{
  "coding_patterns": [
    {
      "pattern_type": "error_handling",
      "pattern": "Always use try-catch with specific error types",
      "language": "TypeScript",
      "confidence": "high"
    }
  ]
}
```

Import it:
```bash
./scripts/memory-manager.sh import-json my-patterns.json
```

#### Team Collaboration

Share your patterns with your team:

```bash
# Export shareable patterns
./scripts/memory-manager.sh export-shareable

# Share the exported file with team
# They can import it:
./scripts/memory-manager.sh import-json shared-patterns.json
```

## 🔧 Configuration

### Continue Configuration

Located at `~/.continue/config.json`. Automatically generated with your preferences:

```json
{
  "models": [
    {
      "title": "Primary Model (Personalized)",
      "provider": "ollama",
      "model": "qwen2.5-coder:32b",
      "systemMessage": "Your learned patterns and preferences..."
    }
  ],
  "customCommands": [
    {
      "name": "refactor",
      "prompt": "Refactor following my established patterns...",
      "description": "Refactor code using learned patterns"
    }
  ]
}
```

### Cline Configuration

Memory Bank instructions located at `~/.ai-coding-stack/memory-bank-instructions.md`.

To use:
1. Open Cline settings in VSCode
2. Find "Custom Instructions"
3. Copy contents from the instructions file

## 📊 Performance Benchmarks

### Model Performance (HumanEval)

| Model | Score | Speed | VRAM | Cost |
|-------|-------|-------|------|------|
| Qwen 2.5 Coder 32B | 92.3% | Medium | 24GB | $0 |
| DeepSeek Coder V2 16B | 90.2% | Fast | 16GB | $0 |
| Qwen 2.5 Coder 7B | 87.0% | Fast | 8GB | $0 |
| Code Llama 34B | 48.8% | Medium | 24GB | $0 |

### Cost Comparison

| Solution | Monthly Cost | Limitations |
|----------|--------------|-------------|
| **This Stack** | $0-5 | None (unlimited local) |
| Cursor | $20 | 500 completions/month |
| GitHub Copilot | $10-39 | Rate limits |
| Tabnine Pro | $12 | Limited features |

**Annual Savings: $120-468**

## 🏗️ Architecture

```
Ultimate AI Coding Stack
│
├── Ollama (Model Server)
│   ├── Qwen 2.5 Coder (Primary)
│   ├── DeepSeek Coder (Backup)
│   └── Code Llama (Autocomplete)
│
├── VSCode Extensions
│   ├── Cline (Autonomous Coding)
│   ├── Continue (Chat & Autocomplete)
│   └── Quality Tools (ESLint, Prettier, etc.)
│
├── Memory System
│   ├── Pattern Recognition
│   ├── Preference Learning
│   ├── Behavior Analysis
│   └── Cross-Project Sharing
│
└── Configuration
    ├── Auto-generated Continue config
    ├── Memory Bank instructions
    └── Project templates
```

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) first.

### Development Setup

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/ultimate-ai-coding-stack.git
cd ultimate-ai-coding-stack

# Run tests
./tests/run-tests.sh

# Submit PR
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Ollama](https://ollama.com) - Local model hosting
- [Qwen Team](https://qwenlm.github.io) - Qwen 2.5 Coder models
- [DeepSeek](https://www.deepseek.com) - DeepSeek Coder models
- [Cline](https://cline.bot) - Autonomous coding assistant
- [Continue](https://continue.dev) - Open-source AI assistant
- The open-source AI community

## 📚 Documentation

- [Installation Guide](docs/installation.md)
- [Memory System Guide](docs/memory-system.md)
- [Configuration Guide](docs/configuration.md)
- [Troubleshooting](docs/troubleshooting.md)
- [API Reference](docs/api-reference.md)

## 🐛 Troubleshooting

### Common Issues

**Models running slowly?**
```bash
# Use smaller model
ollama pull qwen2.5-coder:7b
```

**Ollama not connecting?**
```bash
# Check if Ollama is running
ollama list

# Restart Ollama
killall ollama
ollama serve
```

**Memory import failed?**
```bash
# Validate JSON
jq empty your-file.json

# Check logs
tail -f ~/.ai-coding-stack/install.log
```

## 🔗 Links

- **Documentation:** [docs/](docs/)
- **Issues:** [GitHub Issues](https://github.com/YOUR_USERNAME/ultimate-ai-coding-stack/issues)
- **Discussions:** [GitHub Discussions](https://github.com/YOUR_USERNAME/ultimate-ai-coding-stack/discussions)

## ⭐ Star History

If you find this project useful, please consider giving it a star!

---

**Built with ❤️ by the open-source community**

*Last Updated: October 16, 2025*


## 🔬 Enhanced Installation Features

### Pre-Flight Validation

Before installation, run a comprehensive system check:

```bash
./scripts/preflight-check.sh
```

This validates:
- ✅ Operating system compatibility
- ✅ RAM and disk space requirements
- ✅ GPU detection (optional)
- ✅ Required dependencies
- ✅ Network connectivity
- ✅ Existing installations

### Dry-Run Mode

Preview what will be installed without making any changes:

```bash
./install-enhanced.sh --dry-run
```

Perfect for:
- Understanding installation steps
- Verifying system compatibility
- Safe exploration before committing

### Installation Options

```bash
# Standard installation (recommended)
./install-enhanced.sh

# Preview without changes
./install-enhanced.sh --dry-run

# Force install (skip checks)
./install-enhanced.sh --force

# Skip pre-flight validation
./install-enhanced.sh --skip-preflight
```

### Verification & Auto-Fix

After installation, verify and fix any issues:

```bash
# Interactive menu
./scripts/verify-and-fix.sh

# Auto-verify all components
./scripts/verify-and-fix.sh --verify-all

# Run health check
./scripts/verify-and-fix.sh --health-check

# Rollback installation
./scripts/verify-and-fix.sh --rollback
```

### Comprehensive Testing

Run the full test suite:

```bash
cd tests
./test-install.sh
```

Tests include:
- Script syntax validation
- JSON configuration validation
- Installation verification
- Integration tests
- Performance tests
- Security checks
- Documentation completeness

## 🛡️ Safety Features

### Automatic Backups
- All configurations backed up before changes
- Timestamped backup directories
- Easy rollback with one command

### Graceful Degradation
- Missing components handled gracefully
- Appropriate models selected based on RAM
- Clear error messages with solutions

### Error Recovery
- Automatic retry logic
- Service health monitoring
- Self-healing capabilities

### Comprehensive Logging
- All actions logged to `~/.ai-coding-stack/install.log`
- Detailed error context
- Easy troubleshooting

## 📊 Validation Status

✅ **All scripts syntax validated**  
✅ **All JSON configs validated**  
✅ **Comprehensive test coverage**  
✅ **Security audit passed**  
✅ **Cross-platform tested (Linux, macOS)**  
✅ **Production ready**

See [VALIDATION_REPORT.md](VALIDATION_REPORT.md) for complete validation details.

