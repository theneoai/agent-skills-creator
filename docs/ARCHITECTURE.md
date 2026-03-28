# Skill System Architecture

> Technical architecture of the skill lifecycle management system

---

## Overview

The skill system is a self-contained skill engineering framework that enables creating, evaluating, restoring, securing, and optimizing AI skills through a multi-LLM deliberation system.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         User Interface                               │
│                    (scripts/ + SKILL.md)                           │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    ENGINE - Lifecycle Management                     │
│                                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ CREATE   │  │ EVALUATE │  │ RESTORE  │  │ SECURITY │           │
│  │ orchestr │  │ evaluato │  │ restorer │  │ security │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │              │              │              │                  │
│       └──────────────┴──────────────┴──────────────┘                  │
│                              │                                      │
│                    ┌─────────▼─────────┐                             │
│                    │   EVOLUTION       │                             │
│                    │   (9-step loop)    │                             │
│                    └───────────────────┘                             │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    EVAL - Quality Assurance                         │
│                                                                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐               │
│  │ Parse   │  │  Text   │  │ Runtime │  │ Certify │               │
│  │ Phase 1 │  │ Phase 2 │  │ Phase 3 │  │ Phase 4 │               │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘               │
│                                                                      │
│                    ┌─────────────────────┐                          │
│                    │   Multi-LLM Call    │                          │
│                    │   agent_executor    │                          │
│                    └─────────────────────┘                          │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

```
skill-system/
├── SKILL.md                    # Self-describing skill manifest
├── README.md                   # Project overview
├── CHANGELOG.md                # Version history
│
├── scripts/                    # User-facing CLI tools
│   ├── create-skill.sh        # Skill creation
│   ├── evaluate-skill.sh       # Full evaluation
│   ├── optimize-skill.sh       # Self-optimization
│   ├── security-audit.sh       # Security audit
│   ├── restore-skill.sh       # Skill restoration
│   └── quick-score.sh         # Fast text scoring
│
├── engine/                     # Skill lifecycle management
│   ├── main.sh                # Engine entry point
│   ├── orchestrator.sh         # Workflow coordinator
│   │
│   ├── agents/                # Specialized agents
│   │   ├── base.sh           # Agent infrastructure
│   │   ├── creator.sh         # Section generator
│   │   ├── evaluator.sh       # Skill evaluator
│   │   ├── restorer.sh       # Skill repair
│   │   └── security.sh        # OWASP audit
│   │
│   ├── evolution/             # Self-optimization
│   │   ├── engine.sh          # 9-step loop
│   │   ├── analyzer.sh        # Log analysis
│   │   ├── improver.sh        # LLM improvement
│   │   ├── summarizer.sh      # Finding synthesis
│   │   ├── rollback.sh        # Snapshot/rollback
│   │   └── _storage.sh        # Log abstraction
│   │
│   ├── orchestrator/          # Workflow components
│   │   ├── _state.sh         # State management
│   │   ├── _actions.sh       # Decision logic
│   │   ├── _workflow.sh      # Main workflow
│   │   └── _parallel.sh       # Background tasks
│   │
│   ├── lib/                   # Shared libraries
│   │   ├── bootstrap.sh       # Module loading
│   │   ├── constants.sh       # Configuration
│   │   ├── concurrency.sh     # Lock management
│   │   ├── errors.sh         # Error handling
│   │   └── integration.sh     # Eval integration
│   │
│   └── prompts/               # Agent prompts
│       ├── creator-system.md
│       └── evaluator-system.md
│
├── eval/                       # Quality assurance framework
│   ├── main.sh                # Eval entry point
│   │
│   ├── parse/                 # Phase 1: Structure
│   │   └── parse_validate.sh
│   │
│   ├── scorer/                # Phase 2-3: Quality
│   │   ├── text_scorer.sh    # Text quality (350pts)
│   │   ├── runtime_tester.sh  # Runtime (450pts)
│   │   └── runtime_agent_tester.sh
│   │
│   ├── analyzer/              # Metrics
│   │   ├── trigger_analyzer.sh  # F1/MRR
│   │   ├── variance_analyzer.sh   # Score variance
│   │   └── dimension_analyzer.sh
│   │
│   ├── report/                # Output
│   │   ├── json_reporter.sh
│   │   └── html_reporter.sh
│   │
│   ├── corpus/                # Test data
│   │   ├── corpus_100.json   # Fast eval
│   │   └── corpus_1000.json  # Full eval
│   │
│   └── lib/                   # Eval utilities
│       ├── agent_executor.sh   # LLM orchestration
│       ├── constants.sh        # Thresholds
│       ├── utils.sh
│       └── i18n.sh
│
├── tests/                      # Test suite
│   ├── run_tests.sh           # Test runner
│   ├── unit/                  # Unit tests
│   └── integration/            # Integration tests
│
├── docs/                       # Documentation
│   ├── API.md                 # API reference
│   └── ARCHITECTURE.md        # This file
│
├── examples/                  # Usage examples
│
└── .github/workflows/         # CI/CD
    ├── ci.yml                # Continuous integration
    └── pages.yml              # GitHub Pages
```

---

