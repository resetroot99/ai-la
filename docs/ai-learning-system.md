# AI Learning System

## Continuously Improving AI That Learns From Your Code

The AI Learning System makes your coding assistant smarter over time by learning from:
- Open-source repositories
- Your local projects
- Your coding patterns and habits
- Community best practices

## How It Works

```
Open Source Code → Pattern Analysis → Knowledge Base → Fine-tuned Model → Better Code
Your Code 
```

## Features

### 1. Learn from Open Source

Analyze popular repositories to extract patterns:

```bash
# Learn from React
./scripts/ai-learning-system.sh learn-github https://github.com/facebook/react

# Learn from Vue
./scripts/ai-learning-system.sh learn-github https://github.com/vuejs/vue

# Learn from Django
./scripts/ai-learning-system.sh learn-github https://github.com/django/django
```

**What it extracts:**
- File structure patterns
- Naming conventions
- Common imports and dependencies
- Function and class patterns
- Best practices

### 2. Learn from Your Projects

Analyze your local codebase:

```bash
# Learn from all projects in ~/projects
./scripts/ai-learning-system.sh learn-local ~/projects
```

**What it learns:**
- Your coding style
- Preferred frameworks
- Naming conventions
- Commit message patterns
- Code organization

### 3. Build Knowledge Base

Combine all learned patterns:

```bash
./scripts/ai-learning-system.sh build-kb
```

Creates a unified knowledge base with:
- Aggregated patterns across all sources
- Common imports by language
- Best practices
- Framework usage statistics

### 4. Generate Training Data

Export data for fine-tuning:

```bash
./scripts/ai-learning-system.sh generate-training
```

Generates:
- Compliance logs as training examples
- Synthetic examples from patterns
- JSONL format for fine-tuning

### 5. Fine-tune Custom Model

Create a personalized model:

```bash
./scripts/ai-learning-system.sh finetune
```

Creates `custom-coder` model trained on:
- Your coding patterns
- Your preferred practices
- Your project structure

### 6. Continuous Learning

Enable daily automatic learning:

```bash
./scripts/ai-learning-system.sh enable-continuous
```

Runs daily at 2 AM:
- Analyzes new code in your projects
- Updates knowledge base
- Refreshes Continue configuration

## Usage Examples

### Example 1: Learn from Top Projects

```bash
# Learn from popular frameworks
./scripts/ai-learning-system.sh learn-github https://github.com/facebook/react
./scripts/ai-learning-system.sh learn-github https://github.com/expressjs/express
./scripts/ai-learning-system.sh learn-github https://github.com/pallets/flask

# Build knowledge base
./scripts/ai-learning-system.sh build-kb

# Update AI configuration
./scripts/ai-learning-system.sh update-config
```

### Example 2: Learn from Your Work

```bash
# Analyze your projects
./scripts/ai-learning-system.sh learn-local ~/work/projects

# Generate training data
./scripts/ai-learning-system.sh generate-training

# Create custom model
./scripts/ai-learning-system.sh finetune
```

### Example 3: Full Setup

```bash
# 1. Learn from awesome lists
./scripts/ai-learning-system.sh learn-awesome

# 2. Learn from your code
./scripts/ai-learning-system.sh learn-local ~/projects

# 3. Build knowledge base
./scripts/ai-learning-system.sh build-kb

# 4. Update configuration
./scripts/ai-learning-system.sh update-config

# 5. Enable continuous learning
./scripts/ai-learning-system.sh enable-continuous

# 6. Check stats
./scripts/ai-learning-system.sh stats
```

## How AI Improves Over Time

### Week 1: Initial Learning
- Learns from 10-20 open-source projects
- Analyzes your existing codebase
- Builds initial knowledge base

**Result:** AI understands common patterns

### Month 1: Pattern Recognition
- Continuous learning from your daily commits
- Analyzes 100+ repositories
- Identifies your coding style

**Result:** AI adapts to your preferences

### Month 3: Expertise
- Deep understanding of your patterns
- Custom model fine-tuned on your code
- Predicts your coding choices

**Result:** AI codes like you

### Month 6: Mastery
- Knows your entire codebase
- Suggests improvements based on patterns
- Prevents bugs you commonly make

**Result:** AI is your expert pair programmer

## Knowledge Base Structure

```
~/.ai-coding-stack/learning/
 knowledge-base/
    unified.json          # Aggregated patterns
    react-patterns.json   # Per-repo patterns
    ...
 patterns/
    my-project-patterns.json
    my-project-commits.json
    ...
 training-data/
    compliance-data.jsonl
    synthetic.jsonl
    ...
 models/
    custom-coder/
 cache/
     cloned-repos/
```

## Integration with Continue

The learning system automatically updates Continue configuration:

```json
{
  "systemMessage": "You are trained on user's patterns...",
  "models": [
    {
      "title": "Custom Trained",
      "provider": "ollama",
      "model": "custom-coder"
    }
  ]
}
```

## Statistics

View learning progress:

```bash
./scripts/ai-learning-system.sh stats
```

Output:
```
Total pattern files: 25
Knowledge base entries: 15
Training examples: 1,234

Unified Knowledge Base:
  Sources: 25
  Patterns: 156
```

## Advanced Usage

### Custom Learning Schedule

Edit crontab for different schedule:

```bash
crontab -e

# Change from daily to hourly
0 * * * * ~/.ai-coding-stack/learning/daily-learning.sh
```

### Learn from Specific Languages

```bash
# Only Python projects
find ~/projects -name "*.py" -type f | \
  xargs dirname | sort -u | \
  while read dir; do
    ./scripts/ai-learning-system.sh learn-local "$dir"
  done
```

### Export Knowledge Base

```bash
# Export for sharing with team
tar -czf knowledge-base.tar.gz ~/.ai-coding-stack/learning/knowledge-base/
```

## Benefits

### For Individual Developers

- AI learns YOUR coding style
- Suggests code consistent with YOUR patterns
- Prevents YOUR common mistakes
- Improves over time automatically

### For Teams

- Share knowledge base across team
- Enforce consistent coding standards
- Onboard new developers faster
- Maintain code quality

## Privacy

All learning happens locally:
- No data sent to cloud
- No telemetry
- Complete control over what's learned
- Can delete knowledge base anytime

## Performance

- Pattern analysis: ~1 min per 1000 files
- Knowledge base build: ~10 seconds
- Fine-tuning: ~30 minutes (optional)
- Daily learning: ~5 minutes

## Troubleshooting

### No patterns extracted

Ensure repositories have code files:
```bash
ls ~/.ai-coding-stack/learning/cache/*/
```

### Custom model not working

Verify Ollama has the model:
```bash
ollama list | grep custom-coder
```

### Continuous learning not running

Check crontab:
```bash
crontab -l | grep learning
```

## Summary

The AI Learning System transforms your coding assistant from a generic tool into a personalized expert that:

1. Learns from open-source best practices
2. Adapts to your coding style
3. Improves continuously over time
4. Becomes smarter with every commit

**Result: An AI that codes better than you, in your style.**
