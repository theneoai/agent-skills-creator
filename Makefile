# Makefile — skill-writer development helpers
#
# Targets:
#   make help              Show this help
#   make lint              Run shellcheck on all install scripts
#   make validate          Dry-run all platform installers
#   make check-version     Verify version consistency across all platform files
#   make check-spec-compat Validate frontmatter against agentskills.io v1.0 spec
#   make build-platforms       Regenerate 8 platform files from platforms.yaml (strict)
#   make build-platforms-check Drift-check platform files vs platforms.yaml (migration mode)
#   make sign ARTIFACT=path    Ed25519-sign a release artifact (+ .sig/.pubkey/.provenance)
#   make verify ARTIFACT=path  Verify Ed25519 signature on a release artifact
#   make eval-trigger ARGS="--skill ... --eval-set ..."   Run real trigger-accuracy eval
#   make optimize-description ARGS="--skill ... --eval-set ..." Iterative description optimizer
#   make gepa-optimize ARGS="--skill ..."  GEPA reflective evolutionary optimizer (S17)
#   make multi-eval ARGS="--skill ..."     Statistical multi-run EVALUATE w/ CI (S18)
#   make aggregate ARGS="--artifacts-dir ..." AGGREGATE collective evolution pipeline
#   make drift-check ARGS="--skill ..."   Monitor skill LEAN score drift vs baseline
#   make ute-init SKILL=name LEAN=N       Initialize GitHub Gist UTE backend
#   make ute-record SKILL=name            Record one skill invocation to Gist
#   make ute-status SKILL=name            Show UTE state and pending cadence events
#   make install           Auto-detect and install to local platforms
#   make install-all       Install to all 8 platforms
#   make ci                Run lint + validate + check-version + check-spec-compat
#                          + build-platforms-check + check-platform-sync

.PHONY: help lint validate check-version check-spec-compat \
        build-platforms build-platforms-check sign verify \
        eval-trigger optimize-description emit-spec-pure \
        gepa-optimize multi-eval aggregate drift-check \
        ute-init ute-record ute-status \
        check-platform-sync install install-all ci

VERSION := $(shell cat VERSION)
PLATFORMS := claude openclaw opencode cursor gemini openai kimi hermes

# ── Default target ────────────────────────────────────────────────────────────

help:
	@echo "skill-writer $(VERSION) — development helpers"
	@echo ""
	@echo "  lint                     Run shellcheck on all install scripts"
	@echo "  validate                 Dry-run every platform installer (smoke test)"
	@echo "  check-version            Verify version $(VERSION) is consistent across all platform files"
	@echo "  check-spec-compat        Validate frontmatter against agentskills.io v1.0 spec"
	@echo "  build-platforms          Regenerate 8 platform files from platforms.yaml (strict)"
	@echo "  build-platforms-check    Drift-check platform files vs platforms.yaml (migration mode)"
	@echo "  sign ARTIFACT=<path>     Ed25519-sign a release artifact"
	@echo "  verify ARTIFACT=<path>   Verify Ed25519 signature"
	@echo "  eval-trigger             Real trigger-accuracy eval (needs ANTHROPIC_API_KEY)"
	@echo "  optimize-description     Iterative description optimizer (needs ANTHROPIC_API_KEY)"
	@echo "  emit-spec-pure           Emit skill to agentskills.io v1.0 spec-pure layout"
	@echo "  check-platform-sync      Diff all platform skill files against claude/skill-writer.md"
	@echo ""
	@echo "  ── v3.5.1 evolutionary & statistical tools (need ANTHROPIC_API_KEY) ──"
	@echo "  gepa-optimize ARGS=...   GEPA reflective evolutionary optimizer (S17)"
	@echo "                           Example: make gepa-optimize ARGS='--skill my-skill.md --rounds 10'"
	@echo "  multi-eval ARGS=...      Statistical multi-run EVALUATE w/ CI (S18)"
	@echo "                           Example: make multi-eval ARGS='--skill my-skill.md --runs 3'"
	@echo "  aggregate ARGS=...       AGGREGATE collective evolution pipeline"
	@echo "                           Example: make aggregate ARGS='--artifacts-dir artifacts/'"
	@echo "  drift-check ARGS=...     Monitor LEAN drift vs certified baseline"
	@echo "                           Example: make drift-check ARGS='--skill my-skill.md'"
	@echo ""
	@echo "  ── UTE GitHub Gist backend (need GITHUB_TOKEN) ──────────────────────"
	@echo "  ute-init SKILL=name LEAN=N  Initialize Gist state for a skill"
	@echo "  ute-record SKILL=name       Record one invocation"
	@echo "  ute-status SKILL=name       Show state + cadence events"
	@echo ""
	@echo "  install                  Auto-detect installed platforms and install"
	@echo "  install-all              Install to all 8 platforms"
	@echo "  ci                       Full local CI (lint + validate + version + spec-compat + build-check + platform-sync)"

# ── Lint ──────────────────────────────────────────────────────────────────────

lint:
	@echo "==> shellcheck"
	@bash scripts/lint.sh

# ── Validate (dry-run all installers) ────────────────────────────────────────

validate:
	@echo "==> dry-run validation"
	@bash scripts/validate.sh

