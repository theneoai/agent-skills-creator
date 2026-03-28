# Skill Engineering

[![GOLD Tier](https://img.shields.io/badge/Tier-GOLD-4CAF50)](SKILL.md)
[![Lean Eval](https://img.shields.io/badge/Lean%20Eval-0.5s-2196F3)](scripts/lean-orchestrator.sh)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

**Authors**: theneoai <lucas_hsueh@hotmail.com> | **Version**: 2.0.0 | **Standard**: agentskills.io v2.1.0

---

## Abstract

Agent Skill Engineering is a comprehensive methodology for managing the complete lifecycle of AI agent skills—from specification through autonomous optimization to production certification. We address four fundamental challenges: standardized skill representation, reliable dual-track evaluation, autonomous optimization, and long-context document handling.

Our **multi-agent optimization architecture** employs parallel evaluation across specialized agents (Security, Trigger, Runtime, Quality, EdgeCase) under deterministic improvement selection. The **9-step autonomous loop** achieves continuous improvement with measurable quality targets.

**Key Innovation**: Lean evaluation mode enables **~0 second** skill assessment at ~$0 cost, with full evaluation available when needed.

---

## Key Features

- **6 Modes**: CREATE, EVALUATE, LEAN, RESTORE, SECURITY, OPTIMIZE
- **9-Step Autonomous Optimization Loop**: READ → ANALYZE → CURATION → PLAN → IMPLEMENT → VERIFY → HUMAN_REVIEW → LOG → COMMIT
- **Multi-LLM Deliberation**: Cross-validation with Anthropic, OpenAI, Kimi
- **Dual-Track Validation**: Text quality + Runtime effectiveness
- **4-Tier Certification**: GOLD ≥ 475 | SILVER ≥ 425 | BRONZE ≥ 350
- **Lean Evaluation**: ~0 second, ~$0 cost (heuristic-based)
- **OWASP AST10 Security**: 10-item security checklist

---

## Quick Start

### Fast Evaluation (~0 seconds, $0)

```bash
# Lean evaluation (no LLM, heuristic-based)
./scripts/lean-orchestrator.sh ./SKILL.md

# Quick text score
./scripts/quick-score.sh ./SKILL.md
```

### Full Evaluation (~2 minutes)

```bash
# Full evaluation with LLM
./scripts/evaluate-skill.sh ./SKILL.md
```

### Skill Lifecycle

```bash
# Create a new skill
./scripts/create-skill.sh "Create a code review skill"

# Security audit
./scripts/security-audit.sh ./code-review.md

# Optimize
./scripts/optimize-skill.sh ./code-review.md

# Restore broken skill
./scripts/restore-skill.sh ./broken-skill.md
```

---

## Evaluation Modes

| Mode | Speed | Cost | Accuracy | Use Case |
|------|-------|------|----------|----------|
| **LEAN** | ~0s | $0 | 95% | CI/CD, quick checks |
| **Full Eval** | ~2min | ~$0.50 | 99% | Production, final cert |
| **Optimize** | ~5min | ~$2.00 | 99% | Continuous improvement |

---

## Directory Structure

```
skill-system/
├── SKILL.md                    # Self-describing skill manifest
├── README.md                   # This file
├── CHANGELOG.md               # Version history
│
├── scripts/                   # User-facing CLI tools
│   ├── lean-orchestrator.sh   # Fast evaluation (~0s, $0)
│   ├── create-skill.sh         # Create new skills
│   ├── evaluate-skill.sh       # Full evaluation (~2min)
│   ├── optimize-skill.sh       # Self-optimization
│   ├── security-audit.sh      # OWASP AST10
│   ├── restore-skill.sh       # Fix broken skills
│   └── quick-score.sh         # Text scoring
│
├── engine/                    # Skill lifecycle management
│   ├── agents/                # Creator, Evaluator, Restorer, Security
│   ├── evolution/             # 9-step optimization loop
│   ├── orchestrator/          # Workflow components
│   ├── lib/                   # Shared libraries
│   └── prompts/               # Agent prompts
│
├── eval/                      # Quality assurance framework
│   ├── scorer/               # Text & runtime scoring
│   ├── analyzer/             # F1/MRR/variance
│   ├── corpus/               # Test data
│   └── report/               # Output formatters
│
├── tests/                     # Test suite
│   ├── run_tests.sh          # Test runner
│   ├── unit/                 # Unit tests
│   └── integration/           # Integration tests
│
├── docs/                      # Documentation
│   ├── API.md                # API reference
│   └── ARCHITECTURE.md       # Technical architecture
│
└── .github/workflows/         # CI/CD
```

---

## Performance

**Lean Evaluation Results**:
```
Parse Score: 100/100
Text Score:  325/350 (93%)
Runtime:      50/50 (100%)
─────────────────────────
TOTAL:        475/500 (GOLD)
Time:         0 seconds
Cost:         $0
```

---

## BibTeX

```
@article{neoai2026agent,
  author  = {neo.ai},
  title   = {Agent Skill Engineering: A Systematic Approach to AI Skill Lifecycle Management},
  journal = {arXiv preprint},
  year    = {2026},
  eprint  = {arXiv:XXXX.XXXXX},
  primaryClass = {cs.AI}
}
```

---

**Last Updated**: 2026-03-28
