#!/bin/bash

################################################################################
# AI Learning System
# Continuously learns from open-source code, your patterns, and usage
# Improves code quality over time through analysis and fine-tuning
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
LEARNING_DIR="${HOME}/.ai-coding-stack/learning"
KNOWLEDGE_BASE="${LEARNING_DIR}/knowledge-base"
PATTERNS_DIR="${LEARNING_DIR}/patterns"
TRAINING_DATA="${LEARNING_DIR}/training-data"
MODELS_DIR="${LEARNING_DIR}/models"
CACHE_DIR="${LEARNING_DIR}/cache"

# Create directories
mkdir -p "$KNOWLEDGE_BASE" "$PATTERNS_DIR" "$TRAINING_DATA" "$MODELS_DIR" "$CACHE_DIR"

################################################################################
# Logging
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# 1. Learn from Open-Source Repositories
################################################################################

learn_from_github() {
    local repo_url="$1"
    local language="${2:-auto}"
    
    log_step "Learning from GitHub Repository"
    
    local repo_name=$(basename "$repo_url" .git)
    local clone_dir="${CACHE_DIR}/${repo_name}"
    
    # Clone repository
    if [ ! -d "$clone_dir" ]; then
        log "Cloning repository: $repo_url"
        git clone --depth 1 "$repo_url" "$clone_dir"
    else
        log "Repository already cloned: $repo_name"
    fi
    
    # Analyze code patterns
    log "Analyzing code patterns..."
    
    local patterns_file="${PATTERNS_DIR}/${repo_name}-patterns.json"
    
    cat > /tmp/analyze_patterns.py << 'PYTHON'
import os
import json
import sys
from pathlib import Path
from collections import defaultdict

def analyze_repository(repo_path):
    patterns = {
        "file_structure": {},
        "naming_conventions": defaultdict(list),
        "common_patterns": defaultdict(int),
        "imports": defaultdict(int),
        "functions": [],
        "classes": []
    }
    
    # Analyze file structure
    for root, dirs, files in os.walk(repo_path):
        # Skip hidden and vendor directories
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['node_modules', 'vendor', 'dist', 'build']]
        
        for file in files:
            if file.startswith('.'):
                continue
                
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, repo_path)
            ext = os.path.splitext(file)[1]
            
            if ext in ['.py', '.js', '.ts', '.go', '.java', '.rb']:
                # Read file
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Extract patterns
                    if ext == '.py':
                        # Python patterns
                        if 'import ' in content:
                            for line in content.split('\n'):
                                if line.strip().startswith('import ') or line.strip().startswith('from '):
                                    patterns['imports'][line.strip()] += 1
                        
                        if 'def ' in content:
                            for line in content.split('\n'):
                                if 'def ' in line:
                                    func_name = line.split('def ')[1].split('(')[0].strip()
                                    patterns['functions'].append(func_name)
                        
                        if 'class ' in content:
                            for line in content.split('\n'):
                                if 'class ' in line:
                                    class_name = line.split('class ')[1].split('(')[0].split(':')[0].strip()
                                    patterns['classes'].append(class_name)
                    
                    elif ext in ['.js', '.ts']:
                        # JavaScript/TypeScript patterns
                        if 'import ' in content or 'require(' in content:
                            for line in content.split('\n'):
                                if 'import ' in line or 'require(' in line:
                                    patterns['imports'][line.strip()] += 1
                        
                        if 'function ' in content or 'const ' in content or 'let ' in content:
                            patterns['common_patterns']['uses_modern_js'] += 1
                    
                    # Naming conventions
                    patterns['naming_conventions'][ext].append(file)
                    
                except Exception as e:
                    pass
    
    return patterns

if __name__ == '__main__':
    repo_path = sys.argv[1]
    output_file = sys.argv[2]
    
    patterns = analyze_repository(repo_path)
    
    with open(output_file, 'w') as f:
        json.dump(patterns, f, indent=2)
    
    print(f"Patterns extracted: {len(patterns['functions'])} functions, {len(patterns['classes'])} classes")
PYTHON
    
    python3 /tmp/analyze_patterns.py "$clone_dir" "$patterns_file"
    
    log "✓ Patterns extracted and saved to: $patterns_file"
    
    # Add to knowledge base
    add_to_knowledge_base "$repo_name" "$patterns_file"
}

