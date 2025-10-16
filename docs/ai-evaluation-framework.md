# AI Evaluation Framework

## Measuring AI Improvement Over Time

A comprehensive framework to evaluate and track your AI's improvement in code quality, efficiency, and context understanding.

## Quick Start

```bash
# Run complete evaluation
./scripts/ai-evaluation.sh full

# View progress
./scripts/ai-evaluation.sh progress

# Generate report
./scripts/ai-evaluation.sh report
```

## Evaluation Metrics

### 1. Code Quality (0-100)

Measures the quality of AI-generated code:

**Criteria:**
- **Error Handling** (20 points) - try/catch, error checks
- **Documentation** (20 points) - Comments, docstrings
- **Type Hints** (20 points) - Type annotations
- **Validation** (20 points) - Input validation, assertions
- **Best Practices** (20 points) - Modern syntax, patterns

**Grade Scale:**
- A+ (90-100): Excellent code quality
- A (85-89): Very good
- B (75-84): Good
- C (65-74): Acceptable
- D (60-64): Needs improvement
- F (<60): Poor

### 2. Context Understanding (0-100)

Measures AI's ability to understand project context:

**Criteria:**
- References existing code correctly (30 points)
- Uses appropriate imports (20 points)
- Maintains consistency with codebase (30 points)
- Follows project patterns (20 points)

**Tests:**
- Multi-file context awareness
- Cross-reference between files
- Project structure understanding

### 3. Efficiency Metrics

Measures AI performance:

**Metrics:**
- **Response Time** - Average time to generate code (ms)
- **Tokens per Second** - Generation speed
- **Efficiency Rating:**
  - Excellent: 150+ tokens/sec
  - Good: 100-149 tokens/sec
  - Average: 50-99 tokens/sec
  - Needs Improvement: <50 tokens/sec

### 4. Benchmark Pass Rate (0-100%)

Standard test suite with 10 benchmarks:

1. Basic Function - Simple function implementation
2. Error Handling - Robust error management
3. API Endpoint - REST API creation
4. Database Query - SQL operations
5. Async Function - Asynchronous operations
6. Class Implementation - OOP patterns
7. Algorithm - Data structures & algorithms
8. Testing - Unit test creation
9. Documentation - Code documentation
10. Security - Secure coding practices

## Usage

### Run Full Evaluation

```bash
./scripts/ai-evaluation.sh full
```

Runs all tests and generates comprehensive report.

**Duration:** ~5-10 minutes

**Output:**
- Code quality score
- Context understanding score
- Efficiency metrics
- Benchmark results
- Overall grade
- Detailed report

### Individual Tests

```bash
# Code quality only
./scripts/ai-evaluation.sh quality

# Efficiency only
./scripts/ai-evaluation.sh efficiency

# Context understanding only
./scripts/ai-evaluation.sh context

# Benchmark suite only
./scripts/ai-evaluation.sh benchmark
```

### View Progress

```bash
./scripts/ai-evaluation.sh progress
```

Shows improvement over time:
```
📊 Improvement Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

First Evaluation:  65/100
Latest Evaluation: 82/100

Improvement: +17 points (+26%)

Total Evaluations: 5
```

### Generate Report

```bash
./scripts/ai-evaluation.sh report
```

Creates detailed markdown report with:
- Overall grade
- Metric breakdown
- Performance analysis
- Learning progress
- Recommendations

## Evaluation Schedule

### Recommended Schedule

**Initial Setup:**
```bash
# Day 1: Baseline
./scripts/ai-evaluation.sh full

# Enable learning
./scripts/ai-learning-system.sh enable-continuous
```

**Regular Evaluations:**
```bash
# Weekly (first month)
0 0 * * 0 ~/.ai-coding-stack/scripts/ai-evaluation.sh full

# Monthly (ongoing)
0 0 1 * * ~/.ai-coding-stack/scripts/ai-evaluation.sh full
```

### Expected Improvement Timeline

**Week 1: Baseline**
- Code Quality: 60-70/100
- Context: 50-60/100
- Overall: D-C grade

**Month 1: Initial Learning**
- Code Quality: 70-75/100
- Context: 65-70/100
- Overall: C-B grade
- +10-15 point improvement

**Month 3: Adaptation**
- Code Quality: 80-85/100
- Context: 75-80/100
- Overall: B-A grade
- +20-25 point improvement

**Month 6: Mastery**
- Code Quality: 85-95/100
- Context: 85-90/100
- Overall: A-A+ grade
- +25-35 point improvement

## Interpreting Results

### Code Quality Score

**90-100 (A+):** Production-ready code
- Comprehensive error handling
- Well-documented
- Type-safe
- Validated inputs
- Best practices

**75-89 (B):** Good code, minor improvements needed
- Basic error handling
- Some documentation
- Mostly follows best practices

**60-74 (C):** Functional but needs work
- Minimal error handling
- Limited documentation
- Some best practices missing

**<60 (F):** Needs significant improvement
- No error handling
- No documentation
- Poor practices

### Context Understanding Score

**85-100:** Excellent context awareness
- Perfectly integrates with existing code
- Maintains consistency
- Understands project architecture

