#!/bin/bash

################################################################################
# Installation Test Suite
# Validates all components before and after installation
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test report file
REPORT_FILE="/tmp/install-test-report-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# Test Framework
################################################################################

test_start() {
    local test_name="$1"
    echo -e "${BLUE}[TEST]${NC} $test_name" | tee -a "$REPORT_FILE"
    ((TESTS_TOTAL++))
}

test_pass() {
    local message="$1"
    echo -e "${GREEN}[PASS]${NC} $message" | tee -a "$REPORT_FILE"
    ((TESTS_PASSED++))
}

test_fail() {
    local message="$1"
    echo -e "${RED}[FAIL]${NC} $message" | tee -a "$REPORT_FILE"
    ((TESTS_FAILED++))
}

test_info() {
    local message="$1"
    echo -e "${YELLOW}[INFO]${NC} $message" | tee -a "$REPORT_FILE"
}

################################################################################
# Pre-Installation Tests
################################################################################

test_system_requirements() {
    test_start "System Requirements Check"
    
    # Check OS
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
        test_pass "Operating system supported: $OSTYPE"
    else
        test_fail "Unsupported OS: $OSTYPE"
        return 1
    fi
    
    # Check RAM
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        total_ram=$(free -g | awk '/^Mem:/{print $2}')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        total_ram=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    fi
    
    if [ "$total_ram" -ge 8 ]; then
        test_pass "RAM: ${total_ram}GB (minimum 8GB met)"
    else
        test_fail "Insufficient RAM: ${total_ram}GB (minimum 8GB required)"
        return 1
    fi
    
    # Check disk space
    available_disk=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_disk" -ge 20 ]; then
        test_pass "Disk space: ${available_disk}GB (minimum 20GB met)"
    else
        test_fail "Insufficient disk space: ${available_disk}GB (minimum 20GB required)"
        return 1
    fi
    
    # Check required commands
    local required_cmds=("curl" "git" "jq")
    for cmd in "${required_cmds[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            test_pass "Command available: $cmd"
        else
            test_fail "Missing required command: $cmd"
            return 1
        fi
    done
}

