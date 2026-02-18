#!/bin/bash

# Bot Self-Healing Installer
# Installs Docker + External & Internal Watchmen
#
# Usage:
#   sudo ./install.sh                    # Full install with Docker
#   sudo ./install.sh --no-docker        # Skip Docker, use systemd
#   ./install.sh --skills-only           # Only install skill files

set -e

WORKSPACE="${WORKSPACE:-/home/clawdbot/workspace}"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

INSTALL_DOCKER=true
SKILLS_ONLY=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --no-docker)
            INSTALL_DOCKER=false
            ;;
        --skills-only)
            SKILLS_ONLY=true
            ;;
        --workspace=*)
            WORKSPACE="${arg#*=}"
            ;;
        *)
            if [[ ! "$arg" == -* ]]; then
                WORKSPACE="$arg"
            fi
            ;;
    esac
done

echo ""
echo "🩹 Bot Self-Healing Installer"
echo "=============================="
echo ""
echo "Workspace: $WORKSPACE"
echo ""

# ============================================
# SKILLS INSTALLATION (Internal Watchman)
# ============================================

install_skills() {
    echo "📋 Installing internal watchman (skills)..."
    
    mkdir -p "$WORKSPACE/skills/self-healing"
    mkdir -p "$WORKSPACE/memory"
    
    cp SKILL.md "$WORKSPACE/skills/self-healing/"
    cp HEARTBEAT.md "$WORKSPACE/"
    
    echo -e "${GREEN}✓ Skills installed${NC}"
}

# ============================================
# DOCKER INSTALLATION
# ============================================

install_docker() {
    echo "🐳 Checking Docker..."
    
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓ Docker already installed${NC}"
        return 0
    fi
    
    echo "📦 Installing Docker..."
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo -e "${RED}Cannot detect OS${NC}"
        return 1
    fi
    
    case $OS in
        ubuntu|debian)
            apt-get update -qq
            apt-get install -y -qq ca-certificates curl gnupg
            
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg
            
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            apt-get update -qq
            apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
            
        centos|rhel|fedora)
            dnf install -y dnf-plugins-core
            dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
            
        *)
            echo -e "${YELLOW}Unknown OS: $OS${NC}"
            echo "Please install Docker manually: https://docs.docker.com/get-docker/"
            return 1
            ;;
    esac
    
    # Start Docker
    systemctl start docker
    systemctl enable docker
    
    echo -e "${GREEN}✓ Docker installed${NC}"
}

# ============================================
# DOCKER COMPOSE SETUP
# ============================================

setup_docker_compose() {
    echo "🔧 Setting up Docker Compose..."
    
    # Create directory
    mkdir -p "$WORKSPACE"
    
    # Copy docker-compose.yml
    cp docker-compose.yml "$WORKSPACE/"
    
    # Create .env template if not exists
    if [ ! -f "$WORKSPACE/.env" ]; then
        cat > "$WORKSPACE/.env" << 'EOF'
# API Keys (fill these in)
ANTHROPIC_API_KEY=
GOOGLE_API_KEY=

# Optional
NODE_ENV=production
EOF
        echo -e "${YELLOW}⚠ Created .env file - add your API keys!${NC}"
    fi
    
    echo -e "${GREEN}✓ Docker Compose configured${NC}"
}

# ============================================
# SYSTEMD SETUP (Alternative to Docker)
# ============================================

setup_systemd() {
    echo "🔧 Setting up systemd service..."
    
    cp clawdbot.service /etc/systemd/system/
    
    # Update paths in service file
    sed -i "s|/home/clawdbot/workspace|$WORKSPACE|g" /etc/systemd/system/clawdbot.service
    
    systemctl daemon-reload
    systemctl enable clawdbot
    
    echo -e "${GREEN}✓ Systemd service installed${NC}"
    echo "  Start with: sudo systemctl start clawdbot"
}

# ============================================
# MAIN INSTALLATION
# ============================================

echo "Starting installation..."
echo ""

# Always install skills
install_skills

if [ "$SKILLS_ONLY" = true ]; then
    echo ""
    echo -e "${GREEN}✅ Skills-only installation complete!${NC}"
    exit 0
fi

# Check root for Docker/systemd
if [ "$EUID" -ne 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠ Run as root for full installation:${NC}"
    echo "  sudo ./install.sh"
    echo ""
    echo "Or install skills only:"
    echo "  ./install.sh --skills-only"
    exit 1
fi

if [ "$INSTALL_DOCKER" = true ]; then
    install_docker
    setup_docker_compose
    
    echo ""
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Edit $WORKSPACE/.env and add your API keys"
    echo "  2. cd $WORKSPACE"
    echo "  3. docker compose up -d"
    echo ""
else
    setup_systemd
    
    echo ""
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Edit /etc/systemd/system/clawdbot.service if needed"
    echo "  2. sudo systemctl start clawdbot"
    echo ""
fi

echo "Your bot now has:"
echo "  🛡️  External watchman - auto-restart on crash"
echo "  🧠  Internal watchman - prevents crashes (heartbeat every 3h)"
echo ""
echo "Monitor with:"
if [ "$INSTALL_DOCKER" = true ]; then
    echo "  docker compose logs -f"
else
    echo "  journalctl -u clawdbot -f"
fi
echo ""