# ── Version consistency check ─────────────────────────────────────────────────

check-version:
	@echo "==> version consistency check (expected: $(VERSION))"
	@python3 scripts/check-version.py "$(VERSION)"

# ── Platform sync check ──────────────────────────────────────────────────────

check-platform-sync:
	@echo "==> platform sync check (canonical: claude/skill-writer.md)"
	@python3 scripts/build-platforms.py --check

# ── agentskills.io spec compatibility (v3.5.0+) ───────────────────────────────

check-spec-compat:
	@echo "==> agentskills.io v1.0 frontmatter validation"
	@python3 scripts/check-spec-compat.py

# ── Single-source platform build (v3.5.0+) ────────────────────────────────────

build-platforms:
	@echo "==> build all platform files from platforms.yaml (strict)"
	@python3 scripts/build-platforms.py

build-platforms-check:
	@echo "==> drift-check platform files vs platforms.yaml (migration mode)"
	@python3 scripts/build-platforms.py --check-warn

# ── Ed25519 release signing (v3.5.0+) ─────────────────────────────────────────

sign:
	@if [ -z "$(ARTIFACT)" ]; then \
		echo "usage: make sign ARTIFACT=<path>"; exit 1; \
	fi
	@bash scripts/sign-release.sh "$(ARTIFACT)"

verify:
	@if [ -z "$(ARTIFACT)" ]; then \
		echo "usage: make verify ARTIFACT=<path>"; exit 1; \
	fi
	@bash scripts/verify-signature.sh "$(ARTIFACT)"

# ── Real eval pipeline (matches Anthropic skill-creator design) ──────────────

eval-trigger:
	@echo "==> real trigger-accuracy eval"
	@python3 scripts/run_trigger_eval.py $(ARGS)

optimize-description:
	@echo "==> iterative description optimizer"
	@python3 scripts/optimize_description.py $(ARGS)

# ── v3.5.1 Evolutionary & statistical tools ──────────────────────────────────

gepa-optimize:
	@echo "==> GEPA reflective evolutionary optimizer (S17)"
	@python3 scripts/run_gepa_optimize.py $(ARGS)

multi-eval:
	@echo "==> statistical multi-run EVALUATE (S18)"
	@python3 scripts/run_multi_eval.py $(ARGS)

aggregate:
	@echo "==> AGGREGATE collective evolution pipeline"
	@python3 scripts/run_aggregate.py $(ARGS)

drift-check:
	@echo "==> skill health drift check"
	@python3 scripts/monitor_skill_drift.py $(ARGS)

# ── gRaSP skill composition pipeline ─────────────────────────────────────────

grasp-compose:
	@echo "==> gRaSP 4-stage skill composition pipeline"
	@if [ -z "$(OBJECTIVE)" ]; then \
		echo "usage: make grasp-compose OBJECTIVE=\"<task>\" [SKILLS_DIR=<dir>] [SKILLS=<file...>] [ARGS=...]"; \
		echo "  OBJECTIVE   task description for skill selection (required)"; \
		echo "  SKILLS_DIR  directory of SKILL.md files (default: ~/.claude/skills/)"; \
		echo "  SKILLS      space-separated list of specific skill files"; \
		echo "  ARGS        extra flags: --dry-run, --json, --out DIR, --model MODEL"; \
		exit 1; \
	fi
	@python3 scripts/run_grasp_compose.py \
		$(if $(SKILLS_DIR),--skills-dir "$(SKILLS_DIR)",) \
		$(if $(SKILLS),--skills $(SKILLS),) \
		--objective "$(OBJECTIVE)" \
		$(ARGS)

# ── UTE GitHub Gist backend ──────────────────────────────────────────────────

ute-init:
	@if [ -z "$(SKILL)" ]; then echo "usage: make ute-init SKILL=<name> [LEAN=<score>]"; exit 1; fi
	@python3 scripts/ute_gist_backend.py init --skill "$(SKILL)" $(if $(LEAN),--lean-score $(LEAN),)

ute-record:
	@if [ -z "$(SKILL)" ]; then echo "usage: make ute-record SKILL=<name>"; exit 1; fi
	@python3 scripts/ute_gist_backend.py record --skill "$(SKILL)"

ute-status:
	@if [ -z "$(SKILL)" ]; then echo "usage: make ute-status SKILL=<name>"; exit 1; fi
	@python3 scripts/ute_gist_backend.py status --skill "$(SKILL)"

# ── Spec-pure emission (agentskills.io v1.0 conformance) ──────────────────────

emit-spec-pure:
	@if [ -z "$(SKILL)" ]; then \
		echo "usage: make emit-spec-pure SKILL=<path> OUT=<path> [STATE=<path>]"; exit 1; \
	fi
	@python3 scripts/emit_spec_pure.py "$(SKILL)" --out "$(OUT)" $(if $(STATE),--state-out "$(STATE)",)

# ── Install ───────────────────────────────────────────────────────────────────

install:
	@bash install.sh

install-all:
	@bash install.sh --all

# ── Full local CI ─────────────────────────────────────────────────────────────

ci: lint validate check-version check-spec-compat build-platforms-check check-platform-sync
	@echo ""
	@echo "  ✓ all CI checks passed"