test_script_syntax() {
    test_start "Script Syntax Validation"
    
    local scripts=(
        "../install.sh"
        "../scripts/memory-manager.sh"
        "../scripts/generate-continue-config.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                test_pass "Syntax valid: $(basename "$script")"
            else
                test_fail "Syntax error in: $(basename "$script")"
                bash -n "$script" 2>&1 | tee -a "$REPORT_FILE"
                return 1
            fi
        else
            test_fail "Script not found: $script"
            return 1
        fi
    done
}

test_json_validity() {
    test_start "JSON Configuration Validation"
    
    local json_files=(
        "../configs/memory-schema.json"
        "../configs/memory-example.json"
    )
    
    for json_file in "${json_files[@]}"; do
        if [ -f "$json_file" ]; then
            if jq empty "$json_file" 2>/dev/null; then
                test_pass "Valid JSON: $(basename "$json_file")"
            else
                test_fail "Invalid JSON: $(basename "$json_file")"
                jq empty "$json_file" 2>&1 | tee -a "$REPORT_FILE"
                return 1
            fi
        else
            test_fail "JSON file not found: $json_file"
            return 1
        fi
    done
}

test_file_permissions() {
    test_start "File Permissions Check"
    
    local scripts=(
        "../install.sh"
        "../scripts/memory-manager.sh"
        "../scripts/generate-continue-config.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -x "$script" ]; then
            test_pass "Executable: $(basename "$script")"
        else
            test_fail "Not executable: $(basename "$script")"
            test_info "Fix with: chmod +x $script"
            return 1
        fi
    done
}

################################################################################
# Installation Tests
################################################################################

test_ollama_installation() {
    test_start "Ollama Installation"
    
    if command -v ollama &> /dev/null; then
        test_pass "Ollama is installed"
        local version=$(ollama --version 2>/dev/null || echo "unknown")
        test_info "Ollama version: $version"
        return 0
    else
        test_fail "Ollama is not installed"
        return 1
    fi
}

test_ollama_service() {
    test_start "Ollama Service Status"
    
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        test_pass "Ollama service is running"
        return 0
    else
        test_fail "Ollama service is not running"
        test_info "Try: ollama serve"
        return 1
    fi
}

test_ollama_models() {
    test_start "Ollama Models Check"
    
    local models=$(curl -s http://localhost:11434/api/tags 2>/dev/null | jq -r '.models[].name' || echo "")
    
    if [ -z "$models" ]; then
        test_fail "No models installed"
        test_info "Install with: ollama pull qwen2.5-coder:7b"
        return 1
    fi
    
    local model_count=$(echo "$models" | wc -l)
    test_pass "Found $model_count model(s) installed"
    
    while IFS= read -r model; do
        test_info "  - $model"
    done <<< "$models"
    
    # Check for recommended models
    if echo "$models" | grep -q "qwen2.5-coder"; then
        test_pass "Recommended model found: qwen2.5-coder"
    else
        test_info "Consider installing: ollama pull qwen2.5-coder:7b"
    fi
}

test_vscode_installation() {
    test_start "VSCode Installation"
    
    if command -v code &> /dev/null; then
        test_pass "VSCode is installed"
        local version=$(code --version 2>/dev/null | head -1 || echo "unknown")
        test_info "VSCode version: $version"
        return 0
    else
        test_fail "VSCode is not installed"
        test_info "Install from: https://code.visualstudio.com/"
        return 1
    fi
}

test_vscode_extensions() {
    test_start "VSCode Extensions Check"
    
    if ! command -v code &> /dev/null; then
        test_fail "VSCode not available, skipping extension check"
        return 1
    fi
    
    local required_extensions=(
        "continue.continue"
        "saoudrizwan.claude-dev"
    )
    
    local installed_extensions=$(code --list-extensions 2>/dev/null || echo "")
    
    for ext in "${required_extensions[@]}"; do
        if echo "$installed_extensions" | grep -q "^${ext}$"; then
            test_pass "Extension installed: $ext"
        else
            test_fail "Extension missing: $ext"
            test_info "Install with: code --install-extension $ext"
        fi
    done
}

test_continue_config() {
    test_start "Continue Configuration"
    
    local config_file="${HOME}/.continue/config.json"
    
    if [ -f "$config_file" ]; then
        test_pass "Continue config exists"
        
        if jq empty "$config_file" 2>/dev/null; then
            test_pass "Continue config is valid JSON"
            
            # Check for models
            local models=$(jq -r '.models[]?.model // empty' "$config_file" 2>/dev/null)
            if [ -n "$models" ]; then
                test_pass "Models configured in Continue"
                while IFS= read -r model; do
                    test_info "  - $model"
                done <<< "$models"
            else
                test_fail "No models configured in Continue"
            fi
        else
            test_fail "Continue config is invalid JSON"
            jq empty "$config_file" 2>&1 | tee -a "$REPORT_FILE"
        fi
    else
        test_fail "Continue config not found"
        test_info "Generate with: ./scripts/generate-continue-config.sh"
    fi
}

test_memory_system() {
    test_start "Memory System Setup"
    
    local memory_dir="${HOME}/.ai-coding-stack/memory"
    
    if [ -d "$memory_dir" ]; then
        test_pass "Memory directory exists"
        
        local file_count=$(find "$memory_dir" -type f | wc -l)
        test_info "Memory files: $file_count"
        
        if [ "$file_count" -gt 0 ]; then
            test_pass "Memory system has data"
        else
            test_info "No memory data yet (this is normal for new installations)"
        fi
    else
        test_info "Memory directory not created yet (will be created on first use)"
    fi
}

################################################################################
# Integration Tests
################################################################################

test_model_inference() {
    test_start "Model Inference Test"
    
    if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
        test_fail "Ollama service not running, skipping inference test"
        return 1
    fi
    
    local model=$(curl -s http://localhost:11434/api/tags | jq -r '.models[0].name' 2>/dev/null)
    
    if [ -z "$model" ]; then
        test_fail "No models available for inference test"
        return 1
    fi
    
    test_info "Testing inference with model: $model"
    
    local response=$(curl -s http://localhost:11434/api/generate -d '{
        "model": "'"$model"'",
        "prompt": "def hello():",
        "stream": false
    }' 2>/dev/null | jq -r '.response' 2>/dev/null)
    
    if [ -n "$response" ] && [ "$response" != "null" ]; then
        test_pass "Model inference successful"
        test_info "Response preview: ${response:0:100}..."
    else
        test_fail "Model inference failed"
        return 1
    fi
}

test_memory_import() {
    test_start "Memory Import Test"
    
    # Create test JSON
    local test_file="/tmp/test-memory.json"
    cat > "$test_file" << 'EOF'
{
    "coding_patterns": [
        {
            "pattern_type": "naming_convention",
            "pattern": "Use camelCase for variables",
            "confidence": "high"
        }
    ],
    "preferences": {
        "languages": ["TypeScript", "Python"]
    }
}
EOF
    
    if [ -f "../scripts/memory-manager.sh" ]; then
        if ../scripts/memory-manager.sh import-json "$test_file" &>> "$REPORT_FILE"; then
            test_pass "Memory import successful"
        else
            test_fail "Memory import failed"
            return 1
        fi
    else
        test_fail "memory-manager.sh not found"
        return 1
    fi
    
    rm -f "$test_file"
}

test_config_generation() {
    test_start "Config Generation Test"
    
    if [ -f "../scripts/generate-continue-config.sh" ]; then
        # Backup existing config
        if [ -f "${HOME}/.continue/config.json" ]; then
            cp "${HOME}/.continue/config.json" "${HOME}/.continue/config.json.test-backup"
        fi
        
        if ../scripts/generate-continue-config.sh &>> "$REPORT_FILE"; then
            test_pass "Config generation successful"
            
            # Verify generated config
            if [ -f "${HOME}/.continue/config.json" ]; then
                if jq empty "${HOME}/.continue/config.json" 2>/dev/null; then
                    test_pass "Generated config is valid JSON"
                else
                    test_fail "Generated config is invalid JSON"
                fi
            fi
        else
            test_fail "Config generation failed"
            return 1
        fi
        
        # Restore backup
        if [ -f "${HOME}/.continue/config.json.test-backup" ]; then
            mv "${HOME}/.continue/config.json.test-backup" "${HOME}/.continue/config.json"
        fi
    else
        test_fail "generate-continue-config.sh not found"
        return 1
    fi
}

################################################################################
# Performance Tests
################################################################################

test_script_performance() {
    test_start "Script Performance Test"
    
    # Test memory-manager.sh help
    local start_time=$(date +%s%N)
    ../scripts/memory-manager.sh &> /dev/null || true
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    if [ "$duration" -lt 1000 ]; then
        test_pass "memory-manager.sh responds quickly (${duration}ms)"
    else
        test_fail "memory-manager.sh is slow (${duration}ms)"
    fi
}

################################################################################
# Security Tests
################################################################################

test_file_security() {
    test_start "File Security Check"
    
    # Check for world-writable files
    local writable_files=$(find .. -type f -perm -002 2>/dev/null | grep -v ".git" || true)
    
    if [ -z "$writable_files" ]; then
        test_pass "No world-writable files found"
    else
        test_fail "Found world-writable files:"
        echo "$writable_files" | tee -a "$REPORT_FILE"
    fi
    
    # Check for sensitive data in scripts
    local sensitive_patterns=("password" "api_key" "secret" "token")
    local found_sensitive=false
    
    for pattern in "${sensitive_patterns[@]}"; do
        if grep -ri "$pattern" ../scripts/*.sh 2>/dev/null | grep -v "# " | grep -v "test" &> /dev/null; then
            test_fail "Found potential sensitive data pattern: $pattern"
            found_sensitive=true
        fi
    done
    
    if [ "$found_sensitive" = false ]; then
        test_pass "No hardcoded sensitive data found"
    fi
}

################################################################################
# Documentation Tests
################################################################################

test_documentation() {
    test_start "Documentation Completeness"
    
    local required_docs=(
        "../README.md"
        "../QUICKSTART.md"
        "../CONTRIBUTING.md"
        "../LICENSE"
    )
    
    for doc in "${required_docs[@]}"; do
        if [ -f "$doc" ]; then
            test_pass "Documentation exists: $(basename "$doc")"
            
            # Check if not empty
            if [ -s "$doc" ]; then
                local lines=$(wc -l < "$doc")
                test_info "  Lines: $lines"
            else
                test_fail "Documentation is empty: $(basename "$doc")"
            fi
        else
            test_fail "Missing documentation: $(basename "$doc")"
        fi
    done
}

################################################################################
# Main Test Runner
################################################################################

run_all_tests() {
    echo "=================================="
    echo "Installation Test Suite"
    echo "=================================="
    echo ""
    echo "Report will be saved to: $REPORT_FILE"
    echo ""
    
    # Pre-installation tests
    echo "=== Pre-Installation Tests ==="
    test_system_requirements || true
    test_script_syntax || true
    test_json_validity || true
    test_file_permissions || true
    echo ""
    
    # Installation tests
    echo "=== Installation Tests ==="
    test_ollama_installation || true
    test_ollama_service || true
    test_ollama_models || true
    test_vscode_installation || true
    test_vscode_extensions || true
    test_continue_config || true
    test_memory_system || true
    echo ""
    
    # Integration tests
    echo "=== Integration Tests ==="
    test_model_inference || true
    test_memory_import || true
    test_config_generation || true
    echo ""
    
    # Performance tests
    echo "=== Performance Tests ==="
    test_script_performance || true
    echo ""
    
    # Security tests
    echo "=== Security Tests ==="
    test_file_security || true
    echo ""
    
    # Documentation tests
    echo "=== Documentation Tests ==="
    test_documentation || true
    echo ""
    
    # Summary
    echo "=================================="
    echo "Test Summary"
    echo "=================================="
    echo "Total Tests: $TESTS_TOTAL"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    
    local pass_rate=$(( TESTS_PASSED * 100 / TESTS_TOTAL ))
    echo "Pass Rate: ${pass_rate}%"
    echo ""
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo "Report: $REPORT_FILE"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        echo "Report: $REPORT_FILE"
        return 1
    fi
}

# Run tests
cd "$(dirname "$0")"
run_all_tests

