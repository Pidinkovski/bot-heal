#!/bin/bash

# Bot Self-Healing Installer
# Installs both external (systemd) and internal (heartbeat) watchmen

set -e

WORKSPACE="${1:-/home/clawdbot/workspace}"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🩹 Bot Self-Healing Installer"
echo "=============================="
echo ""

# Check if running as root for systemd install
if [ "$EUID" -eq 0 ]; then
    INSTALL_SYSTEMD=true
else
    INSTALL_SYSTEMD=false
    echo -e "${YELLOW}Note: Run as root to install systemd service${NC}"
fi

# Create skills directory
echo "📁 Creating directories..."
mkdir -p "$WORKSPACE/skills/self-healing"
mkdir -p "$WORKSPACE/memory"

# Copy internal watchman files
echo "📋 Installing internal watchman (heartbeat)..."
cp SKILL.md "$WORKSPACE/skills/self-healing/"
cp HEARTBEAT.md "$WORKSPACE/"

# Install systemd service if root
if [ "$INSTALL_SYSTEMD" = true ]; then
    echo "🔧 Installing external watchman (systemd)..."
    cp clawdbot.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable clawdbot
    echo -e "${GREEN}✓ Systemd service installed${NC}"
    echo "  Start with: sudo systemctl start clawdbot"
else
    echo ""
    echo "To install systemd service (external watchman), run:"
    echo "  sudo cp clawdbot.service /etc/systemd/system/"
    echo "  sudo systemctl daemon-reload"
    echo "  sudo systemctl enable clawdbot"
fi

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo "Your bot now has:"
echo "  🛡️  External watchman (systemd) - restarts on crash"
echo "  🧠  Internal watchman (heartbeat) - prevents crashes"
echo ""
echo "Files installed:"
echo "  $WORKSPACE/skills/self-healing/SKILL.md"
echo "  $WORKSPACE/HEARTBEAT.md"
echo ""
