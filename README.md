# 🩹 Bot Self-Healing

Complete self-healing system for Clawdbot/OpenClaw with **two layers of protection**.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│         LAYER 1: EXTERNAL WATCHMAN                  │
│         (systemd / Docker)                          │
│                                                     │
│   Bot crashes? → Auto-restart in 10 seconds         │
│   Cost: FREE | Complexity: Zero                     │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│         LAYER 2: INTERNAL WATCHMAN                  │
│         (Heartbeat + Self-Healing Skill)            │
│                                                     │
│   Every 3 hours:                                    │
│   • Check service, disk, memory, logs, network      │
│   • Fix problems BEFORE they cause crashes          │
│   • Alert owner only for critical issues            │
│   Cost: FREE | Complexity: Zero                     │
└─────────────────────────────────────────────────────┘
```

**Why two layers?**
- External catches crashes (can't prevent them)
- Internal prevents crashes (can't catch them if it dies)
- Together = bulletproof 🛡️

## Quick Install

### Full Install (with Docker)

```bash
git clone https://github.com/Pidinkovski/bot-heal.git
cd bot-heal
sudo ./install.sh /path/to/workspace
```

This will:
1. Install Docker (if not present)
2. Setup docker-compose
3. Install self-healing skills
4. Configure auto-restart

### Without Docker (systemd only)

```bash
sudo ./install.sh --no-docker /path/to/workspace
```

### Skills Only (no external watchman)

```bash
./install.sh --skills-only /path/to/workspace
```

### Manual Install

```bash
# Internal watchman (heartbeat)
cp SKILL.md /workspace/skills/self-healing/
cp HEARTBEAT.md /workspace/

# External watchman (pick one)
sudo cp clawdbot.service /etc/systemd/system/   # Option A: Systemd
docker compose up -d                             # Option B: Docker
```

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Self-healing logic (what to check, how to fix) |
| `HEARTBEAT.md` | Heartbeat configuration |
| `clawdbot.service` | Systemd service (external watchman) |
| `docker-compose.yml` | Docker setup (external watchman) |
| `install.sh` | One-command installer |

## What Gets Fixed Automatically

### By Internal Watchman (every 3 hours)

| Problem | Action |
|---------|--------|
| Service stopped | Restart |
| Temp files bloated | Clean |
| Rate limited | Wait and retry |
| Connection timeout | Retry |
| Disk 70-85% | Log warning |
| Minor errors | Monitor |

### By External Watchman (instant)

| Problem | Action |
|---------|--------|
| Process crashed | Restart in 10s |
| Out of memory kill | Restart in 10s |
| Unhandled exception | Restart in 10s |

## What Alerts You

| Problem | Why Can't Auto-Fix |
|---------|-------------------|
| Disk > 85% | Needs manual cleanup |
| Memory > 90% | Needs investigation |
| 3 restart failures | Something deeply wrong |
| Config error | Needs manual fix |
| API key invalid | Needs new key |

## Configuration

### Heartbeat Interval

Default: 3 hours. Change in your Clawdbot config:

```yaml
heartbeat:
  intervalMinutes: 180   # 3 hours
  # intervalMinutes: 60  # 1 hour (more frequent)
```

### Systemd Service

Edit `/etc/systemd/system/clawdbot.service`:

```ini
# Change restart delay
RestartSec=10

# Change user
User=your-user

# Change workspace path
WorkingDirectory=/your/path
```

Then reload:
```bash
sudo systemctl daemon-reload
sudo systemctl restart clawdbot
```

## Monitoring Commands

```bash
# Check service status
sudo systemctl status clawdbot

# View recent logs
journalctl -u clawdbot -n 50

# Follow logs live
journalctl -u clawdbot -f

# Check self-healing log
cat /workspace/memory/self-healing.md
```

## Cost

**€0 / month**

- Systemd: Free (built into Linux)
- Docker: Free
- Heartbeat: Free (Gemini Flash free tier: 15 RPM, you use 0.005 RPM)

## FAQ

**Q: Why not use a Python monitoring script?**

A: Systemd already does this better. A Python script is:
- Extra process to manage
- Extra log file
- Can crash itself
- Needs manual start
- Reinventing the wheel

**Q: What if both watchmen fail?**

A: Then your server has bigger problems. But you'd have:
- healthchecks.io ping (alerts you)
- Uptime Kuma (external monitoring)
- See [MONITORING-STACK.md] for full setup

**Q: Can the bot fix disk space issues?**

A: It can clean temp files, but won't delete user data. For disk >85%, it alerts you because it needs human judgment on what to delete.

## License

MIT — Use it, modify it, share it.

---

*Made by [ailqkai](https://ailqkai.com) 🇧🇬*
