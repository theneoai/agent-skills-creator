# Threshold constants for 1000pts evaluation system

# Guard against re-sourcing
if [[ -n "${_CONSTANTS_SOURCED:-}" ]]; then
    return 0
fi
export _CONSTANTS_SOURCED=1

# Core metrics thresholds
readonly F1_THRESHOLD=0.90
readonly MRR_THRESHOLD=0.85
readonly TRIGGER_ACCURACY_THRESHOLD=0.99

# Score thresholds (1000pts system)
readonly TEXT_SCORE_MIN=280  # 350pts system, 80%
readonly RUNTIME_SCORE_MIN=360  # 450pts system, 80%
readonly VARIANCE_MAX=20

# Certification tiers (1000pts)
readonly PLATINUM_MIN=950
readonly GOLD_MIN=900
readonly SILVER_MIN=800
readonly BRONZE_MIN=700

# Parse & Validate (100pts)
readonly PARSE_YAML_FRONT=30
readonly PARSE_THREE_SECTIONS=30
readonly PARSE_TRIGGER_LIST=25
readonly PARSE_NO_PLACEHOLDERS=15

# Text Score (350pts)
readonly TEXT_SYSTEM_PROMPT=70
readonly TEXT_DOMAIN_KNOWLEDGE=70
readonly TEXT_WORKFLOW=70
readonly TEXT_ERROR_HANDLING=55
readonly TEXT_EXAMPLES=55
readonly TEXT_METADATA=30

# Runtime Score (450pts)
readonly RUNTIME_IDENTITY=80
readonly RUNTIME_FRAMEWORK=70
readonly RUNTIME_ACTIONABILITY=70
readonly RUNTIME_KNOWLEDGE=50
readonly RUNTIME_CONVERSATION=50
readonly RUNTIME_TRACE=50
readonly RUNTIME_LONG_DOC=30
readonly RUNTIME_MULTI_AGENT=25
readonly RUNTIME_TRIGGER=25

# Certify & Report (100pts)
readonly CERTIFY_VARIANCE=40
readonly CERTIFY_TIER=30
readonly CERTIFY_REPORT=20
readonly CERTIFY_SECURITY=10

# Security CWE checks
readonly CWE_798_PATTERN='(sk-|api[-_]?key|password|token|secret|credential)'
readonly CWE_89_PATTERN='(eval\(|exec\(|system\()'
readonly CWE_78_PATTERN='(eval|exec|system|popen)'
readonly CWE_22_PATTERN='(\.\.\/|\.\.\\|%00)'

# Evaluation timeouts (seconds)
readonly FAST_TIMEOUT=180  # 3 minutes
readonly FULL_TIMEOUT=600  # 10 minutes

# Colors (non-readonly to allow CI mode override)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