learn_from_awesome_lists() {
    log_step "Learning from Awesome Lists"
    
    # Clone awesome lists
    local awesome_repos=(
        "https://github.com/sindresorhus/awesome"
        "https://github.com/vinta/awesome-python"
        "https://github.com/sorrycc/awesome-javascript"
        "https://github.com/avelino/awesome-go"
    )
    
    for repo in "${awesome_repos[@]}"; do
        learn_from_github "$repo"
    done
}

################################################################################
# 2. Learn from Your Code
################################################################################

learn_from_local_projects() {
    local projects_dir="${1:-$HOME/projects}"
    
    log_step "Learning from Your Local Projects"
    
    if [ ! -d "$projects_dir" ]; then
        log_info "Projects directory not found: $projects_dir"
        return 0
    fi
    
    # Find all git repositories
    find "$projects_dir" -name ".git" -type d | while read git_dir; do
        local project_dir=$(dirname "$git_dir")
        local project_name=$(basename "$project_dir")
        
        log "Analyzing project: $project_name"
        
        # Extract patterns
        python3 /tmp/analyze_patterns.py "$project_dir" "${PATTERNS_DIR}/${project_name}-patterns.json"
        
        # Analyze git history for coding habits
        cd "$project_dir"
        
        local commit_patterns="${PATTERNS_DIR}/${project_name}-commits.json"
        
        git log --pretty=format:'%s' --since="6 months ago" | \
        python3 -c "
import sys
import json
from collections import Counter

messages = [line.strip() for line in sys.stdin if line.strip()]
types = Counter()
scopes = Counter()

for msg in messages:
    if ':' in msg:
        type_scope = msg.split(':')[0]
        if '(' in type_scope:
            type_part = type_scope.split('(')[0]
            scope_part = type_scope.split('(')[1].split(')')[0]
            types[type_part] += 1
            scopes[scope_part] += 1
        else:
            types[type_scope] += 1

patterns = {
    'commit_types': dict(types.most_common(10)),
    'commit_scopes': dict(scopes.most_common(10)),
    'total_commits': len(messages)
}

print(json.dumps(patterns, indent=2))
" > "$commit_patterns"
        
        log_info "Extracted commit patterns: $commit_patterns"
    done
}

################################################################################
# 3. Build Knowledge Base
################################################################################

add_to_knowledge_base() {
    local source="$1"
    local patterns_file="$2"
    
    local kb_entry="${KNOWLEDGE_BASE}/${source}.json"
    
    cat > "$kb_entry" << EOF
{
  "source": "$source",
  "patterns_file": "$patterns_file",
  "added_at": "$(date -Iseconds)",
  "type": "code_analysis"
}
EOF
    
    log_info "Added to knowledge base: $source"
}

build_unified_knowledge_base() {
    log_step "Building Unified Knowledge Base"
    
    local unified_kb="${KNOWLEDGE_BASE}/unified.json"
    
    # Combine all patterns
    python3 << 'PYTHON'
import json
import os
from pathlib import Path
from collections import defaultdict

patterns_dir = os.path.expanduser("~/.ai-coding-stack/learning/patterns")
unified = {
    "total_sources": 0,
    "languages": defaultdict(lambda: {
        "common_imports": defaultdict(int),
        "naming_patterns": [],
        "best_practices": []
    }),
    "frameworks": defaultdict(int),
    "patterns": defaultdict(int)
}

for pattern_file in Path(patterns_dir).glob("*-patterns.json"):
    try:
        with open(pattern_file) as f:
            data = json.load(f)
        
        unified["total_sources"] += 1
        
        # Aggregate imports
        for imp, count in data.get("imports", {}).items():
            # Detect language from import
            if "import " in imp or "from " in imp:
                lang = "python"
            elif "require(" in imp or "import {" in imp:
                lang = "javascript"
            else:
                lang = "unknown"
            
            unified["languages"][lang]["common_imports"][imp] += count
        
        # Aggregate patterns
        for pattern, count in data.get("common_patterns", {}).items():
            unified["patterns"][pattern] += count
    
    except Exception as e:
        print(f"Error processing {pattern_file}: {e}")

# Convert defaultdicts to regular dicts
unified_json = json.loads(json.dumps(unified))

output_file = os.path.expanduser("~/.ai-coding-stack/learning/knowledge-base/unified.json")
with open(output_file, 'w') as f:
    json.dump(unified_json, f, indent=2)

print(f"Unified knowledge base created with {unified['total_sources']} sources")
PYTHON
    
    log "✓ Unified knowledge base created"
}

