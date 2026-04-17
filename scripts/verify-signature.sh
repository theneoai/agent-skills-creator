#!/usr/bin/env bash
# scripts/verify-signature.sh — Verify Ed25519 signatures on release artifacts.
#
# Usage:
#   scripts/verify-signature.sh [--trust-store PATH] FILE [FILE...]
#
#   For each FILE, expects:
#     FILE.sig          — base64 Ed25519 signature (88 chars)
#     FILE.pubkey       — base64 Ed25519 public key (44 chars)
#     FILE.provenance   — JSON metadata (optional; rich verification)
#
#   --trust-store PATH  : directory of allowlisted pubkeys (one .pubkey per key_id).
#                         If provided, the signer's pubkey MUST match one of these.
#                         Default: $SKILL_WRITER_TRUST_STORE, else skip trust check.
#
# Exit codes:
#   0  every file verified
#   1  at least one file failed verification
#   2  missing signature artifact or broken tool environment

set -euo pipefail

TRUST_STORE="${SKILL_WRITER_TRUST_STORE:-}"
FILES=()

info()    { echo "  $*"; }
success() { echo "  ✓ $*"; }
warn()    { echo "  ⚠ $*" >&2; }
err()     { echo "  ✗ $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --trust-store) TRUST_STORE="${2:?--trust-store requires a path}"; shift 2 ;;
    --trust-store=*) TRUST_STORE="${1#*=}"; shift ;;
    -h|--help)
      sed -n 's/^# \{0,1\}//p' "$0" | head -20
      exit 0 ;;
    *) FILES+=("$1"); shift ;;
  esac
done

if [[ ${#FILES[@]} -eq 0 ]]; then
  err "no files provided"
  exit 2
fi

if ! python3 -c "from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey" 2>/dev/null; then
  err "python3 cryptography backend required for signature verification"
  err "install: pip install cryptography"
  exit 2
fi

RESULT=0
for f in "${FILES[@]}"; do
  if [[ ! -f "${f}.sig" || ! -f "${f}.pubkey" ]]; then
    err "$f: missing .sig or .pubkey"
    RESULT=1
    continue
  fi

  if ! python3 - "$f" "$TRUST_STORE" <<'PY'; then
import base64, hashlib, json, sys
from pathlib import Path
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
from cryptography.exceptions import InvalidSignature

target = Path(sys.argv[1])
trust_store = sys.argv[2]

data = target.read_bytes()
sig = base64.b64decode(target.with_suffix(target.suffix + ".sig").read_text().strip())
pubkey_b64 = target.with_suffix(target.suffix + ".pubkey").read_text().strip()
pubkey_raw = base64.b64decode(pubkey_b64)

try:
    pub = Ed25519PublicKey.from_public_bytes(pubkey_raw)
    pub.verify(sig, data)
except InvalidSignature:
    print(f"  ✗ {target.name}: INVALID signature", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"  ✗ {target.name}: verification error: {e}", file=sys.stderr)
    sys.exit(1)

key_id = hashlib.sha256(pubkey_raw).hexdigest()[:16]

# Trust-store check (opt-in)
if trust_store:
    ts = Path(trust_store)
    trusted = False
    if ts.is_dir():
        for kf in ts.glob("*.pubkey"):
            if kf.read_text().strip() == pubkey_b64:
                trusted = True
                break
    if not trusted:
        print(f"  ✗ {target.name}: signer key {key_id} NOT in trust store {trust_store}",
              file=sys.stderr)
        sys.exit(1)
    trust_note = " (trusted)"
else:
    trust_note = " (TOFU: trust-on-first-use)"

# Provenance consistency
prov_path = target.with_suffix(target.suffix + ".provenance")
if prov_path.exists():
    prov = json.loads(prov_path.read_text())
    if prov.get("file_sha256") != hashlib.sha256(data).hexdigest():
        print(f"  ✗ {target.name}: provenance sha256 mismatch", file=sys.stderr)
        sys.exit(1)

print(f"  ✓ {target.name}: verified (key_id: {key_id}){trust_note}")
sys.exit(0)
PY
    RESULT=1
  fi
done

exit $RESULT
