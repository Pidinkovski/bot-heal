# Docker Guide for Beginners

A practical guide for running Clawdbot with Docker.

---

## What is Docker?

Think of it like this:

```
WITHOUT Docker:
┌─────────────────────────────────────┐
│  Your Server                        │
│  ├── Node.js v18                    │
│  ├── Python 3.9                     │
│  ├── Clawdbot                       │
│  ├── Other apps...                  │
│  └── Everything mixed together 😰   │
└─────────────────────────────────────┘
Problem: Apps conflict, updates break things

WITH Docker:
┌─────────────────────────────────────┐
│  Your Server                        │
│  ┌─────────┐ ┌─────────┐ ┌────────┐ │
│  │ Bot 1   │ │ Bot 2   │ │ Bot 3  │ │
│  │ Node 22 │ │ Node 22 │ │ Node 22│ │
│  │ Clean   │ │ Clean   │ │ Clean  │ │
│  └─────────┘ └─────────┘ └────────┘ │
│  Each in its own "box" 📦           │
└─────────────────────────────────────┘
Benefit: Isolated, clean, reproducible
```

**Docker = Each app runs in its own isolated box (container)**

---

## Key Concepts

| Term | What it means | Example |
|------|---------------|---------|
| **Image** | Recipe/template | `node:22-slim` |
| **Container** | Running instance of image | Your bot running |
| **Volume** | Shared folder between host and container | `./workspace:/root/clawd` |
| **docker-compose** | Config file to set up containers | `docker-compose.yml` |

---

## Basic Commands

### Managing Containers

```bash
# Start containers (from docker-compose.yml)
docker compose up -d

# Stop containers
docker compose down

# Restart containers
docker compose restart

# See running containers
docker ps

# See ALL containers (including stopped)
docker ps -a
```

### Viewing Logs

```bash
# See logs (last 50 lines)
docker compose logs --tail 50

# Follow logs live (like tail -f)
docker compose logs -f

# Logs for specific container
docker logs my-client-bot
```

### Going Inside a Container

```bash
# Open shell inside container
docker exec -it my-client-bot bash

# Run a command inside container
docker exec my-client-bot ls -la /root/clawd

# Exit the container shell
exit
```

### Cleanup

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove everything unused (careful!)
docker system prune
```

---

## Understanding docker-compose.yml

Let's break down each line:

```yaml
# docker-compose.yml

services:                          # List of containers to run
  clawdbot:                        # Name of this service
    
    image: node:22-slim            # Base image (Node.js 22, minimal)
    
    container_name: my-client-bot  # Name for the container
    
    working_dir: /app              # Start in this folder
    
    command: >                     # Command to run on start
      sh -c "npm install -g clawdbot && clawdbot gateway"
    
    restart: unless-stopped        # Auto-restart policy
    
    volumes:                       # Shared folders
      - ./workspace:/root/clawd    # Host:Container
      - ./config.yaml:/root/.clawdbot/config.yaml
    
    env_file:                      # Load environment variables
      - .env
```

---

## Volumes Explained

Volumes connect folders on your server to folders inside the container:

```yaml
volumes:
  - ./workspace:/root/clawd
  #   ↑              ↑
  #   Host path      Container path
```

```
YOUR SERVER                    CONTAINER
./workspace/          ←→      /root/clawd/
├── SOUL.md                   (same files)
├── HEARTBEAT.md
└── skills/
```

**Changes sync both ways!**
- Edit file on server → Container sees it
- Bot creates file → You see it on server

---

## Restart Policies

```yaml
restart: unless-stopped
```

| Policy | What happens |
|--------|--------------|
| `no` | Never restart |
| `always` | Always restart (even after reboot) |
| `unless-stopped` | Restart unless YOU stopped it |
| `on-failure` | Restart only if crashed |

**Use `unless-stopped`** — best for bots.

---

## Environment Variables

### Option 1: .env file (recommended)

```bash
# .env
GOOGLE_API_KEY=AIza-xxxxx
TELEGRAM_BOT_TOKEN=123:ABC
```

```yaml
# docker-compose.yml
env_file:
  - .env
