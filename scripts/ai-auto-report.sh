#!/bin/bash

################################################################################
# AI Automated Reporting System
# Autonomous data collection, analysis, and reporting with self-healing
# Built for: Modular, secure, production-grade, markdown-obsessed workflows
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
REPORT_DIR="${HOME}/.ai-coding-stack/reports"
DATA_DIR="${HOME}/.ai-coding-stack/data"
ARCHIVE_DIR="${HOME}/.ai-coding-stack/archives"
EVAL_DIR="${HOME}/.ai-coding-stack/evaluation"
LEARNING_DIR="${HOME}/.ai-coding-stack/learning"

# Create directories
mkdir -p "$REPORT_DIR" "$DATA_DIR" "$ARCHIVE_DIR"

# Logging
LOG_FILE="${DATA_DIR}/auto-report.log"

################################################################################
# Logging Functions
################################################################################

log() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${GREEN}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_info() {
    local msg="[INFO] $1"
    echo -e "${BLUE}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_warn() {
    local msg="[WARN] $1"
    echo -e "${YELLOW}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] $1"
    echo -e "${RED}$msg${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    log "STEP: $1"
}

################################################################################
# Self-Healing & Health Checks
################################################################################

health_check() {
    log_step "System Health Check"
    
    local issues=0
    
    # Check Ollama
    if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
        log_warn "Ollama not running - attempting to start"
        if command -v ollama &> /dev/null; then
            ollama serve &> /dev/null &
            sleep 5
            if curl -s http://localhost:11434/api/tags &> /dev/null; then
                log "✓ Ollama started successfully"
            else
                log_error "Failed to start Ollama"
                issues=$((issues + 1))
            fi
        else
            log_error "Ollama not installed"
            issues=$((issues + 1))
        fi
    else
        log "✓ Ollama running"
    fi
    
    # Check disk space
    local disk_usage=$(df -h ~/.ai-coding-stack | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        log_warn "Disk usage high: ${disk_usage}%"
        cleanup_old_data
    else
        log "✓ Disk space OK: ${disk_usage}%"
    fi
    
    # Check memory
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    if [ "$mem_usage" -gt 90 ]; then
        log_warn "Memory usage high: ${mem_usage}%"
    else
        log "✓ Memory OK: ${mem_usage}%"
    fi
    
    # Check required directories
    for dir in "$EVAL_DIR" "$LEARNING_DIR" "$REPORT_DIR" "$DATA_DIR"; do
        if [ ! -d "$dir" ]; then
            log_warn "Creating missing directory: $dir"
            mkdir -p "$dir"
        fi
    done
    
    log "Health check complete: $issues issues"
    return $issues
}

cleanup_old_data() {
    log "Cleaning up old data..."
    
    # Archive old reports (>30 days)
    find "$REPORT_DIR" -name "*.md" -mtime +30 -exec mv {} "$ARCHIVE_DIR/" \;
    
    # Compress archives
    cd "$ARCHIVE_DIR"
    find . -name "*.md" -exec gzip {} \;
    
    log "✓ Cleanup complete"
}

################################################################################
# Data Collection
################################################################################

collect_evaluation_data() {
    log_step "Collecting Evaluation Data"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local data_file="${DATA_DIR}/eval_${timestamp}.json"
    
    # Run evaluation if not recent
    local last_eval=$(find "$EVAL_DIR/history" -name "evaluation_*.json" -mtime -1 | head -1)
    
    if [ -z "$last_eval" ]; then
        log "Running fresh evaluation..."
        if [ -f "$(dirname $0)/ai-evaluation.sh" ]; then
            "$(dirname $0)/ai-evaluation.sh" full &>> "$LOG_FILE"
        else
            log_warn "Evaluation script not found"
            return 1
        fi
    else
        log "Using recent evaluation: $(basename $last_eval)"
    fi
    
    # Collect latest metrics
    local latest_eval=$(ls -t "$EVAL_DIR/history"/evaluation_*.json 2>/dev/null | head -1)
    
    if [ -n "$latest_eval" ]; then
        cp "$latest_eval" "$data_file"
        log "✓ Evaluation data collected"
    else
        log_error "No evaluation data found"
        return 1
    fi
}

collect_learning_data() {
    log_step "Collecting Learning Data"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local data_file="${DATA_DIR}/learning_${timestamp}.json"
    
    # Aggregate learning statistics
    cat > "$data_file" << EOF
{
  "timestamp": "$timestamp",
  "date": "$(date -Iseconds)",
  "knowledge_base": {
    "total_sources": $(find "$LEARNING_DIR/knowledge-base" -name "*.json" 2>/dev/null | wc -l),
    "pattern_files": $(find "$LEARNING_DIR/patterns" -name "*-patterns.json" 2>/dev/null | wc -l),
    "training_examples": $(find "$LEARNING_DIR/training-data" -name "*.jsonl" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
  },
  "models": {
    "installed": $(ollama list 2>/dev/null | tail -n +2 | wc -l),
    "custom": $(ollama list 2>/dev/null | grep -c "custom" || echo 0)
  }
}
EOF
    
    log "✓ Learning data collected"
}

collect_compliance_data() {
    log_step "Collecting Compliance Data"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local data_file="${DATA_DIR}/compliance_${timestamp}.json"
    
    # Aggregate compliance logs
    local compliance_dir="${HOME}/.ai-coding-stack/compliance"
    
    if [ -d "$compliance_dir" ]; then
        local total_sessions=$(find "$compliance_dir/sessions" -name "*.jsonl" 2>/dev/null | wc -l)
        local total_requests=$(find "$compliance_dir/sessions" -name "*.jsonl" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
        
        cat > "$data_file" << EOF
{
  "timestamp": "$timestamp",
  "date": "$(date -Iseconds)",
  "total_sessions": $total_sessions,
  "total_requests": $total_requests,
  "last_session": "$(ls -t $compliance_dir/sessions/*.jsonl 2>/dev/null | head -1 | xargs basename)"
}
EOF
        log "✓ Compliance data collected"
    else
        log_warn "No compliance data found"
    fi
}

collect_project_data() {
    log_step "Collecting Project Data"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local data_file="${DATA_DIR}/projects_${timestamp}.json"
    
    # Scan common project directories
    local project_dirs=("$HOME/projects" "$HOME/work" "$HOME/dev" "$HOME/code")
    local total_projects=0
    local total_commits=0
    local languages=()
    
    for dir in "${project_dirs[@]}"; do
        if [ -d "$dir" ]; then
            # Count git repositories
            local repos=$(find "$dir" -name ".git" -type d 2>/dev/null | wc -l)
            total_projects=$((total_projects + repos))
            
            # Count commits
            find "$dir" -name ".git" -type d 2>/dev/null | while read git_dir; do
                cd "$(dirname $git_dir)"
                local commits=$(git log --oneline 2>/dev/null | wc -l)
                total_commits=$((total_commits + commits))
            done
        fi
    done
    
    cat > "$data_file" << EOF
{
  "timestamp": "$timestamp",
  "date": "$(date -Iseconds)",
  "total_projects": $total_projects,
  "total_commits": $total_commits,
  "scanned_directories": [$(printf '"%s",' "${project_dirs[@]}" | sed 's/,$//')]
}
EOF
    
    log "✓ Project data collected"
}

################################################################################
# Data Analysis
################################################################################

analyze_trends() {
    log_step "Analyzing Trends"
    
    local analysis_file="${DATA_DIR}/trends_$(date +%Y%m%d).json"
    
    # Get all evaluation history
    local eval_files=($(ls -t "$EVAL_DIR/history"/evaluation_*.json 2>/dev/null))
    
    if [ ${#eval_files[@]} -lt 2 ]; then
        log_warn "Not enough data for trend analysis (need at least 2 evaluations)"
        return 0
    fi
    
    # Calculate trends
    python3 << 'PYTHON'
import json
import sys
from pathlib import Path
from datetime import datetime

eval_dir = Path.home() / ".ai-coding-stack/evaluation/history"
data_dir = Path.home() / ".ai-coding-stack/data"

eval_files = sorted(eval_dir.glob("evaluation_*.json"), key=lambda x: x.stat().st_mtime)

if len(eval_files) < 2:
    sys.exit(0)

# Load all evaluations
evaluations = []
for f in eval_files:
    with open(f) as file:
        evaluations.append(json.load(file))

# Calculate trends
first = evaluations[0]
latest = evaluations[-1]

trends = {
    "timestamp": datetime.now().isoformat(),
    "total_evaluations": len(evaluations),
    "first_evaluation": first["date"],
    "latest_evaluation": latest["date"],
    "improvements": {
        "code_quality": latest["metrics"]["code_quality"] - first["metrics"]["code_quality"],
        "context_understanding": latest["metrics"]["context_understanding"] - first["metrics"]["context_understanding"],
        "overall_score": latest["metrics"]["overall_score"] - first["metrics"]["overall_score"]
    },
    "current_scores": {
        "code_quality": latest["metrics"]["code_quality"],
        "context_understanding": latest["metrics"]["context_understanding"],
        "overall_score": latest["metrics"]["overall_score"]
    },
    "trend": "improving" if latest["metrics"]["overall_score"] > first["metrics"]["overall_score"] else "declining"
}

# Calculate velocity (improvement per evaluation)
if len(evaluations) > 1:
    total_improvement = latest["metrics"]["overall_score"] - first["metrics"]["overall_score"]
    trends["velocity"] = round(total_improvement / len(evaluations), 2)

# Save trends
output_file = data_dir / f"trends_{datetime.now().strftime('%Y%m%d')}.json"
with open(output_file, 'w') as f:
    json.dump(trends, f, indent=2)

print(f"Trends analyzed: {len(evaluations)} evaluations")
print(f"Overall improvement: {trends['improvements']['overall_score']} points")
print(f"Velocity: {trends.get('velocity', 0)} points per evaluation")
PYTHON
    
    log "✓ Trend analysis complete"
}

calculate_roi() {
    log_step "Calculating ROI"
    
    # Calculate time saved, code quality improvement, etc.
    local roi_file="${DATA_DIR}/roi_$(date +%Y%m%d).json"
    
    python3 << 'PYTHON'
import json
from pathlib import Path
from datetime import datetime

data_dir = Path.home() / ".ai-coding-stack/data"
eval_dir = Path.home() / ".ai-coding-stack/evaluation/history"

# Get latest evaluation
eval_files = sorted(eval_dir.glob("evaluation_*.json"), key=lambda x: x.stat().st_mtime)

if not eval_files:
    print("No evaluation data")
    exit(0)

with open(eval_files[-1]) as f:
    latest = json.load(f)

# Calculate ROI metrics
code_quality = latest["metrics"]["code_quality"]
context_score = latest["metrics"]["context_understanding"]

# Estimate time savings (based on code quality and context understanding)
# Higher scores = less debugging, less refactoring, faster development
time_saved_per_day = (code_quality / 100) * 2 + (context_score / 100) * 1  # hours

# Estimate cost savings (assuming $100/hour developer rate)
cost_saved_per_day = time_saved_per_day * 100

roi = {
    "timestamp": datetime.now().isoformat(),
    "metrics": {
        "code_quality_score": code_quality,
        "context_understanding_score": context_score,
        "overall_score": latest["metrics"]["overall_score"]
    },
    "estimated_savings": {
        "time_saved_hours_per_day": round(time_saved_per_day, 2),
        "cost_saved_usd_per_day": round(cost_saved_per_day, 2),
        "cost_saved_usd_per_month": round(cost_saved_per_day * 20, 2),
        "cost_saved_usd_per_year": round(cost_saved_per_day * 250, 2)
    },
    "productivity_multiplier": round(1 + (time_saved_per_day / 8), 2)
}

output_file = data_dir / f"roi_{datetime.now().strftime('%Y%m%d')}.json"
with open(output_file, 'w') as f:
    json.dump(roi, f, indent=2)

print(f"ROI calculated:")
print(f"  Time saved: {roi['estimated_savings']['time_saved_hours_per_day']} hours/day")
print(f"  Cost saved: ${roi['estimated_savings']['cost_saved_usd_per_month']}/month")
print(f"  Productivity: {roi['productivity_multiplier']}x")
PYTHON
    
    log "✓ ROI calculated"
}

################################################################################
# Report Generation
################################################################################

generate_daily_report() {
    log_step "Generating Daily Report"
    
    local report_date=$(date +%Y-%m-%d)
    local report_file="${REPORT_DIR}/daily_${report_date}.md"
    
    # Load latest data
    local latest_eval=$(ls -t "$DATA_DIR"/eval_*.json 2>/dev/null | head -1)
    local latest_learning=$(ls -t "$DATA_DIR"/learning_*.json 2>/dev/null | head -1)
    local latest_trends=$(ls -t "$DATA_DIR"/trends_*.json 2>/dev/null | head -1)
    local latest_roi=$(ls -t "$DATA_DIR"/roi_*.json 2>/dev/null | head -1)
    
    # Generate report
    cat > "$report_file" << 'REPORTHEADER'
# AI Coding Stack - Daily Report

**Report Date:** $(date)  
**System:** Ultimate AI Coding Stack v6.0

---

## Executive Summary

REPORTHEADER
    
    # Add evaluation summary
    if [ -n "$latest_eval" ]; then
        python3 << PYTHON >> "$report_file"
import json

with open("$latest_eval") as f:
    data = json.load(f)

print(f"""
### Current Performance

| Metric | Score | Grade |
|--------|-------|-------|
| **Code Quality** | {data['metrics']['code_quality']}/100 | {get_grade(data['metrics']['code_quality'])} |
| **Context Understanding** | {data['metrics']['context_understanding']}/100 | {get_grade(data['metrics']['context_understanding'])} |
| **Overall** | {data['metrics']['overall_score']}/100 | {get_grade(data['metrics']['overall_score'])} |

**Efficiency:**
- Response Time: {data['metrics']['efficiency']['avg_response_time_ms']}ms
- Tokens/Second: {data['metrics']['efficiency']['tokens_per_second']}
""")

def get_grade(score):
    if score >= 90: return "A+"
    elif score >= 85: return "A"
    elif score >= 80: return "B+"
    elif score >= 75: return "B"
    elif score >= 70: return "C+"
    elif score >= 65: return "C"
    elif score >= 60: return "D"
    else: return "F"
PYTHON
    fi
    
    # Add trends
    if [ -n "$latest_trends" ]; then
        cat >> "$report_file" << 'EOF'

---

## Improvement Trends

EOF
        python3 << PYTHON >> "$report_file"
import json

with open("$latest_trends") as f:
    data = json.load(f)

print(f"""
**Total Evaluations:** {data['total_evaluations']}  
**Trend:** {data['trend'].upper()}  
**Velocity:** {data.get('velocity', 0)} points per evaluation

### Improvements Since First Evaluation

| Metric | Improvement |
|--------|-------------|
| Code Quality | +{data['improvements']['code_quality']} points |
| Context Understanding | +{data['improvements']['context_understanding']} points |
| Overall Score | +{data['improvements']['overall_score']} points |
""")
PYTHON
    fi
    
    # Add ROI
    if [ -n "$latest_roi" ]; then
        cat >> "$report_file" << 'EOF'

---

## Return on Investment

EOF
        python3 << PYTHON >> "$report_file"
import json

with open("$latest_roi") as f:
    data = json.load(f)

print(f"""
### Estimated Savings

| Period | Time Saved | Cost Saved |
|--------|------------|------------|
| **Daily** | {data['estimated_savings']['time_saved_hours_per_day']} hours | \${data['estimated_savings']['cost_saved_usd_per_day']} |
| **Monthly** | {data['estimated_savings']['time_saved_hours_per_day'] * 20} hours | \${data['estimated_savings']['cost_saved_usd_per_month']} |
| **Yearly** | {data['estimated_savings']['time_saved_hours_per_day'] * 250} hours | \${data['estimated_savings']['cost_saved_usd_per_year']} |

**Productivity Multiplier:** {data['productivity_multiplier']}x
""")
PYTHON
    fi
    
    # Add learning stats
    if [ -n "$latest_learning" ]; then
        cat >> "$report_file" << 'EOF'

---

## Learning System Status

EOF
        python3 << PYTHON >> "$report_file"
import json

with open("$latest_learning") as f:
    data = json.load(f)

print(f"""
- **Knowledge Base Sources:** {data['knowledge_base']['total_sources']}
- **Pattern Files:** {data['knowledge_base']['pattern_files']}
- **Training Examples:** {data['knowledge_base']['training_examples']}
- **Installed Models:** {data['models']['installed']}
- **Custom Models:** {data['models']['custom']}
""")
PYTHON
    fi
    
    # Add recommendations
    cat >> "$report_file" << 'EOF'

---

## Recommendations

EOF
    
    # Generate context-aware recommendations
    if [ -n "$latest_eval" ]; then
        python3 << 'PYTHON' >> "$report_file"
import json
import sys

eval_file = sys.argv[1] if len(sys.argv) > 1 else None
if not eval_file:
    sys.exit(0)

with open(eval_file) as f:
    data = json.load(f)

quality = data['metrics']['code_quality']
context = data['metrics']['context_understanding']

print("### Action Items\n")

if quality < 75:
    print("- 🔴 **Code Quality Low:** Run `./scripts/ai-learning-system.sh learn-awesome` to learn from high-quality projects")

if context < 75:
    print("- 🔴 **Context Understanding Low:** Run `./scripts/ai-learning-system.sh learn-local ~/projects` to analyze your codebase")

if quality >= 75 and context >= 75:
    print("- ✅ **Performance Good:** Continue with current learning schedule")

if data['metrics']['overall_score'] >= 85:
    print("- 🎉 **Excellent Performance:** Consider fine-tuning custom model with `./scripts/ai-learning-system.sh finetune`")

print("\n### Next Steps\n")
print("1. Review detailed metrics above")
print("2. Execute recommended actions")
print("3. Re-evaluate in 7 days")
print("4. Track progress in next report")
PYTHON "$latest_eval"
    fi
    
    # Footer
    cat >> "$report_file" << 'EOF'

---

*Report generated automatically by AI Auto-Report System*  
*Next report: Tomorrow*
EOF
    
    log "✓ Daily report generated: $report_file"
    echo "$report_file"
}

generate_weekly_report() {
    log_step "Generating Weekly Report"
    
    local report_date=$(date +%Y-W%V)
    local report_file="${REPORT_DIR}/weekly_${report_date}.md"
    
    # Aggregate last 7 days of data
    # TODO: Implement weekly aggregation
    
    log "✓ Weekly report generated: $report_file"
}

generate_monthly_report() {
    log_step "Generating Monthly Report"
    
    local report_date=$(date +%Y-%m)
    local report_file="${REPORT_DIR}/monthly_${report_date}.md"
    
    # Aggregate monthly data
    # TODO: Implement monthly aggregation
    
    log "✓ Monthly report generated: $report_file"
}

################################################################################
# Notification & Distribution
################################################################################

send_notification() {
    local report_file="$1"
    
    log "Sending notification for: $(basename $report_file)"
    
    # Display summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    head -30 "$report_file"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_info "Full report: $report_file"
}

################################################################################
# Main Automation
################################################################################

run_full_automation() {
    log_step "Running Full Automation"
    
    # Health check
    health_check || log_warn "Health check found issues"
    
    # Data collection
    collect_evaluation_data
    collect_learning_data
    collect_compliance_data
    collect_project_data
    
    # Analysis
    analyze_trends
    calculate_roi
    
    # Report generation
    local report=$(generate_daily_report)
    
    # Notification
    send_notification "$report"
    
    log "✓ Full automation complete"
}

################################################################################
# CLI Interface
################################################################################

show_help() {
    cat << 'EOF'
AI Automated Reporting System

Usage: ai-auto-report.sh <command>

Commands:
  full              Run complete automation
  collect           Collect all data
  analyze           Analyze collected data
  report [type]     Generate report (daily/weekly/monthly)
  health            Run health check
  cleanup           Clean up old data
  
  schedule          Setup automated schedule
  status            Show automation status
  
  help              Show this help

Examples:
  # Run full automation
  ai-auto-report.sh full
  
  # Generate daily report
  ai-auto-report.sh report daily
  
  # Setup daily automation
  ai-auto-report.sh schedule

Reports saved to: $REPORT_DIR
Data saved to: $DATA_DIR
EOF
}

setup_schedule() {
    log_step "Setting Up Automation Schedule"
    
    local cron_script="${HOME}/.ai-coding-stack/daily-automation.sh"
    
    cat > "$cron_script" << 'CRONSCRIPT'
#!/bin/bash
# Daily automation script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/../ultimate-ai-coding-stack/scripts/ai-auto-report.sh" full
CRONSCRIPT
    
    chmod +x "$cron_script"
    
    # Add to crontab (daily at 6 AM)
    (crontab -l 2>/dev/null | grep -v "ai-auto-report"; echo "0 6 * * * $cron_script >> ${HOME}/.ai-coding-stack/automation.log 2>&1") | crontab -
    
    log "✓ Automation scheduled for daily 6 AM"
    log_info "View logs: tail -f ~/.ai-coding-stack/automation.log"
}

show_status() {
    log_step "Automation Status"
    
    # Check cron
    if crontab -l 2>/dev/null | grep -q "ai-auto-report"; then
        log "✓ Automation is scheduled"
        crontab -l | grep "ai-auto-report"
    else
        log_warn "Automation not scheduled"
    fi
    
    # Show recent reports
    echo ""
    log "Recent Reports:"
    ls -lht "$REPORT_DIR"/*.md 2>/dev/null | head -5
    
    # Show data collection status
    echo ""
    log "Data Collection Status:"
    echo "  Evaluations: $(find $DATA_DIR -name "eval_*.json" | wc -l)"
    echo "  Learning: $(find $DATA_DIR -name "learning_*.json" | wc -l)"
    echo "  Trends: $(find $DATA_DIR -name "trends_*.json" | wc -l)"
    echo "  ROI: $(find $DATA_DIR -name "roi_*.json" | wc -l)"
}

################################################################################
# Main
################################################################################

main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        full)
            run_full_automation
            ;;
        collect)
            collect_evaluation_data
            collect_learning_data
            collect_compliance_data
            collect_project_data
            ;;
        analyze)
            analyze_trends
            calculate_roi
            ;;
        report)
            local type="${1:-daily}"
            case "$type" in
                daily) generate_daily_report ;;
                weekly) generate_weekly_report ;;
                monthly) generate_monthly_report ;;
                *) log_error "Unknown report type: $type" ;;
            esac
            ;;
        health)
            health_check
            ;;
        cleanup)
            cleanup_old_data
            ;;
        schedule)
            setup_schedule
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use 'ai-auto-report.sh help' for usage"
            exit 1
            ;;
    esac
}

main "$@"

