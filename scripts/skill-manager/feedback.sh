#!/bin/bash
set -eo pipefail

SKILL_DIR="${SKILL_DIR:-/Users/lucas/.agents/skills/skill-manager}"
METRICS_FILE="$SKILL_DIR/metrics.json"
LOG_DIR="${LOG_DIR:-$HOME/.opencode/logs}"
ALERT_THRESHOLD=8.0
MIN_INVOCATIONS_FOR_ALERT=5

mkdir -p "$SKILL_DIR"

get_expected_mode() {
    local query="$1"
    local first_verb
    first_verb=$(echo "$query" | awk '{print tolower($1)}')
    
    case "$first_verb" in
        write|create|make|build|develop|generate) echo "CREATE" ;;
        evaluate|test|certify|score|assess|audit|review) echo "EVALUATE" ;;
        restore|repair|recover|fix) echo "RESTORE" ;;
        optimize|tune|autotune|boost) echo "TUNE" ;;
        *) echo "UNKNOWN" ;;
    esac
}

init_metrics() {
    if [[ ! -f "$METRICS_FILE" ]]; then
        cat > "$METRICS_FILE" << 'EOF'
{
  "version": "1.0",
  "last_updated": null,
  "trigger_accuracy": {"total": 0, "correct": 0, "rate": 0.0, "history": []},
  "user_satisfaction": {"total": 0, "positive": 0, "rate": 0.0, "history": []},
  "error_rate": {"total": 0, "errors": 0, "rate": 0.0, "history": []},
  "daily_scores": [],
  "alerts": []
}
EOF
    fi
}

parse_invocation_log() {
    local log_file="$1"
    local -n ref_total=$2
    local -n ref_correct=$3
    local -n ref_history=$4
    
    if [[ ! -f "$log_file" ]]; then
        return 1
    fi
    
    while IFS= read -r line; do
        local timestamp query actual_mode expected_mode
        timestamp=$(echo "$line" | jq -r '.timestamp // empty' 2>/dev/null)
        query=$(echo "$line" | jq -r '.query // empty' 2>/dev/null)
        actual_mode=$(echo "$line" | jq -r '.mode // empty' 2>/dev/null)
        
        if [[ -z "$query" || -z "$actual_mode" || "$actual_mode" == "null" ]]; then
            continue
        fi
        
        expected_mode=$(get_expected_mode "$query")
        
        ((ref_total++))
        local correct_json="false"
        if [[ "$expected_mode" == "$actual_mode" ]]; then
            correct_json="true"
            ((ref_correct++))
        fi
        ref_history+=("{\"timestamp\":\"$timestamp\",\"query\":\"${query:0:50}\",\"expected\":\"$expected_mode\",\"actual\":\"$actual_mode\",\"correct\":$correct_json}")
    done < <(jq -c '.' "$log_file" 2>/dev/null)
}

parse_satisfaction_log() {
    local log_file="$1"
    local -n ref_total=$2
    local -n ref_positive=$3
    local -n ref_history=$4
    
    if [[ ! -f "$log_file" ]]; then
        return 1
    fi
    
    while IFS= read -r line; do
        local timestamp rating
        timestamp=$(echo "$line" | jq -r '.timestamp // empty' 2>/dev/null)
        rating=$(echo "$line" | jq -r '.rating // empty' 2>/dev/null)
        
        if [[ -z "$timestamp" || -z "$rating" || "$rating" == "null" ]]; then
            continue
        fi
        
        ((ref_total++))
        ref_history+=("{\"timestamp\":\"$timestamp\",\"rating\":\"$rating\"}")
        
        if [[ "$rating" == "up" || "$rating" == "positive" || "$rating" == "1" || "$rating" == "true" ]]; then
            ((ref_positive++))
        fi
    done < <(jq -c '.' "$log_file" 2>/dev/null)
}

