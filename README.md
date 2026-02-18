# 🩹 Bot Self-Healing Skill

A self-healing skill for Clawdbot/OpenClaw that monitors the bot's health and automatically fixes common issues.

## What It Does

```
Every 3 hours:
├── Check: Service running?     → Restart if dead
├── Check: Disk space ok?       → Alert if >85%
├── Check: Memory ok?           → Alert if >90%
├── Check: Errors in logs?      → Fix or alert
├── Check: Network working?     → Retry or alert
└── All good?                   → HEARTBEAT_OK
```

## Features

- ✅ Auto-restart stopped services
- ✅ Clear temp files when bloated
- ✅ Handle rate limits gracefully
- ✅ Retry failed connections
- ✅ Alert owner only for critical issues
- ✅ Log all actions for debugging

## Installation

1. Copy files to your Clawdbot workspace:
   ```bash
   cp SKILL.md /path/to/workspace/skills/self-healing/
   cp HEARTBEAT.md /path/to/workspace/
   ```

2. Configure heartbeat interval (optional, default works):
   ```yaml
   # In clawdbot config
   heartbeat:
     intervalMinutes: 180  # 3 hours
   ```

3. Done! Bot will now monitor itself.

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Full self-healing logic and procedures |
| `HEARTBEAT.md` | Quick reference for heartbeat checks |

## What Gets Fixed Automatically

| Problem | Auto-Fix |
|---------|----------|
| Service stopped | Restart service |
| Temp files large | Clean /tmp |
| Rate limited | Wait and retry |
| Connection timeout | Retry |

## What Alerts You

| Problem | Why |
|---------|-----|
| Disk > 85% | Can't auto-fix, needs cleanup |
| Memory > 90% | Needs investigation |
| 3 restart failures | Something deeply wrong |
| Config error | Needs manual fix |
| API key invalid | Needs new key |

## Cost

**FREE** — Works with Gemini Flash free tier (15 RPM).

8 heartbeats/day = 0.005 RPM used.

## License

MIT — Use it, modify it, share it.

---

*Made by [ailqkai](https://ailqkai.com)*
