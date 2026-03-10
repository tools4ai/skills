---
name: clawAgentSync
description: "Export and import OpenClaw agent configurations. Use when: (1) exporting specific agent or all agents, (2) importing from local file or HTTP URL, (3) backing up or sharing agent settings"
---

# Claw Agent Sync - Export & Import

## Quick Start

### Export Agent

```bash
# Export all agents (to current directory)
~/.openclaw/skills/agent-sync/scripts/export_agent.sh

# Export all agents (to specified path)
~/.openclaw/skills/agent-sync/scripts/export_agent.sh "" /path/to/agents.zip

# Export specific agent
~/.openclaw/skills/agent-sync/scripts/export_agent.sh claw1

# Export specific agent to specified path
~/.openclaw/skills/agent-sync/scripts/export_agent.sh claw1 /tmp/claw1.zip
```

Exported package contains:
- `agents/<agent-name>/` - Each agent's config directory
  - `IDENTITY.md` - Agent identity definition
  - `SOUL.md` - Agent personality/behavior
  - `USER.md` - User information
  - `AGENTS.md` - Agent behavior guidelines
  - `TOOLS.md` - Tools configuration
  - `HEARTBEAT.md` - Heartbeat configuration
  - `BOOTSTRAP.md` - Bootstrap configuration
  - `agent/` - Agent runtime configuration
  - `agent-info.json` - Metadata

### Import Agent

```bash
# Import from local package
~/.openclaw/skills/agent-sync/scripts/import_agent.sh /path/to/agents.zip

# Import from HTTP URL
~/.openclaw/skills/agent-sync/scripts/import_agent.sh https://example.com/agents.zip
```

Import process:
1. Detect agent(s) in package
2. Check if each agent already exists
3. If exists → prompt user to skip
4. If not exists → auto import

## Notes

- Duplicate agent names will prompt to skip
- Does not include sessions (conversation history)
- Does not include custom skills
