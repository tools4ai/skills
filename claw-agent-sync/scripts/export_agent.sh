#!/bin/bash
# OpenClaw Agent Export Script
# Usage: export_agent.sh [agent_name] [output_path] [-d|--directory]
# Without agent name, exports all agents
# With -d|--directory, exports as directory instead of zip

set -e

# Parse arguments
AGENT_NAME=""
OUTPUT_PATH=""
EXPORT_AS_DIR=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory)
            EXPORT_AS_DIR=true
            shift
            ;;
        *)
            if [ -z "$AGENT_NAME" ]; then
                AGENT_NAME="$1"
            elif [ -z "$OUTPUT_PATH" ]; then
                OUTPUT_PATH="$1"
            fi
            shift
            ;;
    esac
done

# Set default output path
if [ -z "$OUTPUT_PATH" ]; then
    if [ "$EXPORT_AS_DIR" = true ]; then
        OUTPUT_PATH="./agent-export-$(date +%Y%m%d-%H%M%S)"
    else
        OUTPUT_PATH="./agent-backup-$(date +%Y%m%d-%H%M%S).zip"
    fi
fi

# Determine OpenCLAW directories
OPENCLAW_DIR="$HOME/.openclaw"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"

# Try to get agents directory from config, fallback to default
if [ -f "$CONFIG_FILE" ] && command -v jq &> /dev/null; then
    # If AGENT_NAME specified, find that agent's workspace; otherwise use first agent with workspace
    if [ -n "$AGENT_NAME" ]; then
        AGENTS_DIR=$(cat "$CONFIG_FILE" | jq -r ".agents.list[] | select(.name == \"$AGENT_NAME\") | .workspace" 2>/dev/null | sed 's/\/[^/]*$//')
    else
        AGENTS_DIR=$(cat "$CONFIG_FILE" | jq -r '[.agents.list[] | select(.workspace)] | if length > 0 then .[0].workspace else null end' 2>/dev/null | sed 's/\/[^/]*$//')
    fi
    if [ -z "$AGENTS_DIR" ] || [ "$AGENTS_DIR" = "null" ]; then
        AGENTS_DIR="$OPENCLAW_DIR/agents"
    fi
else
    AGENTS_DIR="$OPENCLAW_DIR/agents"
fi

echo "📦 Exporting OpenClaw Agent configuration from $AGENTS_DIR..."
echo "📍 Output: $OUTPUT_PATH"
if [ "$EXPORT_AS_DIR" = true ]; then
    echo "📁 Format: Directory"
else
    echo "📦 Format: ZIP"
fi

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

# Export based on format
if [ "$EXPORT_AS_DIR" = true ]; then
    # Export as directory
    if [ -z "$AGENT_NAME" ]; then
        cp -r "$TEMP_DIR/agents" "$OUTPUT_PATH"
    else
        mkdir -p "$OUTPUT_PATH"
        cp -r "$TEMP_DIR/agent"/* "$OUTPUT_PATH/"
    fi
    echo "✅ Export complete: $OUTPUT_PATH"
    echo "📊 Contents:"
    ls -la "$OUTPUT_PATH"
else
    # Create zip package
    cd "$TEMP_DIR"
    zip -r "$OUTPUT_PATH" .

    echo "✅ Export complete: $OUTPUT_PATH"
    echo "📊 Contents:"
    unzip -l "$OUTPUT_PATH" | tail -n +3
fi
