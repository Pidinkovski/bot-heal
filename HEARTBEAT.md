# HEARTBEAT.md

<!--
  Self-Healing Heartbeat Configuration
  Run every 3 hours (Gemini Flash free tier = unlimited)
  
  Configure: heartbeat.intervalMinutes: 180
  
  Read SKILL.md for full documentation
-->

## On Every Heartbeat

### Step 1: Run Diagnostics

```bash
# Service alive?
systemctl --user is-active clawdbot-gateway

# Disk usage?
df -h / | awk 'NR==2 {print $5}'

# Memory usage?
free | awk 'NR==2 {printf "%.0f%%", $3*100/$2}'

# Recent errors?
journalctl --user -u clawdbot-gateway --since "3 hours ago" 2>/dev/null | grep -iE "error|fatal|crash" | tail -5

# Network ok?
curl -sf --max-time 5 https://api.anthropic.com > /dev/null && echo "network:ok" || echo "network:down"
```

### Step 2: Evaluate Results

| Check | Good | Warning | Critical |
|-------|------|---------|----------|
| Service | active | - | inactive |
| Disk | <70% | 70-85% | >85% |
| Memory | <70% | 70-85% | >90% |
| Errors | none | minor | fatal/crash |
| Network | ok | - | down >5min |

### Step 3: Take Action

**🟢 All Good:**
→ Reply: `HEARTBEAT_OK`

**🟡 Minor Issue (can fix):**
→ Fix it (restart service, clear temp, etc.)
→ Log to `memory/self-healing.md`
→ Reply: `HEARTBEAT_OK`

**🟡 Warning (monitor):**
→ Log to `memory/self-healing.md`
→ Reply: `HEARTBEAT_OK`

**🔴 Critical (cannot fix):**
→ Send alert to Pavel with details
→ DO NOT reply HEARTBEAT_OK

---

## Auto-Fix Actions

| Problem | Fix Command |
|---------|-------------|
| Service inactive | `systemctl --user restart clawdbot-gateway` |
| Temp files large | `rm -rf /tmp/clawdbot-* 2>/dev/null` |
| Rate limited | Wait 60s, continue |

**Restart limit:** Max 3 attempts/hour. After 3 fails → alert Pavel.

---

## Alert Template

```
🔴 [Bot Name] Needs Help

Problem: [description]
Time: [now]
Tried: [what you did]

Logs:
[relevant lines]

Please check.
```

---

## Logging

After every heartbeat with issues, append to `memory/self-healing.md`:

```markdown
## [Date Time]
- Service: ✅/❌
- Disk: [X]%
- Memory: [X]%
- Errors: [count]
- Action: [what you did]
- Result: [fixed/monitoring/alerted]
```
