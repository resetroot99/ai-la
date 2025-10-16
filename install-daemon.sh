#!/bin/bash

###############################################
# AI-LA Autonomous Daemon Installation
# 
# Installs AI-LA daemon that runs 24/7
# monitoring your code and learning from you
###############################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Installing AI-LA Autonomous Daemon..."
echo ""

# Install Python dependencies
echo "Installing dependencies..."
pip3 install --user watchdog 2>/dev/null || pip3 install watchdog

# Copy daemon to .ai-la directory
mkdir -p ~/.ai-la
cp ai-la-daemon.py ~/.ai-la/

# Make executable
chmod +x ~/.ai-la/ai-la-daemon.py

# Install systemd service (Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Installing systemd service..."
    mkdir -p ~/.config/systemd/user
    cp ai-la-daemon.service ~/.config/systemd/user/
    
    systemctl --user daemon-reload
    systemctl --user enable ai-la-daemon
    systemctl --user start ai-la-daemon
    
    echo -e "${GREEN}Daemon installed and started!${NC}"
    echo "Check status: systemctl --user status ai-la-daemon"
    echo "View logs: journalctl --user -u ai-la-daemon -f"

# macOS - use launchd
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Installing launchd service..."
    
    cat > ~/Library/LaunchAgents/com.ai-la.daemon.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ai-la.daemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>$HOME/.ai-la/ai-la-daemon.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/.ai-la/daemon.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.ai-la/daemon-error.log</string>
</dict>
</plist>
EOF
    
    launchctl load ~/Library/LaunchAgents/com.ai-la.daemon.plist
    
    echo -e "${GREEN}Daemon installed and started!${NC}"
    echo "View logs: tail -f ~/.ai-la/daemon.log"
fi

echo ""
echo "AI-LA Autonomous Daemon is now running!"
echo ""
echo "The daemon will:"
echo "- Monitor all your code directories"
echo "- Learn from your coding patterns"
echo "- Proactively fix security issues"
echo "- Suggest improvements"
echo "- Work 24/7 without being asked"
echo ""
echo "Configuration: ~/.ai-la/daemon-config.json"
echo "Database: ~/.ai-la/autonomous.db"
echo ""

