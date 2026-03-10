#!/bin/bash
# OpenClaw Agent Import Script
# Usage: import_agent.sh <source_path_or_url|directory>
# Supports importing from local file, URL, or directory

set -e

SOURCE="$1"
OPENCLAW_DIR="$HOME/.openclaw"
CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"

# Try to get agents directory from config, fallback to default
if [ -f "$CONFIG_FILE" ] && command -v jq &> /dev/null; then
    # Get first agent's workspace to derive base agents directory
    AGENTS_DIR=$(cat "$CONFIG_FILE" | jq -r '.agents[0].workspace' 2>/dev/null | sed 's/\/[^/]*$//')
    if [ -z "$AGENTS_DIR" ] || [ "$AGENTS_DIR" = "null" ]; then
        AGENTS_DIR="$OPENCLAW_DIR/agents"
    fi
else
    AGENTS_DIR="$OPENCLAW_DIR/agents"
fi

if [ -z "$SOURCE" ]; then
    echo "❌ Please specify import source"
    echo "Usage: import_agent.sh <local_file|URL|directory>"
    exit 1
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Determine source type
if [[ "$SOURCE" =~ ^https?:// ]]; then
    echo "🌐 Downloading from URL: $SOURCE"
    curl -L -o "$TEMP_DIR/agent.zip" "$SOURCE"
    ZIP_FILE="$TEMP_DIR/agent.zip"
    if [ ! -f "$ZIP_FILE" ]; then
        echo "❌ Download failed"
        exit 1
    fi
    echo "📦 Extracting..."
    unzip -o "$ZIP_FILE" -d "$TEMP_DIR/extracted" > /dev/null
    EXTRACTED_DIR="$TEMP_DIR/extracted"
elif [ -d "$SOURCE" ]; then
    echo "📁 Importing from directory: $SOURCE"
    # Check if it's a single agent directory or contains agents/
    if [ -d "$SOURCE/agents" ]; then
        # Multiple agents: source/agents/agent1/, source/agents/agent2/
        EXTRACTED_DIR="$SOURCE"
        AGENT_TYPE="multiple"
    elif [ -f "$SOURCE/IDENTITY.md" ]; then
        # Single agent in root: source/IDENTITY.md
        EXTRACTED_DIR="$SOURCE"
        AGENT_TYPE="single_root"
    elif [ -d "$SOURCE/agent" ] && [ -f "$SOURCE/agent/IDENTITY.md" ]; then
        # Single agent in subdir: source/agent/IDENTITY.md
        EXTRACTED_DIR="$SOURCE"
        AGENT_TYPE="single_subdir"
    else
        echo "❌ Invalid directory format: no agent files found"
        exit 1
    fi
else
    echo "📂 Loading from local file: $SOURCE"
    ZIP_FILE="$SOURCE"
    if [ ! -f "$ZIP_FILE" ]; then
        echo "❌ File not found: $ZIP_FILE"
        exit 1
    fi
    echo "📦 Extracting..."
    unzip -o "$ZIP_FILE" -d "$TEMP_DIR/extracted" > /dev/null
    EXTRACTED_DIR="$TEMP_DIR/extracted"
fi

# Validate package (only for zip-based import)
if [ -z "$AGENT_TYPE" ]; then
    # Validate package - support multiple structures
    # 1. agents/<agent>/ (multiple agents)
    # 2. agent/<files> (single agent, subdirectory)
    # 3. <files> (single agent, root directory)
        if [ -d "$EXTRACTED_DIR/agents" ]; then
            AGENT_TYPE="multiple"
        elif [ -d "$EXTRACTED_DIR/agent" ] && [ -f "$EXTRACTED_DIR/agent/IDENTITY.md" ]; then
            AGENT_TYPE="single_subdir"
        elif [ -f "$EXTRACTED_DIR/IDENTITY.md" ]; then
            AGENT_TYPE="single_root"
        else
            echo "❌ Invalid agent package: no identity files found"
            exit 1
        fi
    fi

    # Determine single or multiple agents
if [ "$AGENT_TYPE" = "multiple" ]; then
    AGENTS_TO_IMPORT=$(ls -1 "$EXTRACTED_DIR/agents/" 2>/dev/null)
    echo "📋 Found multiple agents: $AGENTS_TO_IMPORT"
elif [ "$AGENT_TYPE" = "single_subdir" ]; then
    AGENTS_TO_IMPORT="agent"
    if [ -f "$EXTRACTED_DIR/agent/agent-info.json" ]; then
        AGENT_NAME_FROM_INFO=$(grep -o '"name": *"[^"]*"' "$EXTRACTED_DIR/agent/agent-info.json" | cut -d'"' -f4)
        if [ -n "$AGENT_NAME_FROM_INFO" ]; then
            AGENTS_TO_IMPORT="$AGENT_NAME_FROM_INFO"
        fi
    fi
    echo "📋 Found agent: $AGENTS_TO_IMPORT"
elif [ "$AGENT_TYPE" = "single_root" ]; then
    AGENTS_TO_IMPORT="agent"
    if [ -f "$EXTRACTED_DIR/agent-info.json" ]; then
        AGENT_NAME_FROM_INFO=$(grep -o '"name": *"[^"]*"' "$EXTRACTED_DIR/agent-info.json" | cut -d'"' -f4)
        if [ -n "$AGENT_NAME_FROM_INFO" ]; then
            AGENTS_TO_IMPORT="$AGENT_NAME_FROM_INFO"
        fi
    fi
    echo "📋 Found agent: $AGENTS_TO_IMPORT"
fi

echo ""
echo "⚠️  The following action will be performed:"
echo "   - Import agent(s) → ~/.openclaw/agents/"
echo ""

read -p "Confirm import? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 0
fi

# Import each agent
for agent in $AGENTS_TO_IMPORT; do
    echo ""
    echo "📦 Processing agent: $agent"
    
    # Determine source directory
    case "$AGENT_TYPE" in
        multiple)
            SOURCE_DIR="$EXTRACTED_DIR/agents/$agent"
            ;;
        single_subdir)
            SOURCE_DIR="$EXTRACTED_DIR/agent"
            ;;
        single_root)
            SOURCE_DIR="$EXTRACTED_DIR"
            ;;
        *)
            continue
            ;;
    esac
    
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "   ❌ Source directory not found: $SOURCE_DIR"
        continue
    fi
    
    TARGET_DIR="$AGENTS_DIR/$agent"
    
    # Check if already exists
    if [ -d "$TARGET_DIR" ]; then
        echo "   ⚠️  Agent '$agent' already exists"
        read -p "   Skip? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "   ⏭️  Skipped $agent"
            continue
        fi
    else
        mkdir -p "$TARGET_DIR"
    fi
    
    # Copy identity files
    echo "   📄 Copying identity files..."
    for file in IDENTITY.md SOUL.md USER.md AGENTS.md TOOLS.md HEARTBEAT.md BOOTSTRAP.md; do
        if [ -f "$SOURCE_DIR/$file" ]; then
            cp "$SOURCE_DIR/$file" "$TARGET_DIR/"
            echo "   + $file"
        fi
    done
    
    # Copy agent config
    if [ -d "$SOURCE_DIR/agent" ]; then
        mkdir -p "$TARGET_DIR/agent"
        cp -r "$SOURCE_DIR/agent"/* "$TARGET_DIR/agent/" 2>/dev/null || true
        echo "   + agent/"
    fi
    
    echo "   ✅ $agent import complete"
done

# Register agent to openclaw.json
register_agent_to_config() {
    local agent_name="$1"
    local config_file="$OPENCLAW_DIR/openclaw.json"

    if [ ! -f "$config_file" ]; then
        echo "   ⚠️  Config file not found: $config_file"
        return 1
    fi

    # Check if agent already exists in config
    if grep -q "\"id\": \"$agent_name\"" "$config_file"; then
        echo "   ℹ️  Agent '$agent_name' already registered in config"
        return 0
    fi

    # Use python3 to safely update JSON
    python3 << EOF
import json

config_file = "$config_file"
agent_name = "$agent_name"
agent_dir = "$AGENTS_DIR/$agent_name"

with open(config_file, 'r') as f:
    config = json.load(f)

# Build new agent entry
agent_entry = {
    "id": agent_name,
    "name": agent_name,
    "workspace": f"{agent_dir}",
    "agentDir": f"{agent_dir}/agent"
}

# Add to agents list
if "agents" not in config:
    config["agents"] = {}
if "list" not in config["agents"]:
    config["agents"]["list"] = []

config["agents"]["list"].append(agent_entry)

# Write back
with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print("   ✅ Registered in config")
EOF

    if [ $? -eq 0 ]; then
        echo "   ✅ Agent '$agent_name' registered in openclaw.json"
    else
        echo "   ❌ Failed to register agent in config"
        return 1
    fi

    return 0
}

# Register each imported agent to config
echo ""
echo "📝 Registering agents to openclaw.json..."
for agent in $AGENTS_TO_IMPORT; do
    register_agent_to_config "$agent"
done

echo ""
echo "✅ Import complete!"
echo "💡 To switch agents, use openclaw CLI or restart openclaw"
