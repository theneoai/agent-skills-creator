# Makefile — skill-writer development helpers
#
# Targets:
#   make help          Show this help
#   make lint          Run shellcheck on all install scripts
#   make validate      Dry-run all platform installers
#   make check-version Verify version consistency across all platform files
#   make install       Auto-detect and install to local platforms
#   make install-all   Install to all 8 platforms
#   make ci            Run lint + validate + check-version (full local CI)

.PHONY: help lint validate check-version install install-all ci

VERSION := $(shell cat VERSION)
PLATFORMS := claude openclaw opencode cursor gemini openai kimi hermes

# ── Default target ────────────────────────────────────────────────────────────

help:
	@echo "skill-writer $(VERSION) — development helpers"
	@echo ""
	@echo "  lint           Run shellcheck on all install scripts"
	@echo "  validate       Dry-run every platform installer (smoke test)"
	@echo "  check-version  Verify version $(VERSION) is consistent across all platform files"
	@echo "  install        Auto-detect installed platforms and install"
	@echo "  install-all    Install to all 8 platforms"
	@echo "  ci             Full local CI: lint + validate + check-version"

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

# ── Install ───────────────────────────────────────────────────────────────────

install:
	@bash install.sh

install-all:
	@bash install.sh --all

# ── Full local CI ─────────────────────────────────────────────────────────────

ci: lint validate check-version
	@echo ""
	@echo "  ✓ all CI checks passed"