parse_error_log() {
    local log_file="$1"
    local -n ref_total=$2
    local -n ref_errors=$3
    local -n ref_history=$4
    
    if [[ ! -f "$log_file" ]]; then
        return 1
    fi
    
    while IFS= read -r line; do
        local timestamp error_type message
        timestamp=$(echo "$line" | jq -r '.timestamp // empty' 2>/dev/null)
        error_type=$(echo "$line" | jq -r '.error_type // empty' 2>/dev/null)
        
        if [[ -z "$timestamp" || -z "$error_type" || "$error_type" == "null" ]]; then
            continue
        fi
        
        ((ref_total++))
        ref_history+=("{\"timestamp\":\"$timestamp\",\"error_type\":\"$error_type\"}")
        ((ref_errors++))
    done < <(jq -c '.' "$log_file" 2>/dev/null)
}

calculate_trigger_accuracy() {
    local total="$1"
    local correct="$2"
    if [[ "$total" -eq 0 ]]; then
        echo "0.0"
    else
        echo "scale=2; ($correct * 100) / $total" | bc
    fi
}

calculate_satisfaction() {
    local total="$1"
    local positive="$2"
    if [[ "$total" -eq 0 ]]; then
        echo "0.0"
    else
        echo "scale=2; ($positive * 100) / $total" | bc
    fi
}

calculate_error_rate() {
    local total="$1"
    local errors="$2"
    if [[ "$total" -eq 0 ]]; then
        echo "0.0"
    else
        echo "scale=2; ($errors * 100) / $total" | bc
    fi
}

check_alerts() {
    local trigger_acc="$1"
    local satisfaction="$2"
    local error_rate="$3"
    local total_invocations="$4"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    if [[ "$total_invocations" -lt "$MIN_INVOCATIONS_FOR_ALERT" ]]; then
        return 1
    fi
    
    local alerts=""
    
    if (( $(echo "$trigger_acc < $ALERT_THRESHOLD" | bc -l) )); then
        alerts+=$(printf '[{"timestamp":"%s","metric":"trigger_accuracy","value":%s,"threshold":%s,"severity":"HIGH"}]' "$timestamp" "$trigger_acc" "$ALERT_THRESHOLD")
    fi
    
    if (( $(echo "$satisfaction < $ALERT_THRESHOLD" | bc -l) )); then
        alerts+=$(printf '[{"timestamp":"%s","metric":"user_satisfaction","value":%s,"threshold":%s,"severity":"HIGH"}]' "$timestamp" "$satisfaction" "$ALERT_THRESHOLD")
    fi
    
    if (( $(echo "$error_rate > $(echo "100 - $ALERT_THRESHOLD" | bc)" | bc -l) )); then
        alerts+=$(printf '[{"timestamp":"%s","metric":"error_rate","value":%s,"threshold":%s,"severity":"HIGH"}]' "$timestamp" "$error_rate" "$ALERT_THRESHOLD")
    fi
    
    if [[ -n "$alerts" ]]; then
        echo "[${alerts}]"
        return 0
    fi
    return 1
}

update_metrics_json() {
    local trigger_total="$1"
    local trigger_correct="$2"
    local trigger_history="$3"
    local sat_total="$4"
    local sat_positive="$5"
    local sat_history="$6"
    local err_total="$7"
    local err_count="$8"
    local err_history="$9"
    
    local trigger_acc=$(calculate_trigger_accuracy "$trigger_total" "$trigger_correct")
    local satisfaction=$(calculate_satisfaction "$sat_total" "$sat_positive")
    local error_rate=$(calculate_error_rate "$err_total" "$err_count")
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local trigger_hist_json="${trigger_history:-[]}"
    local sat_hist_json="${sat_history:-[]}"
    local err_hist_json="${err_history:-[]}"
    
    cat > "$METRICS_FILE" << EOF
{
  "version": "1.0",
  "last_updated": "$timestamp",
  "trigger_accuracy": {
    "total": $trigger_total,
    "correct": $trigger_correct,
    "rate": $trigger_acc,
    "history": $trigger_hist_json
  },
  "user_satisfaction": {
    "total": $sat_total,
    "positive": $sat_positive,
    "rate": $satisfaction,
    "history": $sat_hist_json
  },
  "error_rate": {
    "total": $err_total,
    "errors": $err_count,
    "rate": $error_rate,
    "history": $err_hist_json
  },
  "daily_scores": [
    {"date": "$timestamp", "trigger_accuracy": $trigger_acc, "satisfaction": $satisfaction, "error_rate": $error_rate}
  ],
  "alerts": []
}
EOF
}

