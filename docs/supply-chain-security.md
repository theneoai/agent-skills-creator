# Supply-Chain Security for skill-writer

> **Status**: v3.5.0 (2026-04)
> **Scope**: How skill-writer artifacts are signed, distributed, and verified;
>   what consumers should check before installing.
> **Prior art**:
>   - `refs/security-patterns.md` — content-level CWE/OWASP scanning
>   - `refs/skill-registry.md` — registry schema
>   - This doc — transport- and author-level authenticity (NEW in v3.5.0)

---

## §1  Why we changed from SHA-256 to Ed25519 dual-layer signing

Through v3.4.x, skill-writer relied on **SHA-256 content hashes** for integrity
verification of pulled skills. Integrity ≠ authenticity:

- SHA-256 tells you "this file matches the bytes someone published"
- It does **not** tell you "those bytes came from who you think"

In 2026-Q1 the industry learned this lesson the hard way — the **OpenClaw malicious
skills incident** saw 1,184 confirmed malicious packages on ClawHub (~1 in 5 at
peak). Many were SHA-256-clean; the attack surface was publisher identity, not
content tampering.

**v3.5.0 adds Ed25519 signatures** in a **dual-layer** model inspired by the
agentskills.io security annex and sigstore's dual-signing pattern:

| Layer       | Signer               | Purpose |
|-------------|----------------------|---|
| Developer   | Skill author         | Proves "this author created this skill" |
| Registry    | Registry operator    | Proves "this registry reviewed and accepted it" |

Consumers MAY require either, both, or neither — trust policy is local.

---

## §2  Author workflow

```bash
# One-time: generate your signing key
openssl genpkey -algorithm Ed25519 -out ~/.config/skill-writer/signing.key
chmod 600 ~/.config/skill-writer/signing.key

# Publish your public key (e.g. in your GitHub profile, a .well-known URL, or
# an agentskills.io verified-author record)
openssl pkey -in ~/.config/skill-writer/signing.key -pubout -outform DER \
  | base64 > my-signing.pubkey

# Sign every release artifact
SIGNER="alice@example.com" scripts/sign-release.sh dist/*.md dist/*.mdc
```

Each signed artifact produces three sidecar files:

| File             | Purpose |
|------------------|---|
| `FILE.sig`       | Ed25519 signature over the file bytes (base64, 88 chars) |
| `FILE.pubkey`    | Signer's Ed25519 public key (base64, 44 chars) |
| `FILE.provenance`| JSON: signer, timestamp, file sha256, key_id, algo, sig, spec_version |

---

## §3  Consumer workflow

### Fast path — TOFU (Trust On First Use)

```bash
scripts/verify-signature.sh skill-writer-claude.md
# ✓ skill-writer-claude.md: verified (key_id: a7f…) (TOFU: trust-on-first-use)
```

This ONLY confirms the signature is mathematically valid, not that the signer
is trusted. Safe for local-only development; insufficient for production.

### Production path — Trust store

```bash
# Build a trust store by collecting pubkeys of authors you trust
mkdir -p ~/.config/skill-writer/trust-store
cp alice.pubkey ~/.config/skill-writer/trust-store/

export SKILL_WRITER_TRUST_STORE=~/.config/skill-writer/trust-store
scripts/verify-signature.sh skill-writer-claude.md
# ✓ skill-writer-claude.md: verified (key_id: a7f…) (trusted)
```

Signatures whose `pubkey` does not match any key in the trust store are **rejected**
with exit code 1.

### Registry path — Dual-layer verification

When pulling from a hosted registry, the `provenance.json` artifact carries
TWO signatures: developer + registry. Both must verify for `TRUSTED` status.

| Result                              | Trust tier  | Consumer policy           |
|-------------------------------------|-------------|---------------------------|
| Both signatures verify              | `TRUSTED`   | Install silently          |
| Only developer verifies             | `VERIFIED`  | Install with warning      |
| Only registry verifies              | `LOW_TRUST` | Install with confirmation |
| Neither verifies / missing          | `UNTRUSTED` | Block (refuse by default) |

(Integrated into `refs/skill-registry.md §11 trust-tier` semantics.)

---

## §4  Sandboxing recommendation

Signature verification proves authorship; it does NOT prove safety. A signed
skill from a trusted author can still have bugs, misconfigurations, or
compromised upstream dependencies. Run skills with least privilege:

```bash
# Docker-based sandbox (see docs/sandboxing.md for full guide)
docker run --rm -it \
  --network none --read-only --tmpfs /tmp \
  --cap-drop=ALL --security-opt=no-new-privileges \
  -v "$(pwd)/skill-workspace:/workspace:ro" \
  claude-sandbox claude --skill skill-writer
```

Key flags:
- `--network none` — no outbound network (blocks exfiltration)
- `--read-only --tmpfs /tmp` — writes only to ephemeral tmpfs
- `--cap-drop=ALL` — drop all Linux capabilities
- `--security-opt=no-new-privileges` — prevent setuid/setgid escalation

---

## §5  Threat model

What Ed25519 signing **does** protect against:
- Tampered downloads in transit (MitM on mirror)
- Tampered downloads at rest (compromised CDN edge)
- Impersonation of the author by a registry hijacker
- Silent replacement of a published skill (fresh upload detectable via key_id change)

What signing does **not** protect against:
- A compromised author's private key (rotation + revocation list needed)
- Supply chain compromise BEFORE signing (upstream skill → downstream author)
- Author publishing knowingly malicious content (policy, not crypto)
- Prompt-injection or data-exfiltration payloads inside the skill itself
  (covered by `refs/security-patterns.md` OWASP ASI scans)

---

## §6  Rotation and revocation

Planned for v3.6.0:

- `signers.json` at the registry — authoritative signer allowlist + revocation
- `keys/rotation.md` — key rotation protocol (overlap window, deprecated-after)
- Consumer-side revocation cache refreshed on INSTALL

Until then, revocation is manual: remove the pubkey from your trust store.

---

## §7  References

- Agent Skills Open Standard security annex: <https://agentskills.io/security>
- Sigstore / Cosign dual-layer model: <https://www.sigstore.dev/how-it-works>
- OpenClaw supply-chain incident write-up: <https://blog.pluto.security/p/clawing-out-the-skills-marketplace>
- Empirical study of agent-skill vulnerabilities (26.1% affected):
  <https://huggingface.co/papers/2601.10338>
- Formal analysis (arXiv 2603.00195): <https://arxiv.org/html/2603.00195v1>
