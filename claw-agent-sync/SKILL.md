---
name: clawAgentSync
description: "Export and import OpenClaw agent configurations. Use when: (1) exporting specific agent or all agents, (2) importing from local file or HTTP URL, (3) backing up or sharing agent settings"
---

# Claw Agent Sync - Export & Import

## Quick Start

### Export Agent

```bash
# Export all agents as ZIP (to current directory)
~/.openclaw/skills/agent-sync/scripts/export_agent.sh

# Export all agents as ZIP (to specified path)
~/.openclaw/skills/agent-sync/scripts/export_agent.sh "" /path/to/agents.zip

# Export all agents as directory
~/.openclaw/skills/agent-sync/scripts/export_agent.sh -d

# Export all agents to specified directory
~/.openclaw/skills/agent-sync/scripts/export_agent.sh -d /path/to/agents

# Export specific agent as ZIP
~/.openclaw/skills/agent-sync/scripts/export_agent.sh claw1

# Export specific agent as directory
~/.openclaw/skills/agent-sync/scripts/export_agent.sh claw1 -d

# Export specific agent to specified directory
~/.openclaw/skills/agent-sync/scripts/export_agent.sh claw1 /tmp/claw1 -d
```

Exported package contains the agent configuration files (see Agent Files Location below).

### Import Agent

```bash
# Import from local ZIP package
~/.openclaw/skills/agent-sync/scripts/import_agent.sh /path/to/agents.zip

# Import from HTTP URL
~/.openclaw/skills/agent-sync/scripts/import_agent.sh https://example.com/agents.zip

# Import from directory (auto-detects structure)
~/.openclaw/skills/agent-sync/scripts/import_agent.sh /path/to/agents-directory

# Import from single agent directory
~/.openclaw/skills/agent-sync/scripts/import_agent.sh /path/to/claw1
```

Import process:
1. Detect agent(s) in package
2. Check if each agent already exists
3. If exists → prompt user to skip
4. If not exists → auto import

## Agent Directory Configuration

OpenCLAW agent files are located in the agent workspace directory. You can determine this directory dynamically:

### Default Location
```
~/.openclaw/agents/<agent-name>/
```

### Dynamic Lookup (from OpenCLAW config)
Read the agent's workspace from `~/.openclaw/openclaw.json`:

```bash
# Get workspace for specific agent
cat ~/.openclaw/openclaw.json | jq -r '.agents[] | select(.id=="<agent-name>") | .workspace'

# Get all agent directories
cat ~/.openclaw/openclaw.json | jq -r '.agents[] | "\(.id): \(.workspace)"'
```

### Agent Files Location
Each agent directory contains:
- `IDENTITY.md` - Agent identity definition
- `SOUL.md` - Agent personality/behavior
- `USER.md` - User information
- `AGENTS.md` - Agent behavior guidelines
- `TOOLS.md` - Tools configuration
- `HEARTBEAT.md` - Heartbeat configuration
- `BOOTSTRAP.md` - Bootstrap configuration
- `agent/` - Agent runtime configuration
- `agent-info.json` - Metadata

## Notes

- Duplicate agent names will prompt to skip
- Does not include sessions (conversation history)
- Does not include custom skills