main() {
    init_metrics
    
    local trigger_total=0 trigger_correct=0
    local sat_total=0 sat_positive=0
    local err_total=0 err_count=0
    local trigger_history="" sat_history="" err_history=""
    
    local invocation_log="$LOG_DIR/invocations.jsonl"
    local satisfaction_log="$LOG_DIR/satisfaction.jsonl"
    local error_log="$LOG_DIR/errors.jsonl"
    
    if [[ -d "$LOG_DIR" ]]; then
        parse_invocation_log "$invocation_log" trigger_total trigger_correct trigger_history
        parse_satisfaction_log "$satisfaction_log" sat_total sat_positive sat_history
        parse_error_log "$error_log" err_total err_count err_history
        
        for log_file in "$LOG_DIR"/*.log; do
            if [[ -f "$log_file" ]]; then
                while IFS= read -r line; do
                    if [[ "$line" =~ skill.manager.*mode ]]; then
                        if [[ "$line" =~ mode.*[\'\"]?([A-Z]+) ]]; then
                            local ts
                            ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                            local mode="${BASH_REMATCH[1]}"
                            ((trigger_total++))
                            trigger_history="${trigger_history:+$trigger_history,}{\"timestamp\":\"$ts\",\"mode\":\"$mode\"}"
                        fi
                    fi
                    
                    if [[ "$line" =~ thumbs.up ]] || [[ "$line" =~ positive ]]; then
                        local ts
                        ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                        ((sat_total++))
                        ((sat_positive++))
                        sat_history="${sat_history:+$sat_history,}{\"timestamp\":\"$ts\",\"rating\":\"up\"}"
                    elif [[ "$line" =~ thumbs.down ]] || [[ "$line" =~ negative ]]; then
                        local ts
                        ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                        ((sat_total++))
                        sat_history="${sat_history:+$sat_history,}{\"timestamp\":\"$ts\",\"rating\":\"down\"}"
                    fi
                    
                    if [[ "$line" =~ error || "$line" =~ exception || "$line" =~ fail ]]; then
                        local ts
                        ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                        ((err_total++))
                        ((err_count++))
                        err_history="${err_history:+$err_history,}{\"timestamp\":\"$ts\",\"error_type\":\"log_detected\"}"
                    fi
                done < "$log_file"
            fi
        done
    fi
    
    local trigger_acc=$(calculate_trigger_accuracy "$trigger_total" "$trigger_correct")
    local satisfaction=$(calculate_satisfaction "$sat_total" "$sat_positive")
    local error_rate=$(calculate_error_rate "$err_total" "$err_count")
    
    update_metrics_json \
        "$trigger_total" "$trigger_correct" "$trigger_history" \
        "$sat_total" "$sat_positive" "$sat_history" \
        "$err_total" "$err_count" "$err_history"
    
    echo "=== Production Feedback Metrics ==="
    echo "Trigger Accuracy: ${trigger_acc}% (${trigger_correct}/${trigger_total})"
    echo "User Satisfaction: ${satisfaction}% (${sat_positive}/${sat_total})"
    echo "Error Rate: ${error_rate}% (${err_count}/${err_total})"
    
    local has_alerts=false
    local alert_output
    if alert_output=$(check_alerts "$trigger_acc" "$satisfaction" "$error_rate" "$trigger_total"); then
        has_alerts=true
        echo ""
        echo "⚠️  ALERTS TRIGGERED:"
        echo "$alert_output" | jq -r '.[] | "  - \(.metric): \(.value)% (threshold: \(.threshold)%)"'
        
        local temp_alerts
        temp_alerts=$(mktemp)
        jq --argjson alerts "$alert_output" '.alerts = $alerts | .last_updated = "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"' "$METRICS_FILE" > "$temp_alerts" && mv "$temp_alerts" "$METRICS_FILE"
    fi
    
    if [[ "$has_alerts" == "false" ]]; then
        echo ""
        echo "✓ All metrics above threshold ($ALERT_THRESHOLD%) or insufficient data"
    fi
    
    echo ""
    echo "Metrics saved to: $METRICS_FILE"
}

main "$@"
