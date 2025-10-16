# Contributing to Ultimate AI Coding Stack

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce**
- **Expected vs actual behavior**
- **System information** (OS, RAM, GPU, etc.)
- **Log files** (from `~/.ai-coding-stack/install.log`)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear use case**
- **Expected behavior**
- **Why this enhancement would be useful**
- **Possible implementation approach**

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following our coding standards
3. **Test your changes** thoroughly
4. **Update documentation** if needed
5. **Write clear commit messages** using conventional commits format
6. **Submit a pull request** with a clear description

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/ultimate-ai-coding-stack.git
cd ultimate-ai-coding-stack

# Create a branch
git checkout -b feature/my-new-feature

# Make changes and test
./install.sh  # Test installation
./scripts/memory-manager.sh --help  # Test scripts

# Commit changes
git add .
git commit -m "feat: add new feature"

# Push to your fork
git push origin feature/my-new-feature
```

## Coding Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Use meaningful variable names in UPPER_CASE for globals
- Add comments for complex logic
- Use functions for reusable code
- Include error messages with `log_error`

### JSON Files

- Follow the schema in `configs/memory-schema.json`
- Use 2-space indentation
- Validate with `jq` before committing

### Documentation

- Use Markdown for all documentation
- Include code examples where applicable
- Keep language clear and concise
- Update README.md if adding new features

## Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(memory): add support for importing from VS Code settings
fix(install): handle missing Ollama service gracefully
docs(readme): update installation instructions
```

## Testing

Before submitting a PR:

1. **Test installation on a clean system** (use a VM or container)
2. **Test all scripts** with various inputs
3. **Verify health checks** pass
4. **Check for shell script errors** with `shellcheck`
5. **Validate JSON files** with `jq`

## Project Structure

```
ultimate-ai-coding-stack/
├── install.sh              # Main installation script
├── scripts/                # Utility scripts
│   ├── memory-manager.sh   # Memory management
│   └── generate-continue-config.sh
├── configs/                # Configuration files
│   ├── memory-schema.json  # Memory data schema
│   └── memory-example.json # Example data
├── templates/              # Project templates
│   └── default-project/    # Default template
├── docs/                   # Documentation
└── .github/                # GitHub workflows
```

## Adding New Features

### Adding a New Memory Import Source

1. Add import function to `scripts/memory-manager.sh`
2. Update schema in `configs/memory-schema.json` if needed
3. Add example in `configs/memory-example.json`
4. Update documentation in README.md
5. Add tests

### Adding a New Model

1. Update model detection in `install.sh`
2. Add model to recommended list
3. Update documentation with benchmarks
4. Test on various hardware configurations

### Adding a New Script

1. Create script in `scripts/` directory
2. Add shebang and error handling
3. Include help/usage function
4. Make executable with `chmod +x`
5. Update README.md with usage

## Documentation

When adding features, update:

- **README.md** - Main documentation
- **docs/** - Detailed guides if needed
- **Code comments** - For complex logic
- **CHANGELOG.md** - Record changes

## Release Process

1. Update version in relevant files
2. Update CHANGELOG.md
3. Create a git tag: `git tag -a v1.0.0 -m "Release v1.0.0"`
4. Push tag: `git push origin v1.0.0`
5. Create GitHub release with notes

## Questions?

- Open an issue for questions
- Join discussions in GitHub Discussions
- Check existing documentation first

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Ultimate AI Coding Stack! 🚀

