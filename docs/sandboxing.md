# Running skills in a sandbox

> **Status**: v3.5.0 — reference configurations (Docker, Firejail, macOS seatbelt).
> **Prior art**: `docs/supply-chain-security.md` (signature verification) — signing
>   proves authorship, sandboxing contains blast radius. You want both.

---

## §1  Why sandbox

Signature verification (Ed25519 in v3.5.0) confirms a skill came from a trusted
author. It does **not** confirm the skill is safe:

- Authors make mistakes (a skill may have accidental `rm -rf` or exfil paths)
- Upstream dependencies may be compromised (supply-chain attack beyond author)
- Static CWE/OWASP scanners miss novel patterns (especially LLM-generated code)
- Prompt injection in tool outputs can re-interpret instructions

Academic surveys (HuggingFace 2601.10338) report **26.1% of sampled agent skills
contain at least one vulnerability** across four categories: prompt injection,
data exfiltration, privilege escalation, supply-chain risks. Assume every
third-party skill is potentially dangerous; run with least privilege.

---

## §2  Threat model per sandbox tier

| Tier | What it protects against | What it costs |
|------|--------------------------|---|
| T0 — None               | nothing | fastest, most convenient |
| T1 — Process isolation  | accidental file writes outside workspace | Firejail / `bwrap` / macOS seatbelt |
| T2 — Container          | network egress, device access, capability abuse | Docker / Podman |
| T3 — VM                 | kernel bugs, container escapes | Lima / microVM |
| T4 — Airgap             | targeted exfiltration via side channels | physical isolation |

skill-writer recommends **T2 (container) as the production default** for
third-party skills; T1 for your own skills in development.

---

## §3  Docker reference config (T2)

```bash
# Build a minimal runner image (one-time)
cat > Dockerfile.skill-sandbox <<'EOF'
FROM python:3.12-alpine
RUN adduser -D -u 1000 skilluser
WORKDIR /workspace
USER skilluser
CMD ["python", "-c", "import sys; print('sandbox ready')"]
EOF
docker build -t skill-sandbox -f Dockerfile.skill-sandbox .

# Run a skill in the sandbox
docker run --rm -it \
    --network none \
    --read-only \
    --tmpfs /tmp:rw,noexec,nosuid,size=64m \
    --cap-drop=ALL \
    --security-opt=no-new-privileges \
    --pids-limit=64 \
    --memory=512m --memory-swap=512m \
    --cpus=0.5 \
    -v "$(pwd)/skill-workspace:/workspace:ro" \
    -v "$(pwd)/skill-output:/workspace/out:rw" \
    skill-sandbox \
    "$@"
```

### Flag rationale

| Flag | Why |
|------|---|
| `--network none`                 | Blocks outbound exfiltration |
| `--read-only`                    | Prevents persistent tampering |
| `--tmpfs /tmp:rw,noexec,nosuid`  | Ephemeral scratch space, no binary exec |
| `--cap-drop=ALL`                 | No Linux capabilities (no raw sockets, ptrace, etc.) |
| `--security-opt=no-new-privileges` | Prevent setuid/setgid escalation |
| `--pids-limit=64`                | Caps fork bombs |
| `--memory=512m --memory-swap=512m` | OOM kills hang jobs cheaply |
| `--cpus=0.5`                     | Mitigates DoS-by-compute |
| workspace read-only, output read-write | Contains writes to a known directory |

### Skill-writer integration

```bash
# Wrapper that invokes a skill inside the sandbox
scripts/run-sandboxed.sh skill-writer evaluate examples/00-starter/skill.md
```

(`scripts/run-sandboxed.sh` is a `[ROADMAP v3.6.0]` helper; manual `docker run`
is the supported path today.)

---

## §4  Firejail reference (T1, Linux)

For development when you need network but not elevated privileges:

```bash
firejail \
    --private=/tmp/skill-ws \
    --private-dev --private-tmp \
    --net=none \
    --seccomp \
    --caps.drop=all \
    --noroot --noprofile \
    -- bash -lc 'python3 your-skill-runner.py'
```

---

## §5  macOS seatbelt (T1, macOS)

```bash
sandbox-exec -f skill.sb \
    bash -lc 'python3 your-skill-runner.py'

# skill.sb (sandbox profile)
cat > skill.sb <<'EOF'
(version 1)
(deny default)
(allow process*)
(allow file-read* (subpath "/Users/you/skill-workspace"))
(allow file-write* (subpath "/Users/you/skill-workspace/out"))
(deny network*)
EOF
```

---

## §6  Verifying the sandbox works

Before trusting a sandbox, verify escape attempts fail:

```bash
# 1. Network egress should be blocked
docker run --rm --network none skill-sandbox \
    python -c "import urllib.request; urllib.request.urlopen('https://example.com')"
# Expected: URLError

# 2. Root filesystem should be read-only
docker run --rm --read-only skill-sandbox \
    python -c "open('/etc/root-marker', 'w').write('pwn')"
# Expected: PermissionError (Read-only file system)

# 3. Capabilities should be dropped
docker run --rm --cap-drop=ALL skill-sandbox \
    python -c "import os; os.chroot('/')"
# Expected: PermissionError (Operation not permitted)
```

If any of these succeed, your sandbox is misconfigured.

---

## §7  CI integration

GitHub Actions example — runs all `examples/*/skill.md` in the sandbox:

```yaml
# .github/workflows/sandbox-examples.yml (reference)
name: sandbox-examples
on: [pull_request]
jobs:
  sandbox:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build sandbox image
        run: docker build -t skill-sandbox -f Dockerfile.skill-sandbox .
      - name: Run each example
        run: |
          for d in examples/*/; do
            docker run --rm --network none --read-only \
              --tmpfs /tmp --cap-drop=ALL \
              -v "$PWD/$d:/workspace:ro" skill-sandbox \
              python -c "print('example ok: $d')"
          done
```

---

## §8  Further reading

- Docker security bench: <https://github.com/docker/docker-bench-security>
- CIS Docker Benchmark
- Anthropic Claude Code sandboxing docs
- OWASP Agentic Top 10: <https://genai.owasp.org/llmrisk-agentic/>
