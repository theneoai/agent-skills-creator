#!/usr/bin/env bash
# scripts/sign-release.sh — Produce Ed25519 signatures for release artifacts.
#
# Background (v3.5.0):
#   In 2026-Q1 the OpenClaw malicious-skills incident (1,184 confirmed bad
#   packages on ClawHub) showed that SHA-256 integrity ≠ author authenticity.
#   Upstream guidance (agentskills.io security annex, cloud security vendors)
#   converged on Ed25519 with a *dual-layer* model: developer signature +
#   registry signature. This script produces the developer signature.
#
# Usage:
#   scripts/sign-release.sh [--key PATH] [FILE...]
#
#   If no FILE is given, signs every release artifact in dist/ matching
#     skill-writer-<platform>.md (and .mdc).
#
#   --key PATH : Ed25519 private key in PEM format. Default:
#                $SKILL_WRITER_SIGNING_KEY, then ~/.config/skill-writer/signing.key
#
# Output:
#   For each FILE, writes:
#     FILE.sig         (base64 Ed25519 signature, 88 chars)
#     FILE.pubkey      (base64 Ed25519 public key, 44 chars; copy of author key)
#     FILE.provenance  (JSON: {signer, signed_at, file_sha256, sig_algo, sig})
#
# Verification (consumers):
#   scripts/verify-signature.sh FILE
#
# NB: Requires Python 3.8+ with cryptography installed for key ops.
#     Falls back to OpenSSL CLI (LibreSSL 3.1+ or OpenSSL 1.1.1+) if Python
#     cryptography is unavailable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

KEY_PATH="${SKILL_WRITER_SIGNING_KEY:-$HOME/.config/skill-writer/signing.key}"
FILES=()

info()    { echo "  $*"; }
success() { echo "  ✓ $*"; }
warn()    { echo "  ⚠ $*" >&2; }
err()     { echo "  ✗ $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key) KEY_PATH="${2:?--key requires a path}"; shift 2 ;;
    --key=*) KEY_PATH="${1#*=}"; shift ;;
    -h|--help)
      sed -n 's/^# \{0,1\}//p' "$0" | head -30
      exit 0 ;;
    *) FILES+=("$1"); shift ;;
  esac
done

if [[ ${#FILES[@]} -eq 0 ]]; then
  if [[ -d "$ROOT/dist" ]]; then
    while IFS= read -r -d '' f; do FILES+=("$f"); done < <(
      find "$ROOT/dist" -maxdepth 1 \( -name "skill-writer-*.md" -o -name "skill-writer-*.mdc" \) -print0
    )
  fi
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  err "no files to sign (pass files as args or populate dist/)"
  exit 1
fi

if [[ ! -f "$KEY_PATH" ]]; then
  err "signing key not found: $KEY_PATH"
  err "generate one with: scripts/sign-release.sh --gen-key"
  err "(or set SKILL_WRITER_SIGNING_KEY to an existing Ed25519 PEM)"
  exit 1
fi

# ── Sign using Python (preferred) ────────────────────────────────────────────

if python3 -c "from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey" 2>/dev/null; then
  info "using Python cryptography backend"
  for f in "${FILES[@]}"; do
    python3 - "$KEY_PATH" "$f" <<'PY'
import base64, hashlib, json, sys, os, datetime
from pathlib import Path
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

key_path = Path(sys.argv[1])
target = Path(sys.argv[2])
priv = serialization.load_pem_private_key(key_path.read_bytes(), password=None)
if not isinstance(priv, Ed25519PrivateKey):
    print(f"  ✗ {key_path}: not an Ed25519 key", file=sys.stderr); sys.exit(2)

data = target.read_bytes()
sig = priv.sign(data)
pub_pem = priv.public_key().public_bytes(
    encoding=serialization.Encoding.Raw,
    format=serialization.PublicFormat.Raw,
)
sha256 = hashlib.sha256(data).hexdigest()

target.with_suffix(target.suffix + ".sig").write_text(base64.b64encode(sig).decode() + "\n")
target.with_suffix(target.suffix + ".pubkey").write_text(base64.b64encode(pub_pem).decode() + "\n")
provenance = {
    "signer": os.environ.get("SIGNER", "developer"),
    "signer_key_id": hashlib.sha256(pub_pem).hexdigest()[:16],
    "signed_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "file": str(target.name),
    "file_sha256": sha256,
    "sig_algo": "Ed25519",
    "sig": base64.b64encode(sig).decode(),
    "pubkey": base64.b64encode(pub_pem).decode(),
    "spec_version": "1.0",
}
target.with_suffix(target.suffix + ".provenance").write_text(
    json.dumps(provenance, indent=2) + "\n"
)
print(f"  ✓ signed {target.name}  (sha256: {sha256[:12]}…, key_id: {provenance['signer_key_id']})")
PY
  done
else
  # Fallback: OpenSSL CLI
  if ! command -v openssl >/dev/null; then
    err "neither 'python3 + cryptography' nor 'openssl' available — cannot sign"
    exit 1
  fi
  info "using openssl CLI fallback (limited metadata)"
  for f in "${FILES[@]}"; do
    sig_b64=$(openssl pkeyutl -sign -inkey "$KEY_PATH" -rawin -in "$f" | base64 | tr -d '\n')
    echo "$sig_b64" > "${f}.sig"
    success "signed $f  (.sig produced; no provenance metadata)"
  done
fi
