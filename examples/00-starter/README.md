# Example: git-diff-summarizer (Starter / BRONZE Target)

> **Certification target**: BRONZE (~700/1000)  
> **Skill type**: atomic  
> **Purpose**: Demonstrates the minimum viable structure for a working skill.

## Why start here?

The other examples in this folder (api-tester, code-reviewer, doc-generator) are
GOLD-tier skills (900+). They are great references but overwhelming for beginners.

**This skill shows the minimum you need to reach BRONZE (700/1000) and ship a working skill.**

---

## What's in this skill

| Section | Purpose | Required? |
|---------|---------|-----------|
| YAML frontmatter | name, version, skill_tier, triggers | ✅ Required |
| §1 Identity | Role, purpose, red lines | ✅ Required |
| §2 Skill Summary + Negative Boundaries | What it does / doesn't do | ✅ Required (v3.1.0) |
| §3 Workflow + Quality Gates | Steps and thresholds | ✅ Required |
| §4 Error Handling | Error types + recovery | ✅ Required |
| §5 Output Format | Example output | Strongly recommended |
| §6 Security Baseline | Input/output safety | ✅ Required |
| §7 Examples | Bilingual trigger examples | ✅ Required (≥2) |
| §UTE | Use-to-Evolve state block | Auto-injected by CREATE |

---

## Estimated LEAN score breakdown

| Dimension | Score | Notes |
|-----------|-------|-------|
| systemDesign | 65/100 | Identity + Red Lines present |
| domainKnowledge | 60/100 | Concrete field specificity, one template type |
| workflow | 55/100 | 5-step workflow + Quality Gates table |
| errorHandling | 65/100 | Error table + escalation path |
| examples | 60/100 | 3 examples, bilingual triggers |
| security | 55/100 | Security Baseline section present |
| metadata | 35/40 | Complete frontmatter + Negative Boundaries |
| **LEAN Total** | **~365/500** | **→ BRONZE proxy (estimated 730/1000)** |

---

## How to improve this from BRONZE → GOLD

| Change | Points gained | Effort |
|--------|--------------|--------|
| Add 3 more EN trigger phrases (total ≥ 8) | +15 pt | Low |
| Add second workflow mode (e.g. "batch summarise") | +20 pt | Medium |
| Add benchmark test cases (§3 extended) | +25 pt | Medium |
| Add Chinese output format example | +10 pt | Low |
| Add performance section (token budget, latency) | +15 pt | Low |
| Add UTE hook configuration | +20 pt | High |
| **Total potential gain** | **+105 pt** | → GOLD range |

---

## Learning path

```
00-starter (this file)    ~730 pt BRONZE  ← Start here
     ↓ add modes + examples
api-tester                ~920 pt GOLD    ← Single-mode GOLD
     ↓ add bilingual + UTE
code-reviewer             ~947 pt GOLD    ← Multi-mode advanced
```

---

## Try it yourself

1. Copy `skill.md` to your platform's skills directory
2. Restart your AI platform
3. Try: `summarise this diff` or `总结这个 diff`
4. Run `/lean` on the skill to see its actual score
5. Then try `/opt` to see how the optimizer improves it
