# Agent Skills Creator

A tool for creating, evaluating, and optimizing AI agent skills following the agentskills.io v2.1.0 open standard.

## Core Capabilities

- **Skill Lifecycle Management**: Create, evaluate, train, and optimize skills end-to-end
- **Multi-Agent Collaboration**: Parallel, hierarchical, debate, and crew patterns
- **Quality Assurance**: Dual-track validation with F1≥0.90, MRR≥0.85, MultiTurnPassRate≥85%
- **CI/CD Pipeline Generation**: Auto-generate GitHub Actions workflows
- **Security Review**: OWASP AST10 (2024) compliance checking
- **Self-Optimization**: Autonomous skill improvement loop with 7-step optimization cycle

## Quick Start

```bash
# Create a new skill
opencode "create a code-review skill"

# Evaluate a skill
opencode "evaluate git-release skill"

# Run security review
opencode "execute OWASP AST10 security review"

# Self-optimize current skill
opencode "self-optimize"
```

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `validate.sh` | Validate skill structure against agentskills.io standard |
| `eval.sh` | Run evaluation on skill test cases |
| `score.sh` / `score-v3.sh` | Calculate quality scores (Text, Runtime, Variance) |
| `certify.sh` | Certify skill if metrics meet thresholds |
| `tune.sh` | Tune skill parameters |
| `feedback.sh` | Collect improvement feedback |
| `self-optimize.sh` | Run 7-step autonomous optimization loop |
| `generate_ci_pipeline.py` | Generate GitHub Actions CI/CD pipeline |
| `validate_skill.py` | Python-based skill validation |

## Directory Structure

```
agent-skills-creator/
├── SKILL.md              # Main skill definition
├── scripts/
│   ├── skill-manager/    # Core skill management tools
│   └── self-optimize.sh  # Self-optimization loop
├── references/           # Documentation and templates
│   └── skill-manager/    # Detailed guides (create, evaluate, etc.)
├── evals/                # Evaluation datasets
├── test_cases/           # Test cases
└── test_results/         # Test results
```

## Quality Standards

- **Text Score ≥ 8.0**
- **Runtime Score ≥ 8.0**
- **Variance < 1.0** (|Text - Runtime|)
- **Certification**: Text ≥ 8.0 + Runtime ≥ 8.0 + Variance < 1.0

## References

- [agentskills.io Standard](https://agentskills.io)
- [SKILL.md](./SKILL.md) - Full skill definition
- [Self-Optimization](./references/SELF_OPTIMIZATION.md)
- [Create Guide](./references/skill-manager/create.md)
- [Evaluation Guide](./references/skill-manager/evaluate.md)
- [Optimization Methodology](./references/skill-manager/OPTIMIZATION_METHODOLOGY.md)
- [OWASP AST10 Checklist](./references/owasp-ast10-checklist.md)
