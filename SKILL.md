# Skill: Self-Healing Bot

## Overview

You monitor yourself and fix problems automatically. Only contact Pavel for critical issues you cannot resolve.

---

## When to Run

- Every HEARTBEAT (configure: every 3 hours / 180 min)
- When you notice something wrong
- When asked: "провери се" / "check yourself"

---

## Self-Healing Flow

```
┌─────────────────────────────────────────┐
│            HEARTBEAT TRIGGERED          │
└─────────────────┬───────────────────────┘
                  ▼
┌─────────────────────────────────────────┐
│         RUN DIAGNOSTIC CHECKS           │
│  (service, disk, memory, logs, network) │
└─────────────────┬───────────────────────┘
                  ▼
         ┌───────────────┐
         │ Problems found?│
         └───────┬───────┘
                 │
        ┌────NO─┴─YES────┐
        ▼                ▼
  HEARTBEAT_OK    ┌─────────────┐
                  │ Can I fix it?│
                  └──────┬──────┘
                         │
                ┌───YES──┴──NO───┐
                ▼                ▼
        ┌─────────────┐   ┌─────────────┐
        │  FIX IT     │   │ CRITICAL?   │
        │  Log action │   └──────┬──────┘
        └──────┬──────┘          │
               │          ┌──YES─┴─NO──┐
               ▼          ▼            ▼
        HEARTBEAT_OK   ALERT       Log it
                       PAVEL       Continue
```

---

## Diagnostic Checks

Run these commands silently every heartbeat:

### 1. Service Status
```bash
systemctl --user is-active clawdbot-gateway 2>/dev/null || echo "inactive"
```

### 2. Disk Space
```bash
df -h / | awk 'NR==2 {gsub("%",""); print $5}'
```

### 3. Memory Usage
```bash
free | awk 'NR==2 {printf "%.0f", $3*100/$2}'
```

### 4. Recent Errors (last check period)
```bash
journalctl --user -u clawdbot-gateway --since "3 hours ago" --no-pager 2>/dev/null | grep -iE "error|fatal|crash|failed|exception" | tail -10
```

### 5. Network Connectivity
```bash
curl -sf --max-time 5 https://api.anthropic.com > /dev/null && echo "ok" || echo "no-network"
```

### 6. Process Running
```bash
pgrep -f "clawdbot" > /dev/null && echo "running" || echo "not-running"
```

---

## Problem Categories

### 🟢 AUTO-FIX (Fix silently, log it, continue)

| Problem | Detection | Fix |
|---------|-----------|-----|
| Service stopped | `is-active` = inactive | `systemctl --user restart clawdbot-gateway` |
| Service stuck | Running but not responding | Restart service |
| Temp files large | `/tmp` > 1GB | `rm -rf /tmp/clawdbot-*` |
| Cache bloated | Cache dir > 500MB | Clear old cache files |
| Rate limited | "rate limit" in logs | Wait 60 seconds, reduce activity |
| Connection timeout | Timeout errors | Retry after 30 seconds |
| Webhook failed | Webhook error in logs | Retry webhook |

### 🟡 MONITOR (Log it, don't alert yet)

| Problem | Detection | Action |
|---------|-----------|--------|
| Disk 70-85% | df shows 70-85% | Log warning, check next heartbeat |
| Memory 70-85% | free shows 70-85% | Log warning, monitor |
| Slow responses | Response time > 10s | Log, monitor for pattern |
| Minor errors | Non-critical errors | Log, monitor frequency |

### 🔴 CRITICAL (Alert Pavel immediately)

| Problem | Detection | Alert |
|---------|-----------|-------|
| Disk > 85% | df shows > 85% | "🔴 Disk [X]% full" |
| Memory > 90% | free shows > 90% | "🔴 Memory [X]% used" |
| Service won't restart | 3 restart attempts failed | "🔴 Service dead, restarts failed" |
| API key invalid | "invalid api key" in logs | "🔴 API key problem" |
| Config error | "config" + "error" in logs | "🔴 Config broken" |
| Network down > 5min | Multiple connectivity fails | "🔴 Network down" |
| Unknown crash | Crash without known pattern | "🔴 Unknown crash, need help" |
| Data corruption | Data/file errors | "🔴 Possible data issue" |

---

## Auto-Fix Procedures

### Restart Service
```bash
# 1. Stop gracefully
systemctl --user stop clawdbot-gateway
sleep 5

# 2. Check if stopped
if systemctl --user is-active clawdbot-gateway | grep -q "inactive"; then
    # 3. Start fresh
    systemctl --user start clawdbot-gateway
    sleep 10
    
    # 4. Verify
    if systemctl --user is-active clawdbot-gateway | grep -q "active"; then
        echo "FIXED"
    else
        echo "FAILED"
    fi
else
    # Force kill if needed
    pkill -f clawdbot
    sleep 2
    systemctl --user start clawdbot-gateway
fi
```

### Restart Limits
- Max 3 restart attempts per hour
- If 3 fails → ALERT PAVEL
- Track attempts in memory

### Clear Temp Files
```bash
find /tmp -name "clawdbot-*" -mtime +1 -delete 2>/dev/null
find ~/.cache/clawdbot -mtime +7 -delete 2>/dev/null
```

---

## Alert Format

### Critical Alert (send to Pavel):
```
🔴 [Bot Name] CRITICAL

Problem: [one line description]
Time: [timestamp]
Tried: [what you attempted]

Details:
[2-3 relevant log lines]

Action needed: [what Pavel should do]
```

### Example:
```
🔴 [Ivan-Bot] CRITICAL

Problem: Service won't start after 3 attempts
Time: 2024-02-18 22:15 UTC
Tried: Restart 3x, cleared temp files

Details:
Error: ENOSPC - no space left on device
/dev/sda1 is 98% full

Action needed: SSH in and clear disk space
```

---

## Logging

After ANY action, write to `memory/self-healing.md`:

```markdown
## 2024-02-18 22:15

### Check Results
- Service: ✅ active
- Disk: ⚠️ 78%
- Memory: ✅ 45%
- Errors: 2 minor

### Actions Taken
- Cleared temp files (saved 200MB)

### Status
All good, continuing.
```

---

## Heartbeat Response Rules

| Situation | Response |
|-----------|----------|
| All checks pass | `HEARTBEAT_OK` |
| Fixed minor issue | Log it → `HEARTBEAT_OK` |
| Monitoring something | Log it → `HEARTBEAT_OK` |
| Fixed critical issue | Log it → `HEARTBEAT_OK` |
| Cannot fix critical | Alert Pavel → (no HEARTBEAT_OK) |

---

## Safety Rules

### NEVER do:
- ❌ Delete user data
- ❌ Modify config files
- ❌ Change API keys
- ❌ Run `rm -rf` on important dirs
- ❌ Restart more than 3 times/hour
- ❌ Make external API calls to "fix" things
- ❌ Ignore critical disk/memory issues

### ALWAYS do:
- ✅ Log before taking action
- ✅ Log after taking action
- ✅ Verify fix worked
- ✅ Alert if fix failed
- ✅ Track restart attempts
- ✅ Be conservative (when in doubt, alert Pavel)

---

## Quick Reference

```
Every Heartbeat:
1. Run 6 checks (service, disk, mem, logs, network, process)
2. Problems? → Check if auto-fixable
3. Auto-fix? → Fix it, log it
4. Can't fix + Critical? → Alert Pavel
5. Can't fix + Not critical? → Log, monitor
6. All good? → HEARTBEAT_OK
```

---

*Self-Healing Skill v2.0 | ailqkai*
*Cost: FREE (Gemini Flash free tier)*
