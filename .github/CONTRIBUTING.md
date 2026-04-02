# Contributing to Skill Writer

Thank you for your interest in contributing to Skill Writer! This document provides guidelines and instructions for contributing.

## Ways to Contribute

### 1. Submit a New Skill
Help expand our skill library by submitting new skills.

**Requirements:**
- Follow the skill template format
- Include at least 2 usage examples
- Provide bilingual documentation (Chinese/English)
- Pass all quality checks (LEAN ≥ 350, Full ≥ 700, No P0 issues)

**Process:**
1. Create a new issue using the [Skill Submission template](../ISSUE_TEMPLATE/skill_submission.md)
2. Fill in all required information
3. Attach your skill file
4. Wait for review and feedback

### 2. Report Bugs
Help us improve by reporting bugs you encounter.

**Process:**
1. Check if the bug has already been reported
2. Create a new issue using the [Bug Report template](../ISSUE_TEMPLATE/bug_report.md)
3. Provide detailed reproduction steps
4. Include environment information

### 3. Suggest Features
Have an idea for improvement? We'd love to hear it!

**Process:**
1. Create a new issue using the [Feature Request template](../ISSUE_TEMPLATE/feature_request.md)
2. Describe the problem and proposed solution
3. Discuss with maintainers and community

### 4. Improve Documentation
Help us improve our documentation.

**Areas to contribute:**
- Fix typos and grammar
- Add examples and tutorials
- Translate documentation
- Improve clarity and completeness

## Development Setup

### Prerequisites
- Git
- Node.js (v18+)
- npm or yarn

### Setup Steps

```bash
# Clone the repository
git clone https://github.com/your-org/skill-writer.git
cd skill-writer

# Install dependencies
npm install

# Run tests
npm test

# Start development server
npm run dev
```

## Skill Development Guide

### Skill Structure

```yaml
name: skill-name
description: Brief description
version: 1.0.0
author: Your Name

parameters:
  - name: param1
    type: string
    required: true
    description: Parameter description

examples:
  - input: example input
    output: expected output
```

### Best Practices

1. **Naming**: Use descriptive, lowercase names with hyphens
2. **Documentation**: Include clear descriptions for all parameters
3. **Examples**: Provide at least 2 practical examples
4. **Error Handling**: Handle edge cases gracefully
5. **Testing**: Write tests for your skill

### Quality Standards

| Metric | Minimum | Target |
|--------|---------|--------|
| LEAN Score | 350 | 500+ |
| Full Score | 700 | 850+ |
| P0 Issues | 0 | 0 |
| Examples | 2 | 3+ |

## Pull Request Process

1. **Fork the Repository**
   ```bash
   git clone https://github.com/your-username/skill-writer.git
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Follow the coding standards
   - Add tests if applicable
   - Update documentation

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add new skill for X"
   ```

5. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Use a clear title
   - Reference related issues
   - Describe your changes
   - Request review from maintainers

### PR Checklist

- [ ] Code follows project style guidelines
- [ ] Tests pass locally
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] No merge conflicts

## Code Review Process

All submissions require review before being merged:

1. Automated checks must pass
2. At least one maintainer approval required
3. Address all review comments
4. Squash commits if requested

## Getting Help

- Check our [FAQ](https://github.com/your-org/skill-writer/wiki/FAQ)
- Join our [Discord community](https://discord.gg/skill-writer)
- Open a [Discussion](https://github.com/your-org/skill-writer/discussions)

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](../LICENSE).

## Recognition

Contributors will be recognized in our:
- README.md contributors section
- Release notes
- Hall of Fame page

Thank you for contributing to Skill Writer!
