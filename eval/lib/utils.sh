#!/usr/bin/env bash
set -euo pipefail

check_dependencies() {
    local missing=()
    for cmd in bc jq grep awk; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing[*]}" >&2
        return 1
    fi
    return 0
}

parse_yaml_frontmatter() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    
    awk '/^---/{
        if(!in_yaml){
            in_yaml=1
            next
        }else{
            in_yaml=0
            exit
        }
    }
    in_yaml{
        print
    }' "$file"
}

count_lines() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "0"
        return 1
    fi
    wc -l < "$file" | awk '{print $1}'
}

extract_trigger_section() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "" >&2
        return 1
    fi
    
    awk '/^##?\s*[Tt]rigger/,/^##?\s*[A-Z]/{
        if(/^##?\s*[Tt]rigger/){next}
        if(/^##?\s*[A-Z]/){exit}
        print
    }' "$file" | sed '/^$/d'
}

run_with_timeout() {
    local timeout="$1"
    shift
    local cmd=("$@")
    
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout" "${cmd[@]}"
    else
        (
            "$cmd[@]" &
        local pid=$!
        (
            sleep "$timeout"
            kill -9 $pid 2>/dev/null
        ) &
        local timer=$!
        wait $pid 2>/dev/null
        local status=$?
        kill -9 $timer 2>/dev/null
        return $status
        )
    fi
}

calculate_percentage() {
    local numerator="$1"
    local denominator="$2"
    if [[ "$denominator" -eq 0 ]]; then
        echo "0"
        return 1
    fi
    echo "scale=2; ($numerator / $denominator) * 100" | bc
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/constants.sh"
fi