**70-84:** Good context awareness
- Generally consistent
- Some integration issues

**<70:** Poor context awareness
- Doesn't reference existing code
- Inconsistent with project

### Benchmark Pass Rate

**90-100%:** Excellent
- Handles all common scenarios
- Production-ready

**75-89%:** Good
- Handles most scenarios
- Minor gaps

**<75%:** Needs improvement
- Missing key capabilities
- Requires more learning

## Continuous Improvement

### Improvement Loop

```
Evaluate → Identify Gaps → Learn → Re-evaluate
```

**1. Run Evaluation**
```bash
./scripts/ai-evaluation.sh full
```

**2. Review Report**
```bash
cat ~/.ai-coding-stack/evaluation/results/report_*.md
```

**3. Address Gaps**

If code quality is low:
```bash
# Learn from high-quality projects
./scripts/ai-learning-system.sh learn-github https://github.com/facebook/react
./scripts/ai-learning-system.sh learn-github https://github.com/django/django
```

If context understanding is low:
```bash
# Learn from your projects
./scripts/ai-learning-system.sh learn-local ~/projects
```

**4. Rebuild Knowledge Base**
```bash
./scripts/ai-learning-system.sh build-kb
./scripts/ai-learning-system.sh update-config
```

**5. Re-evaluate**
```bash
./scripts/ai-evaluation.sh full
```

### Optimization Tips

**To Improve Code Quality:**
- Learn from well-documented projects
- Analyze projects with comprehensive tests
- Study security-focused repositories

**To Improve Context Understanding:**
- Analyze more of your local projects
- Ensure Memory Bank is properly configured
- Use Cline with project context

**To Improve Efficiency:**
- Use quantized models (4-bit)
- Enable GPU acceleration
- Optimize prompt caching

## Results Storage

### Directory Structure

```
~/.ai-coding-stack/evaluation/
├── benchmarks/
│   └── standard_benchmark.json
├── results/
│   ├── code_quality_score.txt
│   ├── context_understanding_score.txt
│   ├── avg_response_time.txt
│   ├── tokens_per_second.txt
│   ├── benchmark_pass_rate.txt
│   └── report_YYYYMMDD_HHMMSS.md
└── history/
    ├── evaluation_20250101_120000.json
    ├── evaluation_20250108_120000.json
    └── ...
```

### History Format

```json
{
  "timestamp": "20250101_120000",
  "date": "2025-01-01T12:00:00Z",
  "metrics": {
    "code_quality": 75,
    "context_understanding": 70,
    "overall_score": 72,
    "efficiency": {
      "avg_response_time_ms": 2500,
      "tokens_per_second": 85
    }
  },
  "model": "qwen2.5-coder:32b",
  "knowledge_base_sources": 15
}
```

## Advanced Usage

### Custom Benchmarks

Create custom benchmark suite:

```bash
cat > ~/.ai-coding-stack/evaluation/benchmarks/custom.json << 'EOF'
{
  "version": "1.0",
  "tests": [
    {
      "name": "Your Test",
      "prompt": "Your prompt here",
      "expected_keywords": ["keyword1", "keyword2"]
    }
  ]
}
EOF
```

### Compare Evaluations

```bash
# Compare two specific evaluations
./scripts/ai-evaluation.sh compare \
  ~/.ai-coding-stack/evaluation/history/evaluation_20250101_120000.json \
  ~/.ai-coding-stack/evaluation/history/evaluation_20250201_120000.json
```

### Export Results

```bash
# Export all results
tar -czf evaluation-results.tar.gz ~/.ai-coding-stack/evaluation/

# Share with team
scp evaluation-results.tar.gz user@server:/path/
```

## Integration with Learning System

### Automated Improvement

```bash
# 1. Run evaluation
./scripts/ai-evaluation.sh full

# 2. If score < 80, trigger learning
if [ $(cat ~/.ai-coding-stack/evaluation/results/code_quality_score.txt) -lt 80 ]; then
    ./scripts/ai-learning-system.sh learn-awesome
    ./scripts/ai-learning-system.sh build-kb
fi

# 3. Re-evaluate
./scripts/ai-evaluation.sh full
```

### Continuous Monitoring

```bash
# Daily evaluation + learning
cat > ~/.ai-coding-stack/daily-improve.sh << 'EOF'
#!/bin/bash

# Evaluate
./scripts/ai-evaluation.sh full

# Learn
./scripts/ai-learning-system.sh learn-local ~/projects
./scripts/ai-learning-system.sh build-kb

# Update config
./scripts/ai-learning-system.sh update-config
EOF

chmod +x ~/.ai-coding-stack/daily-improve.sh

# Add to cron (daily at 3 AM)
(crontab -l; echo "0 3 * * * ~/.ai-coding-stack/daily-improve.sh") | crontab -
```

## Summary

The AI Evaluation Framework provides:

✅ **Objective Metrics** - Quantifiable improvement tracking  
✅ **Comprehensive Testing** - Code quality, context, efficiency  
✅ **Progress Tracking** - Historical comparison  
✅ **Actionable Insights** - Specific recommendations  
✅ **Automated Monitoring** - Continuous evaluation  

**Result: Data-driven AI improvement with measurable results.**
