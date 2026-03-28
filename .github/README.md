# GitHub CI/CD Workflows

This directory contains automated workflows for code review and skill evaluation.

## Workflows

### 1. `ci.yml` - Main CI Pipeline

Triggered on: push to `main`, pull requests to `main`

**Jobs:**

| Job | Purpose | Key Files |
|-----|---------|-----------|
| `lint` | Run shellcheck on all `.sh` files | Uses matrix strategy for ubuntu/macos |
| `eval` | Verify SKILL.md quality via eval framework | `eval/main.sh --skill ./SKILL.md --fast` |
| `test` | Run engine tests and test_cases | `engine/tests/run_tests.sh` |

**Eval Framework Path:** `eval/main.sh` (not `unified-skill-eval/main.sh`)

**Artifacts:**
- `eval-results/` - Contains `summary.json`, `phase1-4.json` from eval run

### 2. `code-review.yml` - AI Code Review

Triggered on: pull requests (opened, synchronize, reopened)

Posts automated review comments on PRs with:
- Summary of changes
- Review focus areas
- Links to automated check results

### 3. `pages.yml` - GitHub Pages Deployment

Triggered on: push to `main`, manual dispatch

Deploys documentation to GitHub Pages.

---

## Engine Directory Structure

```
engine/
├── agents/          # Agent implementations
├── evolution/        # Evolution and rollback logic
├── lib/             # Core libraries (bootstrap, constants, concurrency, errors)
├── orchestrator/    # Orchestration scripts
├── tests/           # Test suite (run_tests.sh)
├── main.sh          # Engine entry point
└── orchestrator.sh  # Orchestrator entry point
```

---

## Eval Framework

**Location:** `eval/main.sh`

**Usage:**
```bash
bash eval/main.sh --skill ./SKILL.md --fast --output ./eval_results --ci
```

**Phases:**
1. Phase 1: Parse & Validate (100pts)
2. Phase 2: Text Score (350pts)
3. Phase 3: Runtime Score (450pts)
4. Phase 4: Certification (100pts)

**Output:** `summary.json` with tier determination (PLATINUM/GOLD/SILVER/BRONZE/NOT_CERTIFIED)

---

## Running Locally

```bash
# Run lint
shellcheck **/*.sh

# Run eval
bash eval/main.sh --skill ./SKILL.md --fast

# Run engine tests
cd engine && bash tests/run_tests.sh
```