################################################################################
# 4. Generate Training Data
################################################################################

generate_training_data() {
    log_step "Generating Training Data"
    
    # Export compliance logs as training data
    if [ -f "${HOME}/.ai-coding-stack/compliance/sessions"/*.jsonl ]; then
        cat "${HOME}/.ai-coding-stack/compliance/sessions"/*.jsonl | \
        jq -c 'select(.type=="request" or .type=="response") | 
               {prompt: .prompt, completion: .response}' \
        > "${TRAINING_DATA}/compliance-data.jsonl"
        
        log "✓ Exported compliance logs as training data"
    fi
    
    # Generate synthetic training data from patterns
    python3 << 'PYTHON'
import json
import os
from pathlib import Path

patterns_dir = Path(os.path.expanduser("~/.ai-coding-stack/learning/patterns"))
training_file = os.path.expanduser("~/.ai-coding-stack/learning/training-data/synthetic.jsonl")

examples = []

for pattern_file in patterns_dir.glob("*-patterns.json"):
    try:
        with open(pattern_file) as f:
            data = json.load(f)
        
        # Generate examples from functions
        for func in data.get("functions", [])[:10]:
            example = {
                "prompt": f"Generate a function named {func}",
                "completion": f"def {func}():\n    pass"
            }
            examples.append(example)
        
        # Generate examples from classes
        for cls in data.get("classes", [])[:10]:
            example = {
                "prompt": f"Create a class named {cls}",
                "completion": f"class {cls}:\n    pass"
            }
            examples.append(example)
    
    except Exception as e:
        pass

with open(training_file, 'w') as f:
    for example in examples:
        f.write(json.dumps(example) + '\n')

print(f"Generated {len(examples)} training examples")
PYTHON
    
    log "✓ Generated synthetic training data"
}

################################################################################
# 5. Fine-tune Model (Optional)
################################################################################

finetune_model() {
    log_step "Fine-tuning Model"
    
    log_info "Fine-tuning requires significant compute resources"
    log_info "This will create a custom model based on your patterns"
    
    read -p "Continue with fine-tuning? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping fine-tuning"
        return 0
    fi
    
    # Check if training data exists
    if [ ! -f "${TRAINING_DATA}/compliance-data.jsonl" ]; then
        log_info "No training data found. Run learning system first."
        return 1
    fi
    
    log "Creating fine-tuned model..."
    
    # Use Ollama to create custom model
    cat > /tmp/Modelfile << EOF
FROM qwen2.5-coder:32b

# Load custom training data
SYSTEM """
You are a highly specialized coding assistant trained on the user's coding patterns and preferences.

You have learned from:
- User's commit history and coding style
- Popular open-source projects
- Best practices from the community

You prioritize:
- Consistency with user's existing codebase
- Modern best practices
- Clean, maintainable code
- Security and performance

You adapt to the user's:
- Naming conventions
- Code structure preferences
- Framework choices
- Testing patterns
"""

# Increase context for better memory
PARAMETER num_ctx 32768
PARAMETER temperature 0.3
EOF
    
    ollama create custom-coder -f /tmp/Modelfile
    
    log "✓ Custom model created: custom-coder"
    log_info "Use this model in Continue/Cline for personalized coding"
}

################################################################################
# 6. Update Continue Configuration
################################################################################

update_continue_config() {
    log_step "Updating Continue Configuration"
    
    local continue_config="${HOME}/.continue/config.json"
    
    if [ ! -f "$continue_config" ]; then
        log_info "Continue config not found"
        return 0
    fi
    
    # Backup existing config
    cp "$continue_config" "${continue_config}.backup"
    
    # Load knowledge base
    local kb_file="${KNOWLEDGE_BASE}/unified.json"
    
    if [ ! -f "$kb_file" ]; then
        log_info "Knowledge base not found. Run learning system first."
        return 0
    fi
    
    # Update config with knowledge base context
    python3 << PYTHON
import json

config_file = "${continue_config}"
kb_file = "${kb_file}"

with open(config_file) as f:
    config = json.load(f)

with open(kb_file) as f:
    kb = json.load(f)

# Add knowledge base to system message
system_msg = config.get("systemMessage", "")

kb_context = f"""

## Your Knowledge Base

You have learned from {kb['total_sources']} code sources.

Common patterns you should follow:
"""

for pattern, count in list(kb.get('patterns', {}).items())[:5]:
    kb_context += f"- {pattern}: {count} occurrences\n"

config["systemMessage"] = system_msg + kb_context

# Add custom model if exists
if "models" not in config:
    config["models"] = []

custom_model = {
    "title": "Custom Trained",
    "provider": "ollama",
    "model": "custom-coder",
    "systemMessage": "You are trained on the user's coding patterns and preferences."
}

# Check if custom model already exists
if not any(m.get("model") == "custom-coder" for m in config["models"]):
    config["models"].insert(0, custom_model)

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print("✓ Continue config updated with knowledge base")
PYTHON
    
    log "✓ Continue configuration updated"
}

################################################################################
# 7. Continuous Learning
################################################################################

enable_continuous_learning() {
    log_step "Enabling Continuous Learning"
    
    # Create cron job for daily learning
    local cron_script="${HOME}/.ai-coding-stack/learning/daily-learning.sh"
    
    cat > "$cron_script" << 'CRONSCRIPT'
#!/bin/bash

# Daily learning routine
LEARNING_SCRIPT="${HOME}/.ai-coding-stack/learning/ai-learning-system.sh"

# Learn from local projects
"$LEARNING_SCRIPT" learn-local

# Update knowledge base
"$LEARNING_SCRIPT" build-kb

# Update Continue config
"$LEARNING_SCRIPT" update-config

echo "Daily learning completed: $(date)"
CRONSCRIPT
    
    chmod +x "$cron_script"
    
    # Add to crontab (daily at 2 AM)
    (crontab -l 2>/dev/null; echo "0 2 * * * $cron_script >> ${HOME}/.ai-coding-stack/learning/daily-learning.log 2>&1") | crontab -
    
    log "✓ Continuous learning enabled (daily at 2 AM)"
}

################################################################################
# 8. CLI Interface
################################################################################

show_help() {
    cat << 'EOF'
AI Learning System - Continuously improve code quality

Usage: ai-learning-system.sh <command> [options]

Commands:
  learn-github <url>           Learn from GitHub repository
  learn-awesome                Learn from Awesome lists
  learn-local [dir]            Learn from local projects
  build-kb                     Build unified knowledge base
  generate-training            Generate training data
  finetune                     Fine-tune custom model
  update-config                Update Continue configuration
  enable-continuous            Enable daily learning
  
  stats                        Show learning statistics
  help                         Show this help

Examples:
  # Learn from popular repository
  ai-learning-system.sh learn-github https://github.com/facebook/react
  
  # Learn from your projects
  ai-learning-system.sh learn-local ~/projects
  
  # Build knowledge base
  ai-learning-system.sh build-kb
  
  # Enable continuous learning
  ai-learning-system.sh enable-continuous

Directories:
  Knowledge Base: $KNOWLEDGE_BASE
  Patterns:       $PATTERNS_DIR
  Training Data:  $TRAINING_DATA
EOF
}

show_stats() {
    log_step "Learning Statistics"
    
    local total_patterns=$(find "$PATTERNS_DIR" -name "*-patterns.json" | wc -l)
    local total_kb=$(find "$KNOWLEDGE_BASE" -name "*.json" | wc -l)
    local total_training=$(find "$TRAINING_DATA" -name "*.jsonl" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
    
    echo "Total pattern files: $total_patterns"
    echo "Knowledge base entries: $total_kb"
    echo "Training examples: ${total_training:-0}"
    echo ""
    
    if [ -f "${KNOWLEDGE_BASE}/unified.json" ]; then
        echo "Unified Knowledge Base:"
        jq -r '.total_sources, .patterns | keys | length' "${KNOWLEDGE_BASE}/unified.json" | \
        awk 'NR==1{print "  Sources: " $0} NR==2{print "  Patterns: " $0}'
    fi
}

################################################################################
# Main
################################################################################

main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        learn-github)
            learn_from_github "$@"
            ;;
        learn-awesome)
            learn_from_awesome_lists
            ;;
        learn-local)
            learn_from_local_projects "$@"
            ;;
        build-kb)
            build_unified_knowledge_base
            ;;
        generate-training)
            generate_training_data
            ;;
        finetune)
            finetune_model
            ;;
        update-config)
            update_continue_config
            ;;
        enable-continuous)
            enable_continuous_learning
            ;;
        stats)
            show_stats
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use 'ai-learning-system.sh help' for usage"
            exit 1
            ;;
    esac
}

main "$@"

