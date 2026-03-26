# Optimization Anti-Patterns

> Documented from rounds 52-70 of skill-manager optimization work.
> This document catalogs the mistakes made during optimization to serve as a reference for avoiding similar pitfalls.

---

## Anti-Pattern 1: Inconsistent Scoring Metrics (Metric Instability)

- **What happened**: Multiple scoring scripts (`score.sh`, `score-v2.sh`, `score-llm.sh`) used different regex patterns and weight distributions for the same dimensions, causing the same skill file to receive different scores depending on which script was used.

- **Impact**: 
  - Score variance > 1.5 points between scripts for the same file
  - Tune loop would keep/discard same change based on which scorer was used
  - 10 consecutive discards could occur even when improvement was valid
  - General instability in the optimization loop

- **How to avoid**:
  - Create a single source of truth for regex patterns (see `scripts/lib/trigger_patterns.sh`)
  - Lock weight distributions per dimension across all scoring scripts
  - Add consistency validation: difference between v1 and v2 scoring must be < 1.5
  - Run stability-check.sh after any scoring script modification

---

## Anti-Pattern 2: Non-Deterministic Improvement Selection (Random Tuning)

- **What happened**: Original `tune.sh` used `RANDOM` to select the next improvement type, causing the same starting point to produce different optimization paths across runs.

- **Impact**:
  - Non-reproducible optimization results
  - Could not replicate which improvement led to final state
  - Wasted rounds exploring paths that had already been tried
  - Team members could not reproduce each other's tuning results

- **How to avoid**:
  - Replace random selection with priority-based selection (weakest dimension first)
  - Use deterministic ordering: always fix lowest-scoring dimension before higher ones
  - Log the full decision chain so paths can be replicated
  - Consider using a deterministic seed if randomness is truly needed

---

## Anti-Pattern 3: Premature Optimization of Secondary Dimensions

- **What happened**: Tuning would start improving dimensions that were already at acceptable levels (e.g., adding more examples when Examples was already 9/10) instead of focusing on critical gaps.

- **Impact**:
  - Wasted optimization rounds on dimensions that barely contributed to overall score
  - 10 consecutive discards because improvements were marginal or non-scoring
  - Skills remained unstable because core issues (missing §1.1/1.2/1.3) were never fixed

- **How to avoid**:
  - Always prioritize dimensions below their floor threshold (System Prompt < 6.0, Domain < 6.0, etc.)
  - Use a priority queue: fix lowest-scoring dimension first
  - Skip improvements to dimensions already at 9+/10 unless no other options exist
  - Set minimum improvement threshold (e.g., require > 0.1 score increase to keep)

---

## Anti-Pattern 4: Ignoring Variance Between Text and Runtime Scores

- **What happened**: Optimization focused purely on text score without checking runtime consistency, leading to high variance (e.g., Text 9/10, Runtime 5/10).

- **Impact**:
  - Documentation looked perfect but skill failed in actual use
  - Variance > 2.0 was a red flag that went unaddressed
  - Certified skills that did not work as described

- **How to avoid**:
  - Always run dual-track evaluation (text + runtime)
  - Reject any improvement that increases variance by > 0.5
  - Add variance check to tune loop: if variance > 2.0, alert and halt
  - Weight overall score calculation to penalize high variance

---

## Anti-Pattern 5: Test File Bugs Causing False Negatives

- **What happened**: Test files contained arithmetic errors (e.g., expected 7.85 when actual was 7.65) and unrealistic time estimates (2-hour certify test could not run in CI).

- **Impact**:
  - 4 test failures in rounds 22-28 were due to test bugs, not implementation bugs
  - Test suite showed 87% pass rate when actual implementation was 100% correct
  - Team spent time investigating "failures" that were not real
  - False confidence in stability due to missed test coverage

- **How to avoid**:
  - Validate expected values in test files match calculated values
  - Add tolerance ranges for floating-point comparisons (e.g., ±0.1)
  - Mock time-intensive operations in CI (quick-certify mode)
  - Run test file validation before running actual tests

---

## Anti-Pattern 6: Script Dependency Blind Spots

- **What happened**: Scripts assumed dependencies existed without checking:
  - `tune.sh` called `score.sh` without validating the path
  - All scripts assumed `bc` was available
  - LLM scripts had inconsistent API key error handling

