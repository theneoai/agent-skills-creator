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
# CWE-798: Hardcoded credentials - match real credential patterns only.
# Deliberately excludes generic uppercase env-var references like $HOME/$PATH
# which caused high false-positive rates. Only matches known credential shapes.
readonly CWE_798_PATTERN='(sk-[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|ghp_[a-zA-Z0-9]{36}|xox[baprs]-[0-9A-Za-z\-]{10,}|(api[-_]key|password|passwd|secret|credential)\s*=\s*["\x27][^"${\x27]{6,}["\x27])'
readonly CWE_89_PATTERN='(mysql|psql|sqlite3|mongosh|sqlcmd)\s+.*\$\{|sql\s*=.*\$\{|["'\''].*\$\w+|WHERE\s+\$\w+|SELECT\s+\$\w+|INSERT\s+INTO\s+\$\w+|UPDATE\s+\$\w+\s+SET|DELETE\s+FROM\s+\$\w+|--\s*\$\{|"\s*\.\s*\$\{|'\''\s*\.\s*\$\{)'
readonly CWE_78_PATTERN='(eval\s*\$\{|\$\(\s*\$.*|exec\s+\$\{|system\s+\$\{|popen\s*\$\{|`[^`]*\$\{[^`]*`|\beval\s+\$\(|\bexec\s+\$\(|\bsystem\s+\$\(|\bsh\s+-c.*\$\{|\bbash\s+-c.*\$\{)'
readonly CWE_22_PATTERN='(\.\.\/|\.\.\\|%00|/etc/passwd|/etc/shadow|\.\.\.\/|\.\.\\\.\\.)'
readonly CWE_306_PATTERN='(if\s+\[\s*-z\s+\$\w+\s*\]\s*;?\s*then\s*return|if\s+\[\s*-z\s+\$\w+\s*\]\s*;?\s*then\s*exit|auth[_-]?check|is[_-]?auth[_-]?enticated|check[_-]?auth|verify[_-]?creds?|validate[_-]?token?|require[_-]?auth)'
readonly CWE_862_PATTERN='(is[_-]?authorized|check[_-]?perm[_-]?s?|has[_-]?perm[_-]?s?|validate[_-]?role?|has[_-]?role?|require[_-]?role|check[_-]?ownership|is[_-]?owner)'

# Evaluation timeouts (seconds)
readonly FAST_TIMEOUT=180  # 3 minutes
readonly FULL_TIMEOUT=600  # 10 minutes

# Colors (non-readonly to allow CI mode override)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Evolution Engine constants
readonly CONVERGENCE_WINDOW=5
readonly CONVERGENCE_VARIANCE_THRESHOLD=0.5
readonly POSITIVE_LEARNING_WINDOW=10
readonly MIN_SUCCESS_RATE=0.7
readonly MIN_IMPROVEMENT_DELTA=0.5
readonly STUCK_ROUNDS_THRESHOLD=5
readonly EVOLUTION_TIMEOUT=300

# Lock timeouts
readonly SKILL_FILE_TIMEOUT=30

# Export constants for child processes
export F1_THRESHOLD MRR_THRESHOLD TRIGGER_ACCURACY_THRESHOLD
export TEXT_SCORE_MIN RUNTIME_SCORE_MIN VARIANCE_MAX
export PLATINUM_MIN GOLD_MIN SILVER_MIN BRONZE_MIN
export FAST_TIMEOUT FULL_TIMEOUT
export EVOLUTION_TIMEOUT SKILL_FILE_TIMEOUT
