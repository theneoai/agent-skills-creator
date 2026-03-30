# Skill Engineering

**Full Lifecycle AI Skill Engineering System**

[![CI](https://github.com/theneoai/skill/actions/workflows/ci.yml/badge.svg)](https://github.com/theneoai/skill/actions)
[![PyPI Version](https://img.shields.io/pypi/v/skill-engineering.svg)](https://pypi.org/project/skill-engineering/)
[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://pypi.org/project/skill-engineering/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-634%20passed-brightgreen)](tests/unit/)

A comprehensive framework for creating, evaluating, restoring, securing, and optimizing AI skills. Built with multi-agent orchestration, self-evolution capabilities, and enterprise-grade evaluation.

## Overview

Skill Engineering provides production-ready AI skill lifecycle management:

- **Multi-Mode Operation**: CREATE | EVALUATE | RESTORE | SECURITY | OPTIMIZE
- **Multi-LLM Deliberation**: Cross-validation with 3 independent LLMs
- **Self-Evolution**: Autonomous improvement based on usage metrics
- **Enterprise Evaluation**: GEPA, SAE, Ground Truth benchmarks
- **Security Audit**: CWE-based OWASP AST10 security scanning
- **Cross-Platform Compatible**: MCP, Microsoft Copilot, OpenAI agents

## Quick Start

```bash
# Install
pip install skill-engineering

# Evaluate a skill
skill evaluate ./SKILL.md

# Create a new skill
skill create "Create a weather API skill"

# Parse and validate
skill parse ./SKILL.md
skill validate ./SKILL.md
```

## Installation

```bash
# From PyPI
pip install skill-engineering

# From source
git clone https://github.com/theneoai/skill.git
cd skill
pip install -e .
```

## Features

### Multi-Mode Lifecycle

| Mode | Purpose | Trigger Keywords |
|------|---------|------------------|
| CREATE | Build new skills from requirements | create, build, new, 开发 |
| EVALUATE | Measure quality (F1 ≥ 0.90, MRR ≥ 0.85) | evaluate, test, 评估, 测试 |
| RESTORE | Repair broken or degraded skills | restore, repair, fix, 修复 |
| SECURITY | CWE-based security audit | security, audit, scan, 安全 |
| OPTIMIZE | Autonomous self-improvement | optimize, improve, 优化 |

### Quality Certification Tiers

| Tier | Score | Description |
|------|-------|-------------|
| PLATINUM | ≥950 | Elite production quality |
| GOLD | ≥900 | Production ready, excellent |
| SILVER | ≥800 | Production ready, good |
| BRONZE | ≥700 | Ready with minor issues |

### Cross-Platform Compatibility

Skills produced by this framework are compatible with:

- **MCP (Model Context Protocol)**: For Claude Code, Cursor, and other MCP clients
- **Microsoft Copilot**: Via declarative agent manifest format
- **OpenAI Agents**: Via standard tool definition format

## Architecture

```
skill/
├── cli/                    # Command-line interface
├── orchestrator/           # LoongFlow workflow orchestration
├── agents/                 # Agent implementations (creator, evaluator, etc.)
├── engine/                 # Self-evolution engine (BOAD/ROAD)
├── eval/                   # Evaluation framework (GEPA, SAE, Ground Truth)
└── schema.py              # Universal metadata schema
```

See [docs/source/architecture.md](docs/source/architecture.md) for detailed architecture.

## Documentation

| Document | Description |
|----------|-------------|
| [docs/source/getting-started.md](docs/source/getting-started.md) | Installation and quick start |
| [docs/source/architecture.md](docs/source/architecture.md) | Technical architecture |
| [docs/source/user-guide.md](docs/source/user-guide.md) | End user manual |
| [docs/source/developer-guide.md](docs/source/developer-guide.md) | For AI agent developers |
| [docs/source/api-reference.md](docs/source/api-reference.md) | CLI and API reference |
| [SKILL.md](SKILL.md) | Skill format specification |

## Development

```bash
# Set up development environment
pip install -e .[dev]

# Run linting
ruff check skill/

# Run type checking
mypy skill/

# Run tests
python -m pytest tests/unit/ -v
```

## Contributing

Contributions are welcome! Please read our coding standards and submit PRs with tests.

## License

MIT License - see [LICENSE](LICENSE) for details.
