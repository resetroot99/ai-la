# AI-LA Agent for VS Code

Autonomous AI development agent with cryptographic verification. Build entire features from natural language descriptions.

## Features

### Autonomous Feature Building

Simply describe what you want to build, and AI-LA Agent will:
- Analyze your project context
- Create an implementation plan
- Generate production-ready code
- Write tests automatically
- Create cryptographic receipts (TECP) for verification

### TECP Cryptographic Verification

Every operation is cryptographically verified and stored in an immutable chain. You can verify the integrity of all AI-generated code at any time.

### Local or Cloud

- **Local Mode (Free)**: Uses Ollama with local models. No cost, complete privacy.
- **Cloud Mode (Premium)**: Uses cloud APIs for more powerful models.

### Project Analysis

AI-LA Agent understands your entire project:
- Detects frameworks and languages
- Analyzes code patterns
- Learns your coding style
- Maintains context across sessions

## Getting Started

### Prerequisites

For local mode (free):
1. Install [Ollama](https://ollama.ai)
2. Pull a model: `ollama pull qwen2.5-coder:7b`

For cloud mode (premium):
1. Get an API key
2. Configure in settings: `ai-la.apiKey`

### Installation

1. Install from VS Code Marketplace
2. Open a project folder
3. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
4. Type "AI-LA: Build Feature"

## Usage

### Build a Feature

1. Press `Cmd+Shift+P` and select "AI-LA: Build Feature"
2. Describe what you want: "Add user authentication with JWT tokens"
3. Watch AI-LA build it autonomously
4. Review the generated code
5. Verify with TECP: "AI-LA: Verify Changes"

### Chat with AI-LA

1. Press `Cmd+Shift+P` and select "AI-LA: Open Chat"
2. Ask questions about your code
3. Get architectural advice
4. Request code improvements

### Analyze Your Project

1. Press `Cmd+Shift+P` and select "AI-LA: Analyze Project"
2. See comprehensive project analysis
3. Get improvement suggestions

## Configuration

### Settings

- `ai-la.model`: Choose "local" (free) or "cloud" (premium)
- `ai-la.localModel`: Local model to use (default: qwen2.5-coder:7b)
- `ai-la.enableTECP`: Enable cryptographic verification (default: true)
- `ai-la.apiKey`: API key for cloud mode

### Recommended Local Models

- **qwen2.5-coder:7b** - Fast, good quality (8GB RAM)
- **qwen2.5-coder:14b** - Better quality (16GB RAM)
- **qwen2.5-coder:32b** - Best quality (32GB RAM)

## Commands

- `AI-LA: Build Feature` - Build a complete feature autonomously
- `AI-LA: Open Chat` - Chat with AI-LA
- `AI-LA: Analyze Project` - Analyze your project
- `AI-LA: Verify Changes (TECP)` - Verify cryptographic receipts

## Sidebar Views

- **Chat** - Quick access to chat interface
- **Active Tasks** - See running tasks and progress
- **History (TECP)** - View verification history

## Why AI-LA Agent?

### vs GitHub Copilot
- **Autonomous**: Builds entire features, not just suggestions
- **Free**: Local mode costs $0/month
- **Verifiable**: TECP cryptographic receipts
- **Privacy**: Runs completely local

### vs Cursor
- **Open Source**: Transparent and auditable
- **Cheaper**: $0 vs $20/month
- **TECP**: Cryptographic verification
- **Local-first**: Complete privacy

### vs Other AI Assistants
- **Truly Autonomous**: Makes all decisions
- **Production-Ready**: Generates complete, tested code
- **Verifiable**: Mathematical proof of all operations
- **Context-Aware**: Understands your entire project

## Privacy

- **Local Mode**: All data stays on your machine
- **Cloud Mode**: Only sends prompts to API, no code storage
- **Telemetry**: Anonymous usage stats (opt-out in settings)
- **TECP**: Cryptographic receipts stored locally

## Support

- **Issues**: [GitHub Issues](https://github.com/resetroot99/ai-la/issues)
- **Discussions**: [GitHub Discussions](https://github.com/resetroot99/ai-la/discussions)
- **Documentation**: [Full Docs](https://github.com/resetroot99/ai-la)

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! See CONTRIBUTING.md for guidelines.

---

**Built with AI-LA Agent. Verified with TECP.**