- **Impact**:
  - Tune loop would fail mid-execution with cryptic errors
  - Score failures in CI but not locally (missing `bc`)
  - Partial results written to files when scripts crashed

- **How to avoid**:
  - Add dependency checks at script startup: `command -v bc >/dev/null || exit 1`
  - Validate all referenced script paths before calling
  - Add consistent error handling for API key issues
  - Create a pre-flight check script that validates all dependencies

---

## Anti-Pattern 7: Over-Optimization of Already-Good Dimensions

- **What happened**: During rounds 52-70, aggressive attempts to push scores from 9.8 to 9.9+ resulted in:
  - Adding redundant §1.1/1.2/1.3 sections that duplicated existing content
  - Adding placeholder benchmarks that were generic ("accuracy > 90%")
  - Adding excessive examples that diluted quality

- **Impact**:
  - SKILL.md exceeded 300-line recommended limit
  - Generic content penalized the score instead of helping
  - Skills became harder to maintain

- **How to avoid**:
  - Set ceiling thresholds: stop optimizing dimension at 9.5
  - Prefer depth over breadth: make existing content better rather than adding more
  - Reject improvements that add generic placeholder content
  - Enforce line count limits and reject/trim content that exceeds them

---

## Anti-Pattern 8: Ignoring Feedback Metrics in Optimization Loop

- **What happened**: `feedback.sh` tracked production metrics (trigger accuracy, user satisfaction, error rate) but `tune.sh` never read them, creating a disconnect between live performance and optimization.

- **Impact**:
  - Optimization improved text scores but not user satisfaction
  - Trigger accuracy problems went unaddressed by tuning
  - Same errors repeated because feedback was not incorporated

- **How to avoid**:
  - Feed production metrics back into tuning decisions
  - Weight user satisfaction in overall score calculation
  - Alert if trigger accuracy drops below threshold during tuning
  - Create闭环: feedback -> tune -> feedback

---

## Anti-Pattern 9: Lack of Checkpoint/Resume for Long Operations

- **What happened**: certify.sh took ~2 hours to complete. If interrupted, all progress was lost with no way to resume.

- **Impact**:
  - Test suite could not verify certification in reasonable time
  - Interruptions during certification required starting over
  - Production deployments delayed due to certification time

- **How to avoid**:
  - Add checkpoint logging: save state after each major phase
  - Implement resume capability: detect existing checkpoint and continue
  - Create quick-certify mode (30 seconds) for iterative testing
  - Keep full certify for production sign-off only

---

## Anti-Pattern 10: Single-Metric Obsession (Score-only Thinking)

- **What happened**: Tune loop optimized for score without considering:
  - Stability (same file scored differently on re-run)
  - Consistency (text and runtime diverged)
  - Maintainability (code became complex and fragile)

- **Impact**:
  - Skills that scored well but were unstable
  - Skills that looked good in docs but failed in practice
  - Technical debt accumulated as scripts grew complex

- **How to avoid**:
  - Track multiple metrics: score + stability + variance + error rate
  - Reject improvements that degrade stability below threshold
  - Add overall health score that combines multiple dimensions
  - Run stability-check.sh as part of every tune iteration

---

## Summary: Key Lessons Learned

| Anti-Pattern | Root Cause | Detection Signal | Prevention |
|--------------|------------|------------------|------------|
| Inconsistent Scoring | Multiple regex patterns | v1-v2 diff > 1.5 | Single pattern library |
| Random Tuning | RANDOM in bash | Non-reproducible | Deterministic selection |
| Premature Optimization | No dimension priority | Wasted rounds | Priority queue |
| Ignoring Variance | Score-only focus | variance > 2.0 | Dual-track always |
| Test Bugs | Unvalidated test data | False negatives | Test validation |
| Dependency Blind Spots | No checks | Crashes on fresh env | Pre-flight checks |
| Over-optimization | No ceiling | Line count > 300 | Stop at thresholds |
| Ignoring Feedback | Siloed systems | Metrics not improving | Close the loop |
| No Checkpoints | Sequential assumption | Lost progress | Checkpoint/resume |
| Single-Metric | Score-as-truth | Unstable high scores | Multi-metric health |

---

**Document Version**: 1.0  
**Source Rounds**: 52-70  
**Last Updated**: 2026-03-27