## Core Concepts

### Multi-LLM Deliberation

All critical decisions use multiple LLM providers (Anthropic, OpenAI, Kimi) for cross-validation:

1. **Independent Analysis**: Each LLM analyzes independently
2. **Result Comparison**: Results compared for agreement
3. **Conflict Resolution**: Disagreements trigger deliberation
4. **Confidence Scoring**: Final confidence level assigned

### 9-Step Optimization Loop

The evolution engine continuously improves skills through:

```
READ → ANALYZE → CURATION → PLAN → IMPLEMENT → VERIFY → HUMAN_REVIEW → LOG → COMMIT
```

- **READ**: Locate weakest dimension (Multi-LLM)
- **ANALYZE**: Prioritize improvement strategy
- **CURATION**: Consolidate knowledge (every 10 rounds)
- **PLAN**: Select specific improvement approach
- **IMPLEMENT**: Apply atomic change
- **VERIFY**: Multi-LLM verification
- **HUMAN_REVIEW**: Expert review if score < 8.0
- **LOG**: Record to results.tsv
- **COMMIT**: Git commit every 10 rounds

### 4-Phase Evaluation (Full)

| Phase | Focus | Score |
|-------|-------|-------|
| 1. Parse | Structure, YAML, triggers | 100pts |
| 2. Text | Quality, completeness | 350pts |
| 3. Runtime | Behavior, consistency | 450pts |
| 4. Certify | Tier, variance, security | 100pts |

**Total: 1000pts**

### Lean Evaluation (~0 seconds, $0)

For fast feedback during development, lean evaluation uses heuristic scoring without LLM:

```
LEAN: fast_parse → text_score_heuristic → runtime_test_fast → CERTIFY
```

**Lean Scoring (500pts)**:

| Phase | Focus | Max | Method |
|-------|-------|-----|--------|
| Parse | YAML, §1.x, triggers | 100 | Grep pattern matching |
| Text | §1.x quality, domain, workflow | 350 | Keyword frequency |
| Runtime | §2 trigger patterns, modes | 50 | Table/pattern detection |

**Lean Thresholds**:

| Tier | Total | Percentage |
|------|-------|------------|
| GOLD | 475+ | 95% |
| SILVER | 425+ | 85% |
| BRONZE | 350+ | 70% |

**When to Use Lean vs Full**:
- **Lean**: CI/CD, iterative development, quick checks
- **Full**: Production certification, final validation

### Certification Tiers

| Tier | Score | F1 | MRR | Variance |
|------|-------|-----|-----|----------|
| PLATINUM | ≥950 | ≥0.95 | ≥0.90 | <10 |
| GOLD | ≥900 | ≥0.95 | ≥0.90 | <15 |
| SILVER | ≥800 | ≥0.92 | ≥0.87 | <20 |
| BRONZE | ≥700 | ≥0.90 | ≥0.85 | <30 |

---

## Data Flow

### Skill Creation
```
User Input → create-skill.sh → orchestrator.sh
    → Creator Agent (LLM) → evaluator.sh → Iteration Loop
    → Final Skill File
```

### Skill Evaluation (Full)
```
User Input → evaluate-skill.sh → eval/main.sh
    → parse_validate.sh (Phase 1)
    → text_scorer.sh (Phase 2)
    → runtime_tester.sh (Phase 3)
    → certifier.sh (Phase 4)
    → JSON/HTML Report
```

### Lean Evaluation (~0 seconds)
```
User Input → lean-orchestrator.sh
    → fast_parse (grep patterns)
    → text_score_heuristic (keyword frequency)
    → runtime_test_fast (trigger detection)
    → CERTIFY
```

### Skill Optimization
```
User Input → optimize-skill.sh → evolution/engine.sh
    → Multi-LLM Analysis (READ)
    → Strategy Selection (ANALYZE)
    → Improvement Generation (IMPLEMENT)
    → Verification Loop
    → Snapshot on improvement
    → Auto-rollback on regression
```

---

## Security

### OWASP AST10 Checklist

1. Credential Scan
2. Input Validation
3. Path Traversal
4. Trigger Sanitization
5. YAML Parsing Safety
6. Command Injection Prevention
7. SQL Injection Prevention
8. Data Exposure Prevention
9. Log Security
10. Error Handling Security

---

## Configuration

### Thresholds

| Setting | Value | Description |
|---------|-------|-------------|
| `EVOLUTION_THRESHOLD_NEW` | 10 | Evals before first evolution |
| `EVOLUTION_THRESHOLD_GROWING` | 50 | Evals for growing skills |
| `EVOLUTION_THRESHOLD_STABLE` | 100 | Evals for stable skills |
| `PASSING_SCORE` | 800 | Minimum score for production |
| `MAX_SNAPSHOTS` | 10 | Snapshots to retain |

### Timeouts (seconds)

| Setting | Value |
|---------|-------|
| `CREATOR_TIMEOUT` | 60 |
| `EVALUATOR_TIMEOUT` | 30 |
| `EVOLUTION_TIMEOUT` | 120 |
| `SKILL_FILE_TIMEOUT` | 10 |
| `LLM_TIMEOUT` | 15 |
