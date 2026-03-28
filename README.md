# Skill Engineering

[📄 Paper (English)](paper/agent_skills_engineering.md) | [📄 论文 (中文)](paper/agent_skills_engineering_zh.md) | [📖 Methodology](paper/methodology.md) | [🔧 Scripts](scripts/skill-manager/)

**Authors**: theneoai <lucas_hsueh@hotmail.com>  
**Version**: 1.6.0 | **License**: MIT | **Standard**: agentskills.io v2.1.0

---

## Abstract

The proliferation of large language model (LLM)-based agents has created an urgent need for systematic engineering approaches to AI skill development. Unlike traditional software, agent skills encompass complex behavioral specifications that must exhibit consistent performance across diverse execution contexts.

This repository presents **Agent Skill Engineering**, a comprehensive methodology for managing the complete lifecycle of AI agent skills, from initial specification through autonomous optimization to production certification. Our approach addresses four fundamental challenges: (1) the lack of standardized skill representation formats, (2) the absence of reliable evaluation frameworks capturing both textual quality and runtime effectiveness, (3) the need for autonomous optimization mechanisms, and (4) the critical capability to handle long-context documents.

We introduce a **multi-agent optimization architecture** employing parallel evaluation across specialized agents—Security, Trigger, Runtime, Quality, and EdgeCase—operating under a deterministic improvement selection protocol. Our **9-step autonomous loop** achieves continuous skill improvement with measurable quality targets.

**Key Metrics**: Text Score ≥ 9.5, Runtime Score ≥ 9.5, Variance < 1.0, Mode Detection ≥ 95%

---

## Key Features

- **9-Step Autonomous Optimization Loop**: READ → ANALYZE → CURATION → PLAN → IMPLEMENT → VERIFY → HUMAN_REVIEW → LOG → COMMIT
- **Dual-Track Validation**: Text quality scoring + Runtime effectiveness testing
- **Multi-Agent Parallel Evaluation**: Security, Trigger, Runtime, Quality, EdgeCase agents
- **Trace Compliance Analysis**: Behavioral rule extraction (AgentPex methodology)
- **Long-Context Handling**: Chunking, RAG, cross-reference preservation (100K+ tokens)
- **Human-Agent Collaboration**: Expert review integration for skills below 8.0 after 10 rounds
- **4-Tier Certification System**:
  ```
  ┌─────────────┬────────────┬────────────┬────────────┐
  │   TIER      │ TEXT SCORE │ RUNTIME    │ VARIANCE   │
  ├─────────────┼────────────┼────────────┼────────────┤
  │ PLATINUM    │   ≥ 9.5    │   ≥ 9.5    │   < 1.0    │
  │ GOLD        │   ≥ 9.0    │   ≥ 9.0    │   < 1.5    │
  │ SILVER      │   ≥ 8.0    │   ≥ 8.0    │   < 2.0    │
  │ BRONZE      │   ≥ 7.0    │   ≥ 7.0    │   < 3.0    │
  └─────────────┴────────────┴────────────┴────────────┘
  ```

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/theneoai/agent-skill-creator.git
cd agent-skill-creator

# Create a new skill
opencode "create a code-review skill"

# Evaluate a skill
opencode "evaluate the git-release skill"

# Run self-optimization
opencode "self-optimize"

# Run security review
opencode "execute OWASP AST10 security review"
```

---

## Scripts Reference

| Script | Purpose |
|--------|---------|
| [`score.sh`](scripts/skill-manager/score.sh) | 7-dimension text quality scoring |
| [`score-v3.sh`](scripts/skill-manager/score-v3.sh) | Runtime + Trace Compliance evaluation |
| [`tune.sh`](scripts/skill-manager/tune.sh) | 9-step autonomous optimization loop |
| [`certify.sh`](scripts/skill-manager/certify.sh) | Full certification determination |
| [`validate.sh`](scripts/skill-manager/validate.sh) | Format validation |
| [`runtime-validate.sh`](scripts/skill-manager/runtime-validate.sh) | Runtime effectiveness testing |
| [`edge-case-check.sh`](scripts/skill-manager/edge-case-check.sh) | Adversarial testing |
| [`self-optimize.sh`](scripts/self-optimize.sh) | Entry point for autonomous optimization |

---

## Directory Structure

```
agent-skill-creator/
├── SKILL.md                      # Main skill definition
├── paper/
│   ├── agent_skills_engineering.md    # English paper
│   ├── agent_skills_engineering_zh.md # Chinese paper
│   ├── methodology.md                 # Methodology details
│   └── figures/                      # Architecture diagrams
├── scripts/
│   └── skill-manager/              # Core skill management tools
├── references/
│   ├── SELF_OPTIMIZATION.md       # Self-optimization design
│   └── skill-manager/             # Detailed guides
└── test_cases/                    # Evaluation test cases
```

---

## BibTeX

```
@article{neoai2026agent,
  author       = {neo.ai},
  title        = {Agent Skill Engineering: A Systematic Approach to AI Skill Lifecycle Management and Autonomous Optimization},
  journal      = {arXiv preprint},
  year         = {2026},
  eprint       = {arXiv:XXXX.XXXXX},
  archivePrefix = {arXiv},
  primaryClass = {cs.AI}
}
```

---

## References

- [agentskills.io Standard](https://agentskills.io)
- [AgentPex (2026)](https://arxiv.org/abs/2603.23806) - Trace-Based Behavioral Evaluation
- [c-CRAB (2026)](https://arxiv.org/abs/2603.23448) - Code Review Agent Benchmark
- [SkillsBench (2026)](https://arxiv.org/abs/2606.XXXXX) - Skill Quality Benchmarks
- [ACE Framework (2025)](https://arxiv.org/abs/2510.XXXXX) - Context Collapse Prevention
- [Qwen-Agent (2026)](https://github.com/QwenLM/Qwen-Agent) - Agent Framework with MCP
- [MiniMax/skills (2026)](https://github.com/MiniMax-AI/skills) - Professional AI Skills

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.6.0 | 2026-03-27 | 9-step loop, Trace Compliance, Long-Context, Human Review |
| 1.5.0 | 2026-03-26 | Multi-agent parallel evaluation |
| 1.0.0 | 2026-03-20 | Initial release |

---

## Funding & Acknowledgments

This research builds upon the agentskills.io open standard and draws from recent advances in agent evaluation including AgentPex, c-CRAB, and SkillsBench.
