# Contributing to Skill Writer

Thank you for your interest in contributing to Skill Writer! This document provides guidelines and instructions for contributing.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Project Structure](#project-structure)
5. [Adding New Features](#adding-new-features)
6. [Adding Platform Support](#adding-platform-support)
7. [Testing](#testing)
8. [Submitting Changes](#submitting-changes)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to:

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Respect different viewpoints and experiences

## Getting Started

### Prerequisites

- Node.js 16+ 
- npm or yarn
- Git

### Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/theneoai/skill-writer.git
   cd skill-writer
   ```

3. Install dependencies:
   ```bash
   cd builder
   npm install
   ```

4. Verify setup:
   ```bash
   npm run validate
   ```

## Development Workflow

### Branch Naming

- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `docs/description` - Documentation updates
- `platform/platform-name` - Platform-specific changes

### Making Changes

1. Create a new branch:
   ```bash
   git checkout -b feature/my-feature
   ```

2. Make your changes

3. Test your changes:
   ```bash
   npm run validate
   npm run build
   ```

4. Commit with clear messages:
   ```bash
   git commit -m "Add feature: description"
   ```

5. Push and create a Pull Request

## Project Structure

```
skill-writer/
├── skill-framework.md # Main skill definition
├── refs/              # Reference documentation (self-review, UTE, security, etc.)
├── templates/         # 4 skill templates + UTE snippet
├── eval/              # Evaluation rubrics and benchmarks
├── optimize/          # Optimization strategies and anti-patterns
├── builder/           # Builder tool
│   ├── src/
│   │   ├── commands/  # CLI commands
│   │   ├── core/      # Reader and embedder modules
│   │   └── platforms/ # Platform adapters
│   └── templates/     # Platform-specific output templates
├── examples/          # Certified example skills
└── platforms/         # Generated platform-specific files
```

## Adding New Features

### Adding a New Template

1. Create file in `templates/`:
   ```bash
   touch templates/my-template.md
   ```

2. Add template structure:
   ```markdown
   ---
   name: my-template
   description: Description of template
   ---
   
   # {{PROJECT_NAME}}
   
   ## Overview
   {{DESCRIPTION}}
   
   ## Usage
   {{USAGE}}
   ```

3. Document placeholders in template

4. Test with CREATE mode

5. Update documentation

### Adding a New Mode

1. Add mode-specific companion files under the appropriate directory (`refs/`, `eval/`, or `optimize/`).

2. Create companion `.md` files for the mode's data (no YAML config files needed since v2.1.0)

3. Update embedder to support new mode

4. Add tests

5. Update documentation

## Adding Platform Support

### Creating a Platform Adapter

1. Create adapter file:
   ```bash
   touch builder/src/platforms/myplatform.js
   ```

2. Implement required functions:
   ```javascript
   const name = 'myplatform';
   
   function formatSkill(skillContent) {
     // Transform content for platform
     return transformedContent;
   }
   
   function getInstallPath() {
     return '/path/to/skills';
   }
   
   function validateSkill(skillContent) {
     // Return validation result
     return { valid: true, errors: [], warnings: [] };
   }
   
   module.exports = {
     name,
     formatSkill,
     getInstallPath,
     validateSkill
   };
   ```

3. Register in `builder/src/platforms/index.js`

4. Create platform template in `builder/templates/`

5. Test build command

6. Update documentation

### Platform Configuration

Add platform config to embedder:

```javascript
myplatform: {
  placeholderPattern: /\{\{(\w+)\}\}/g,
  sectionPrefix: '##',
  codeBlockLang: 'yaml',
  supportsFrontmatter: true,
  triggerFormat: 'markdown',
}
```

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test -- test/builder.test.js

# Run with coverage
npm run test:coverage
```

### Writing Tests

Place tests in `builder/tests/`:

```javascript
describe('Feature', () => {
  test('should do something', () => {
    expect(result).toBe(expected);
  });
});
```

### Manual Testing

1. Build for your platform:
   ```bash
   npm run build:opencode
   ```

2. Install locally:
   ```bash
   npm run install:opencode
   ```

3. Test with AI assistant

## Submitting Changes

### Pull Request Process

1. **Before Submitting:**
   - Run all tests
   - Update documentation
   - Add changelog entry
   - Ensure code follows style guide

2. **PR Description Should Include:**
   - What changed and why
   - How to test the changes
   - Any breaking changes
   - Screenshots (if applicable)

3. **Review Process:**
   - Maintainers will review within 48 hours
   - Address feedback promptly
   - Keep discussion constructive

### Commit Message Format

```
type(scope): subject

body (optional)

footer (optional)
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Tests
- `chore`: Maintenance

Examples:
```
feat(templates): add ML model template

fix(security): resolve CWE-78 pattern detection

docs(readme): update installation instructions
```

## Style Guide

### JavaScript

- Use ES6+ features
- 2 spaces indentation
- Single quotes for strings
- Semicolons required
- Max line length: 100

### YAML

- 2 spaces indentation
- Use quotes for strings with special characters
- Document all fields

### Markdown

- Use ATX-style headers (`#`)
- Wrap lines at 80 characters
- Use fenced code blocks with language

## Questions?

- **General**: Open a [Discussion](https://github.com/theneoai/skill-writer/discussions)
- **Bugs**: Open an [Issue](https://github.com/theneoai/skill-writer/issues)
- **Security**: Open a [GitHub Security Advisory](https://github.com/theneoai/skill-writer/security/advisories/new)

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in documentation

Thank you for contributing! 🎉
