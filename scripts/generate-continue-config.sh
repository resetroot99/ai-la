#!/bin/bash

################################################################################
# Generate Continue Configuration from Developer Memory
# Creates a personalized Continue config based on learned patterns
################################################################################

set -e

MEMORY_DIR="${HOME}/.ai-coding-stack/memory"
CONTINUE_DIR="${HOME}/.continue"
OUTPUT_FILE="${CONTINUE_DIR}/config.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Create Continue directory if it doesn't exist
mkdir -p "$CONTINUE_DIR"

log "Generating Continue configuration from developer memory..."

# Check if memory files exist
if [ ! -f "${MEMORY_DIR}/dev-patterns.json" ] && [ ! -f "${MEMORY_DIR}/dev-preferences.json" ]; then
    log_info "No memory data found. Creating default configuration..."
    
    # Get installed Ollama models
    MODELS=$(curl -s http://localhost:11434/api/tags 2>/dev/null | jq -r '.models[].name' || echo "")
    
    if [ -z "$MODELS" ]; then
        log_info "No Ollama models found. Using default configuration."
        PRIMARY_MODEL="qwen2.5-coder:7b"
    else
        PRIMARY_MODEL=$(echo "$MODELS" | head -1)
    fi
    
    cat > "$OUTPUT_FILE" << EOF
{
  "models": [
    {
      "title": "Primary Model",
      "provider": "ollama",
      "model": "$PRIMARY_MODEL"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Autocomplete",
    "provider": "ollama",
    "model": "$PRIMARY_MODEL"
  }
}
EOF
    
    log "✓ Default configuration created at $OUTPUT_FILE"
    exit 0
fi

# Load memory data
PATTERNS_DATA=$(cat "${MEMORY_DIR}/dev-patterns.json" 2>/dev/null || echo '{}')
PREFERENCES_DATA=$(cat "${MEMORY_DIR}/dev-preferences.json" 2>/dev/null || echo '{}')
BEHAVIORS_DATA=$(cat "${MEMORY_DIR}/dev-behaviors.json" 2>/dev/null || echo '{}')

# Get installed models
OLLAMA_MODELS=$(curl -s http://localhost:11434/api/tags 2>/dev/null | jq -r '.models[].name' || echo "")

# Select primary model based on preferences
PRIMARY_MODEL=$(echo "$OLLAMA_MODELS" | grep -E "qwen2.5-coder|deepseek-coder|codellama" | head -1)
if [ -z "$PRIMARY_MODEL" ]; then
    PRIMARY_MODEL=$(echo "$OLLAMA_MODELS" | head -1)
fi

# Generate custom instructions from memory
CUSTOM_INSTRUCTIONS=$(cat << 'EOF'
# Developer Profile & Learned Patterns

You are assisting a developer with the following profile and preferences:

EOF
)

# Add language preferences
LANGUAGES=$(echo "$PREFERENCES_DATA" | jq -r '.languages[]?.name // empty' 2>/dev/null | head -5)
if [ -n "$LANGUAGES" ]; then
    CUSTOM_INSTRUCTIONS+="## Preferred Languages
"
    while IFS= read -r lang; do
        CUSTOM_INSTRUCTIONS+="- $lang
"
    done <<< "$LANGUAGES"
    CUSTOM_INSTRUCTIONS+="
"
fi

# Add framework preferences
FRAMEWORKS=$(echo "$PREFERENCES_DATA" | jq -r '.frameworks[]?.name // empty' 2>/dev/null | head -5)
if [ -n "$FRAMEWORKS" ]; then
    CUSTOM_INSTRUCTIONS+="## Preferred Frameworks
"
    while IFS= read -r fw; do
        CUSTOM_INSTRUCTIONS+="- $fw
"
    done <<< "$FRAMEWORKS"
    CUSTOM_INSTRUCTIONS+="
"
fi

# Add coding patterns
PATTERNS=$(echo "$PATTERNS_DATA" | jq -r '.coding_patterns[]? | "- " + .pattern_type + ": " + .pattern' 2>/dev/null | head -10)
if [ -n "$PATTERNS" ]; then
    CUSTOM_INSTRUCTIONS+="## Coding Patterns & Preferences
$PATTERNS

"
fi

# Add code style preferences
CODE_STYLE=$(echo "$PREFERENCES_DATA" | jq -r '
if .code_style then
  "## Code Style Preferences\n" +
  "- Indentation: " + (.code_style.indentation // "2_spaces") + "\n" +
  "- Quotes: " + (.code_style.quotes // "single") + "\n" +
  "- Semicolons: " + (if .code_style.semicolons then "yes" else "no" end) + "\n" +
  "- Line length: " + (.code_style.line_length // 100 | tostring) + "\n"
else "" end
' 2>/dev/null)

if [ -n "$CODE_STYLE" ]; then
    CUSTOM_INSTRUCTIONS+="$CODE_STYLE
"
fi

# Add testing approach
TESTING=$(echo "$BEHAVIORS_DATA" | jq -r '
if .testing_approach then
  "## Testing Approach\n" +
  "- Style: " + .testing_approach + "\n"
else "" end
' 2>/dev/null)

if [ -n "$TESTING" ]; then
    CUSTOM_INSTRUCTIONS+="$TESTING
"
fi

# Add documentation style
DOCS=$(echo "$BEHAVIORS_DATA" | jq -r '
if .documentation_style then
  "## Documentation Style\n" +
  "- Preference: " + .documentation_style + "\n"
else "" end
' 2>/dev/null)

if [ -n "$DOCS" ]; then
    CUSTOM_INSTRUCTIONS+="$DOCS
"
fi

# Add refactoring triggers
REFACTORING=$(echo "$BEHAVIORS_DATA" | jq -r '
if .refactoring_triggers then
  "## Refactoring Triggers\n" +
  (.refactoring_triggers | map("- " + .) | join("\n")) + "\n"
else "" end
' 2>/dev/null)

if [ -n "$REFACTORING" ]; then
    CUSTOM_INSTRUCTIONS+="$REFACTORING
"
fi

CUSTOM_INSTRUCTIONS+="
## Instructions for AI Assistant

1. **Follow the patterns above** when generating code
2. **Match the code style preferences** exactly
3. **Respect the testing approach** when writing tests
4. **Use preferred languages and frameworks** when suggesting solutions
5. **Apply refactoring triggers** when reviewing code
6. **Maintain consistency** with the developer's established patterns

When the developer asks for code, prioritize solutions that align with their learned preferences and patterns.
"

# Create the full Continue configuration
cat > "$OUTPUT_FILE" << EOF
{
  "models": [
    {
      "title": "Primary Model (Personalized)",
      "provider": "ollama",
      "model": "$PRIMARY_MODEL",
      "systemMessage": $(echo "$CUSTOM_INSTRUCTIONS" | jq -Rs .)
    }
  ],
  "tabAutocompleteModel": {
    "title": "Autocomplete",
    "provider": "ollama",
    "model": "$PRIMARY_MODEL"
  },
  "embeddingsProvider": {
    "provider": "ollama",
    "model": "nomic-embed-text"
  },
  "contextProviders": [
    {
      "name": "code",
      "params": {}
    },
    {
      "name": "docs",
      "params": {}
    },
    {
      "name": "diff",
      "params": {}
    },
    {
      "name": "terminal",
      "params": {}
    },
    {
      "name": "problems",
      "params": {}
    },
    {
      "name": "folder",
      "params": {}
    },
    {
      "name": "codebase",
      "params": {}
    }
  ],
  "slashCommands": [
    {
      "name": "edit",
      "description": "Edit highlighted code"
    },
    {
      "name": "comment",
      "description": "Write comments for highlighted code"
    },
    {
      "name": "share",
      "description": "Export this session"
    },
    {
      "name": "cmd",
      "description": "Generate a shell command"
    },
    {
      "name": "commit",
      "description": "Generate a commit message"
    }
  ],
  "customCommands": [
    {
      "name": "refactor",
      "prompt": "Refactor the following code following my established patterns and preferences. Look for: code duplication, long functions, poor naming, and tight coupling. {{{ input }}}",
      "description": "Refactor code using learned patterns"
    },
    {
      "name": "review",
      "prompt": "Review this code for: readability, security, performance, and adherence to my coding patterns. {{{ input }}}",
      "description": "Code review based on preferences"
    },
    {
      "name": "test",
      "prompt": "Generate tests for this code following my testing approach and patterns. {{{ input }}}",
      "description": "Generate tests matching style"
    },
    {
      "name": "explain",
      "prompt": "Explain this code in moderate detail, focusing on the logic and patterns used. {{{ input }}}",
      "description": "Explain code"
    }
  ],
  "allowAnonymousTelemetry": false,
  "docs": []
}
EOF

log "✓ Personalized Continue configuration created at $OUTPUT_FILE"
log_info "Configuration includes:"
log_info "  - Custom system message with your patterns"
log_info "  - Personalized slash commands"
log_info "  - Context providers for better awareness"
log_info ""
log_info "Restart VSCode to apply the new configuration"

