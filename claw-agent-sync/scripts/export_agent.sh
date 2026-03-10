#!/bin/bash
# OpenClaw Agent Export Script
# Usage: export_agent.sh [agent_name] [output_path]
# Without agent name, exports all agents

set -e

AGENT_NAME="$1"
OUTPUT_PATH="${2:-./agent-backup-$(date +%Y%m%d-%H%M%S).zip}"
OPENCLAW_DIR="$HOME/.openclaw"
AGENTS_DIR="$OPENCLAW_DIR/agents"

echo "📦 Exporting OpenClaw Agent configuration..."
echo "📍 Output: $OUTPUT_PATH"

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Get all agent list
get_agent_list() {
    ls -1 "$AGENTS_DIR" 2>/dev/null | grep -v '^sessions$' | grep -v '^agent$'
}

# Export single agent
export_single_agent() {
    local agent="$1"
    local dest="$2"
    local agent_dir="$AGENTS_DIR/$agent"
    
    if [ ! -d "$agent_dir" ]; then
        echo "❌ Agent does not exist: $agent"
        return 1
    fi
    
    echo "📦 Exporting agent: $agent"
    
    # Copy identity files
    for file in IDENTITY.md SOUL.md USER.md AGENTS.md TOOLS.md HEARTBEAT.md BOOTSTRAP.md; do
        if [ -f "$agent_dir/$file" ]; then
            cp "$agent_dir/$file" "$dest/"
        fi
    done
    
    # Copy agent config (optional)
    if [ -d "$agent_dir/agent" ]; then
        mkdir -p "$dest/agent"
        cp -r "$agent_dir/agent"/* "$dest/agent/" 2>/dev/null || true
    fi
    
    # Create agent metadata
    cat > "$dest/agent-info.json" << EOF
{
  "name": "$agent",
  "exported_at": "$(date -Iseconds)",
  "version": "1.0"
}
EOF
}

# List all agents if no name specified
if [ -z "$AGENT_NAME" ]; then
    echo "📋 Available agents:"
    for agent in $(get_agent_list); do
        echo "   - $agent"
    done
    echo ""
    
    # Export all agents
    echo "📦 Exporting all agents..."
    mkdir -p "$TEMP_DIR/agents"
    
    for agent in $(get_agent_list); do
        mkdir -p "$TEMP_DIR/agents/$agent"
        export_single_agent "$agent" "$TEMP_DIR/agents/$agent"
    done
else
    # Export specific agent
    echo "📦 Exporting agent: $AGENT_NAME"
    mkdir -p "$TEMP_DIR/agent"
    export_single_agent "$AGENT_NAME" "$TEMP_DIR/agent"
fi

# Create zip package
cd "$TEMP_DIR"
zip -r "$OUTPUT_PATH" .

echo "✅ Export complete: $OUTPUT_PATH"
echo "📊 Contents:"
unzip -l "$OUTPUT_PATH" | tail -n +3
