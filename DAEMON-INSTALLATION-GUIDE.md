# AI-LA Autonomous Daemon - Installation & Configuration Guide

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Installation](#quick-installation)
3. [Manual Installation](#manual-installation)
4. [Configuration](#configuration)
5. [Verification](#verification)
6. [Management](#management)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Configuration](#advanced-configuration)
9. [Uninstallation](#uninstallation)

---

## Prerequisites

### System Requirements

**Operating Systems:**
- Linux (Ubuntu 20.04+, Debian 11+, Fedora 35+)
- macOS (11.0+)

**Software:**
- Python 3.8 or higher
- pip3 (Python package manager)
- Git
- Ollama (for local AI models)

**Hardware:**
- CPU: Any modern processor
- RAM: 4GB minimum, 8GB recommended
- Disk: 10GB free space (for AI models)

### Check Prerequisites

```bash
# Check Python version
python3 --version  # Should be 3.8+

# Check pip
pip3 --version

# Check Git
git --version

# Check Ollama
ollama --version
```

If any are missing, install them first:

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3 python3-pip git
curl -fsSL https://ollama.com/install.sh | sh
```

**macOS:**
```bash
brew install python3 git
curl -fsSL https://ollama.com/install.sh | sh
```

---

## Quick Installation

### One-Command Install

```bash
curl -fsSL https://raw.githubusercontent.com/resetroot99/ai-la/main/deploy-ai-la.sh | bash
cd ~/.ai-la
./install-daemon.sh
```

This installs:
1. AI-LA core system
2. Ollama and AI models
3. Autonomous daemon
4. All dependencies

**Time: 10-15 minutes** (depending on internet speed for model download)

---

## Manual Installation

### Step 1: Install AI-LA Core

```bash
# Clone repository
git clone https://github.com/resetroot99/ai-la.git ~/.ai-la
cd ~/.ai-la

# Install Python dependencies
pip3 install --user flask fastapi sqlalchemy requests watchdog
```

### Step 2: Install Ollama

```bash
# Download and install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Start Ollama service
ollama serve &

# Download AI model (this takes 5-10 minutes)
ollama pull qwen2.5-coder:7b
```

### Step 3: Install Daemon

**Linux (systemd):**

```bash
# Copy daemon files
cp ai-la-daemon.py ~/.ai-la/
chmod +x ~/.ai-la/ai-la-daemon.py

# Install systemd service
mkdir -p ~/.config/systemd/user
cp ai-la-daemon.service ~/.config/systemd/user/

# Enable and start service
systemctl --user daemon-reload
systemctl --user enable ai-la-daemon
systemctl --user start ai-la-daemon
```

**macOS (launchd):**

```bash
# Copy daemon files
cp ai-la-daemon.py ~/.ai-la/
chmod +x ~/.ai-la/ai-la-daemon.py

# Create launchd plist
cat > ~/Library/LaunchAgents/com.ai-la.daemon.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ai-la.daemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/Users/YOUR_USERNAME/.ai-la/ai-la-daemon.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/.ai-la/daemon.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/.ai-la/daemon-error.log</string>
</dict>
</plist>
EOF

# Replace YOUR_USERNAME with your actual username
sed -i '' "s/YOUR_USERNAME/$USER/g" ~/Library/LaunchAgents/com.ai-la.daemon.plist

# Load service
launchctl load ~/Library/LaunchAgents/com.ai-la.daemon.plist
```

### Step 4: Verify Installation

```bash
# Check if daemon is running
# Linux:
systemctl --user status ai-la-daemon

# macOS:
launchctl list | grep ai-la

# Check logs
# Linux:
journalctl --user -u ai-la-daemon -n 50

# macOS:
tail -f ~/.ai-la/daemon.log
```

---

## Configuration

### Default Configuration

On first run, AI-LA creates `~/.ai-la/daemon-config.json` with defaults:

```json
{
  "watch_dirs": [
    "~/projects",
    "~/work",
    "~/code",
    "~/dev",
    "~/Documents",
    "~/Desktop"
  ],
  "auto_fix": true,
  "auto_suggest": true,
  "auto_learn": true,
  "invasive_mode": true,
  "notification_level": "important",
  "auto_commit": false,
  "languages": ["python", "javascript", "typescript", "go", "rust", "java"],
  "excluded_dirs": [".git", "node_modules", "venv", "__pycache__", ".venv"]
}
```

### Configuration Options

#### watch_dirs

Directories to monitor for code changes.

**Default:** Common code locations

**Customize:**
```json
{
  "watch_dirs": [
    "~/my-projects",
    "~/work/company-repos",
    "/mnt/external-drive/code"
  ]
}
```

**Tips:**
- Use absolute paths or ~ for home directory
- Add all directories where you write code
- Daemon will recursively monitor subdirectories

#### auto_fix

Automatically fix critical security issues.

**Default:** true

**When enabled:**
- Fixes hardcoded secrets immediately
- Removes dangerous code patterns
- Creates backups before changes
- Logs all fixes

**When disabled:**
- Only suggests fixes
- Requires manual action

**Recommended:** true (with auto_commit: false for safety)

#### auto_suggest

Proactively suggest improvements.

**Default:** true

**Suggestions include:**
- Missing tests
- Missing documentation
- Refactoring opportunities
- Performance improvements

**Frequency:** Based on notification_level

#### auto_learn

Learn from your code continuously.

**Default:** true

**What it learns:**
- Coding style (indentation, quotes, naming)
- Testing habits
- Error handling patterns
- Architecture preferences

**When disabled:** AI-LA uses default patterns only

#### invasive_mode

Full filesystem access and monitoring.

**Default:** true

**When enabled:**
- Monitors all watch_dirs recursively
- Discovers projects automatically
- Analyzes all code files
- Maximum learning capability

**When disabled:**
- Only monitors explicitly specified files
- Limited learning
- Manual project registration

**Recommended:** true for maximum autonomy

#### notification_level

How often AI-LA notifies you.

**Options:**
- "all": Every suggestion and action
- "important": Important suggestions only (default)
- "critical": Critical issues only

**Examples:**

"all" - You get notified about:
- Every security issue
- Every suggestion
- Every autonomous action
- Every pattern learned

"important" - You get notified about:
- Security issues
- Missing tests/docs
- Major refactoring opportunities

"critical" - You get notified about:
- Critical security vulnerabilities only
- System errors

#### auto_commit

Automatically commit fixes to git.

**Default:** false

**When enabled:**
- AI-LA commits fixes automatically
- Uses descriptive commit messages
- Example: "fix: remove hardcoded API key (AI-LA autonomous fix)"

**When disabled:**
- Fixes are made but not committed
- You review and commit manually

**Recommended:** false initially, enable after trust is built

#### languages

Programming languages to monitor.

**Default:** ["python", "javascript", "typescript", "go", "rust", "java"]

**Customize:**
```json
{
  "languages": ["python", "javascript"]
}
```

**Supported languages:**
- python (.py)
- javascript (.js)
- typescript (.ts)
- go (.go)
- rust (.rs)
- java (.java)
- ruby (.rb)
- php (.php)
- c (.c, .h)
- cpp (.cpp, .hpp)

#### excluded_dirs

Directories to skip during monitoring.

**Default:** [".git", "node_modules", "venv", "__pycache__", ".venv"]

**Customize:**
```json
{
  "excluded_dirs": [
    ".git",
    "node_modules",
    "venv",
    "build",
    "dist",
    "target"
  ]
}
```

**Common exclusions:**
- .git (git internals)
- node_modules (npm packages)
- venv, .venv (Python virtual environments)
- __pycache__ (Python bytecode)
- build, dist (build artifacts)
- target (Rust/Java build output)

### Applying Configuration Changes

After editing `~/.ai-la/daemon-config.json`:

**Linux:**
```bash
systemctl --user restart ai-la-daemon
```

**macOS:**
```bash
launchctl unload ~/Library/LaunchAgents/com.ai-la.daemon.plist
launchctl load ~/Library/LaunchAgents/com.ai-la.daemon.plist
```

---

## Verification

### Check Daemon Status

**Linux:**
```bash
systemctl --user status ai-la-daemon
```

Expected output:
```
● ai-la-daemon.service - AI-LA Autonomous Development Daemon
   Loaded: loaded
   Active: active (running)
```

**macOS:**
```bash
launchctl list | grep ai-la
```

Expected output:
```
12345  0  com.ai-la.daemon
```

### View Logs

**Linux:**
```bash
# Recent logs
journalctl --user -u ai-la-daemon -n 100

# Follow logs in real-time
journalctl --user -u ai-la-daemon -f
```

**macOS:**
```bash
# View logs
tail -n 100 ~/.ai-la/daemon.log

# Follow logs in real-time
tail -f ~/.ai-la/daemon.log
```

### Check What AI-LA Learned

```bash
# View learned patterns
sqlite3 ~/.ai-la/autonomous.db "
SELECT pattern_type, pattern_data, confidence 
FROM learned_patterns 
ORDER BY confidence DESC
"

# View discovered projects
sqlite3 ~/.ai-la/autonomous.db "
SELECT name, language, path 
FROM projects
"

# View autonomous actions
sqlite3 ~/.ai-la/autonomous.db "
SELECT timestamp, action_type, description 
FROM autonomous_actions 
ORDER BY timestamp DESC 
LIMIT 10
"
```

### Test Daemon Functionality

Create a test file with a security issue:

```bash
# Create test directory
mkdir -p ~/test-ai-la
cd ~/test-ai-la

# Create file with hardcoded password
cat > test.py << 'EOF'
password = "hardcoded123"
api_key = "sk-1234567890"

def connect():
    return f"Connecting with {password}"
EOF

# Wait 5 seconds
sleep 5

# Check if AI-LA detected it
journalctl --user -u ai-la-daemon -n 20 | grep -i "security"
```

Expected: AI-LA should detect and log the security issues.

---

## Management

### Start Daemon

**Linux:**
```bash
systemctl --user start ai-la-daemon
```

**macOS:**
```bash
launchctl load ~/Library/LaunchAgents/com.ai-la.daemon.plist
```

### Stop Daemon

**Linux:**
```bash
systemctl --user stop ai-la-daemon
```

**macOS:**
```bash
launchctl unload ~/Library/LaunchAgents/com.ai-la.daemon.plist
```

### Restart Daemon

**Linux:**
```bash
systemctl --user restart ai-la-daemon
```

**macOS:**
```bash
launchctl unload ~/Library/LaunchAgents/com.ai-la.daemon.plist
launchctl load ~/Library/LaunchAgents/com.ai-la.daemon.plist
```

### Enable Auto-Start

**Linux:**
```bash
systemctl --user enable ai-la-daemon
```

**macOS:**
Auto-start is enabled by default with launchd.

### Disable Auto-Start

**Linux:**
```bash
systemctl --user disable ai-la-daemon
```

**macOS:**
```bash
launchctl unload -w ~/Library/LaunchAgents/com.ai-la.daemon.plist
```

---

## Troubleshooting

### Daemon Won't Start

**Check Python version:**
```bash
python3 --version  # Must be 3.8+
```

**Check dependencies:**
```bash
pip3 list | grep -E "watchdog|flask|sqlalchemy"
```

**Install missing dependencies:**
```bash
pip3 install --user watchdog flask sqlalchemy requests
```

**Check permissions:**
```bash
ls -l ~/.ai-la/ai-la-daemon.py  # Should be executable
chmod +x ~/.ai-la/ai-la-daemon.py
```

### Ollama Not Running

**Check Ollama status:**
```bash
curl http://localhost:11434/api/tags
```

**Start Ollama:**
```bash
ollama serve &
```

**Check if model is downloaded:**
```bash
ollama list
```

**Download model if missing:**
```bash
ollama pull qwen2.5-coder:7b
```

### No Projects Discovered

**Check watch directories exist:**
```bash
ls -la ~/projects ~/work ~/code
```

**Create directories if missing:**
```bash
mkdir -p ~/projects ~/work ~/code
```

**Check configuration:**
```bash
cat ~/.ai-la/daemon-config.json | grep watch_dirs
```

**Manually trigger discovery:**
```bash
sqlite3 ~/.ai-la/autonomous.db "DELETE FROM projects"
systemctl --user restart ai-la-daemon
```

### High CPU Usage

**Check what AI-LA is processing:**
```bash
journalctl --user -u ai-la-daemon -n 50
```

**Reduce monitored directories:**
Edit `~/.ai-la/daemon-config.json`:
```json
{
  "watch_dirs": ["~/projects"]  # Only one directory
}
```

**Add more exclusions:**
```json
{
  "excluded_dirs": [
    ".git",
    "node_modules",
    "venv",
    "build",
    "dist",
    ".next",
    "target"
  ]
}
```

### Database Errors

**Reset database:**
```bash
# Backup first
cp ~/.ai-la/autonomous.db ~/.ai-la/autonomous.db.backup

# Delete and restart (daemon will recreate)
rm ~/.ai-la/autonomous.db
systemctl --user restart ai-la-daemon
```

### Permission Errors

**Fix ownership:**
```bash
chown -R $USER:$USER ~/.ai-la
chmod -R u+rw ~/.ai-la
```

---

## Advanced Configuration

### Custom AI Model

Use a different Ollama model:

```bash
# Download larger model for better quality
ollama pull qwen2.5-coder:32b

# Edit daemon to use it
# In ai-la-daemon.py, change OLLAMA_MODEL variable
```

### Multiple Watch Directories

Monitor external drives or network shares:

```json
{
  "watch_dirs": [
    "~/projects",
    "/mnt/external-drive/code",
    "/Volumes/NetworkShare/work"
  ]
}
```

### Language-Specific Configuration

Different settings per language:

```json
{
  "language_config": {
    "python": {
      "style": "pep8",
      "max_line_length": 88
    },
    "javascript": {
      "style": "airbnb",
      "max_line_length": 100
    }
  }
}
```

(Requires custom daemon modification)

### Integration with Git Hooks

Auto-run AI-LA analysis on commit:

```bash
# In your project's .git/hooks/pre-commit
#!/bin/bash
sqlite3 ~/.ai-la/autonomous.db "
SELECT COUNT(*) FROM autonomous_actions 
WHERE action_type='security_issue' 
AND timestamp > datetime('now', '-1 hour')
" | grep -q "^0$" || {
    echo "AI-LA detected security issues in the last hour!"
    echo "Review: journalctl --user -u ai-la-daemon -n 20"
    exit 1
}
```

### Team Configuration

Share configuration across team:

```bash
# Export your configuration
cp ~/.ai-la/daemon-config.json ~/team-ai-la-config.json

# Team members import
cp ~/team-ai-la-config.json ~/.ai-la/daemon-config.json
systemctl --user restart ai-la-daemon
```

### Notification Integration

Send notifications to Slack/Discord:

Add to daemon or create wrapper script:

```bash
# In cron or as systemd timer
*/5 * * * * sqlite3 ~/.ai-la/autonomous.db "
SELECT description FROM autonomous_actions 
WHERE timestamp > datetime('now', '-5 minutes')
" | while read action; do
    curl -X POST https://hooks.slack.com/YOUR_WEBHOOK \
      -d "{\"text\": \"AI-LA: $action\"}"
done
```

---

## Uninstallation

### Stop and Disable Daemon

**Linux:**
```bash
systemctl --user stop ai-la-daemon
systemctl --user disable ai-la-daemon
rm ~/.config/systemd/user/ai-la-daemon.service
systemctl --user daemon-reload
```

**macOS:**
```bash
launchctl unload ~/Library/LaunchAgents/com.ai-la.daemon.plist
rm ~/Library/LaunchAgents/com.ai-la.daemon.plist
```

### Remove AI-LA Files

```bash
# Remove AI-LA directory
rm -rf ~/.ai-la

# Remove CLI wrapper
rm ~/.local/bin/ai-la
```

### Keep Learned Data

If you want to reinstall later but keep learned patterns:

```bash
# Backup database
cp ~/.ai-la/autonomous.db ~/ai-la-backup.db

# After reinstalling, restore
cp ~/ai-la-backup.db ~/.ai-la/autonomous.db
```

---

## Summary

### Quick Reference

**Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/resetroot99/ai-la/main/deploy-ai-la.sh | bash
cd ~/.ai-la && ./install-daemon.sh
```

**Configure:**
```bash
nano ~/.ai-la/daemon-config.json
systemctl --user restart ai-la-daemon
```

**Monitor:**
```bash
journalctl --user -u ai-la-daemon -f
```

**Query:**
```bash
sqlite3 ~/.ai-la/autonomous.db "SELECT * FROM learned_patterns"
```

### Support

- GitHub: https://github.com/resetroot99/ai-la
- Issues: https://github.com/resetroot99/ai-la/issues
- Documentation: https://github.com/resetroot99/ai-la/blob/main/AI-LA-AUTONOMOUS-DAEMON.md

---

**You now have a truly autonomous AI development assistant running 24/7.**