```

### Option 2: Direct in compose

```yaml
# docker-compose.yml
environment:
  - GOOGLE_API_KEY=AIza-xxxxx
  - TELEGRAM_BOT_TOKEN=123:ABC
```

**Use .env file** — keeps secrets out of the yml.

---

## Complete Client Setup Example

### Folder Structure

```
client-ivan/
├── docker-compose.yml
├── .env
├── config.yaml
└── workspace/
    ├── SOUL.md
    ├── AGENTS.md
    ├── HEARTBEAT.md
    ├── TOOLS.md
    ├── memory/
    └── skills/
        └── self-healing/
            └── SKILL.md
```

### docker-compose.yml

```yaml
services:
  clawdbot:
    image: node:22-slim
    container_name: ivan-bot
    working_dir: /app
    
    command: >
      sh -c "
        npm install -g clawdbot &&
        clawdbot gateway
      "
    
    restart: unless-stopped
    
    volumes:
      - ./workspace:/root/clawd
      - ./config.yaml:/root/.clawdbot/config.yaml
    
    env_file:
      - .env
    
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

### .env

```bash
# AI Provider
GOOGLE_API_KEY=AIza-your-key-here

# Telegram (if using)
TELEGRAM_BOT_TOKEN=123456:ABC-your-token

# Optional
NODE_ENV=production
```

### config.yaml

```yaml
# Clawdbot config
model: google/gemini-2.0-flash

channels:
  telegram:
    token: ${TELEGRAM_BOT_TOKEN}

heartbeat:
  intervalMinutes: 180
```

---

## Common Tasks

### Start a new client bot

```bash
cd client-ivan
docker compose up -d
docker compose logs -f  # Watch it start
```

### Update Clawdbot

```bash
cd client-ivan
docker compose down
docker compose pull      # Get latest image
docker compose up -d
```

### Check if bot is running

```bash
docker ps | grep ivan-bot
```

### View bot logs

```bash
docker logs ivan-bot --tail 100
docker logs ivan-bot -f  # Live follow
```

### Restart bot

```bash
docker restart ivan-bot
# OR
cd client-ivan
docker compose restart
```

### Edit bot files

```bash
# Edit directly on server
nano client-ivan/workspace/SOUL.md

# Changes apply immediately (no restart needed for .md files)
```

### SSH into the bot container

```bash
docker exec -it ivan-bot bash

# Inside container:
ls /root/clawd          # See workspace
cat /root/clawd/SOUL.md # Read files
exit                    # Leave container
```

---

## Troubleshooting

### Bot won't start

```bash
# Check logs for errors
docker compose logs

# Common issues:
# - Missing .env file
# - Wrong API key
# - Port already in use
```

### Container keeps restarting

```bash
# Check why it's crashing
docker logs ivan-bot --tail 50

# Check restart count
docker inspect ivan-bot | grep RestartCount
```

### Out of disk space

```bash
# Check Docker disk usage
docker system df

# Clean up old stuff
docker system prune
```

### Can't connect to bot

```bash
# Is it running?
docker ps | grep ivan-bot

# Check logs
docker logs ivan-bot -f
```

---

## Multiple Clients on One Server

```
/home/bots/
├── client-ivan/
│   ├── docker-compose.yml
│   ├── .env
│   └── workspace/
├── client-maria/
│   ├── docker-compose.yml
│   ├── .env
│   └── workspace/
└── client-peter/
    ├── docker-compose.yml
    ├── .env
    └── workspace/
```

Each client is completely isolated. Start them separately:

```bash
cd /home/bots/client-ivan && docker compose up -d
cd /home/bots/client-maria && docker compose up -d
cd /home/bots/client-peter && docker compose up -d
```

---

## Quick Reference Card

```bash
# START
docker compose up -d

# STOP
docker compose down

# RESTART
docker compose restart

# LOGS
docker compose logs -f

# STATUS
docker ps

# GO INSIDE
docker exec -it <container> bash

# CLEANUP
docker system prune
```

---

*Docker Guide v1.0 | ailqkai*
