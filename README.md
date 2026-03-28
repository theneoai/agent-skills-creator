# Skill Engineering

[![PLATINUM Tier](https://img.shields.io/badge/Tier-PLATINUM-4CAF50)](engine/)
[![F1 Score](https://img.shields.io/badge/F1%20Score-0.923-2196F3)](eval/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

**Authors**: theneoai <lucas_hsueh@hotmail.com> | **Version**: 1.9.0 | **Standard**: agentskills.io v2.1.0

---

## Abstract

Agent Skill Engineering is a comprehensive methodology for managing the complete lifecycle of AI agent skills—from specification through autonomous optimization to production certification. We address four fundamental challenges: standardized skill representation, reliable dual-track evaluation, autonomous optimization, and long-context document handling.

Our **multi-agent optimization architecture** employs parallel evaluation across specialized agents (Security, Trigger, Runtime, Quality, EdgeCase) under deterministic improvement selection. The **9-step autonomous loop** achieves continuous improvement with measurable quality targets.

**Key Metrics**: Text Score ≥ 9.5, Runtime Score ≥ 9.5, Variance < 1.0, F1 ≥ 0.90

---

## Key Features

- **9-Step Autonomous Optimization Loop**: READ → ANALYZE → CURATION → PLAN → IMPLEMENT → VERIFY → HUMAN_REVIEW → LOG → COMMIT
- **Dual-Track Validation**: Text quality + Runtime effectiveness
- **Multi-Agent Parallel Evaluation**: 5 specialized agents
- **4-Tier Certification**: PLATINUM ≥ 9.5 | GOLD ≥ 9.0 | SILVER ≥ 8.0 | BRONZE ≥ 7.0
- **Trace Compliance** (AgentPex methodology)
- **Long-Context Handling**: 100K+ tokens with chunking, RAG, cross-reference preservation

---

## Quick Start

```bash
# Create a new skill
./engine/main.sh create "code-review skill"

# Evaluate a skill
./eval/main.sh score path/to/SKILL.md

# Run self-optimization
./engine/main.sh tune path/to/SKILL.md

# Run security review
./engine/main.sh security path/to/SKILL.md
```

---

## Directory Structure

```
skill/
├── SKILL.md              # Main skill definition
├── engine/               # Core optimization engine
│   ├── main.sh           # Entry point
│   ├── orchestrator.sh   # Workflow orchestration
│   ├── agents/           # Specialized agents
│   └── evolution/        # Self-optimization loop
├── eval/                 # Evaluation framework
│   ├── main.sh           # Evaluation entry
│   ├── scorer/            # Scoring engines
│   └── certifier.sh      # Certification
├── references/           # Detailed documentation
└── paper/                # Academic papers
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
