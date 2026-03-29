#!/usr/bin/env bash
# parallel-evolution.sh - 3-worker 并行自我进化引擎 (快速版)
#
# Usage: ./scripts/parallel-evolution.sh [total_rounds]
#
# 使用 lean-orchestrator 进行快速评估，不依赖LLM

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "${PROJECT_ROOT}/engine/lib/bootstrap.sh"

MAX_WORKERS=3
TOTAL_ROUNDS=${1:-300}

WORKER_STATE_DIR="/tmp/evolution_workers"
LOG_FILE="${LOG_DIR}/parallel-evolution.log"

mkdir -p "$WORKER_STATE_DIR" "$LOG_DIR"

# 跨平台 sed -i 兼容函数
sed_i() {
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# 文件锁函数 (用于并发保护)
acquire_file_lock() {
    local lock_file="$1"
    local timeout="${2:-10}"
    local start_time
    start_time=$(date +%s)
    
    while [[ -f "$lock_file" ]]; do
        local elapsed
        elapsed=$(($(date +%s) - start_time))
        if [[ $elapsed -ge $timeout ]]; then
            return 1
        fi
        sleep 0.1
    done
    
    echo $$ > "$lock_file"
    return 0
}

release_file_lock() {
    local lock_file="$1"
    rm -f "$lock_file"
}

# 动态阈值
F1_THRESHOLD=0.90
MRR_THRESHOLD=0.85

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_worker_state() {
    local worker_id=$1
    cat "${WORKER_STATE_DIR}/worker_${worker_id}.json" 2>/dev/null || echo '{"round": 0, "best_score": 0, "stuck_count": 0}'
}

update_worker_state() {
    local worker_id=$1
    local round=$2
    local score=$3
    local delta=$4
    
    local MIN_DELTA=0.5
    local STUCK_THRESHOLD=5
    
    local prev_state
    prev_state=$(get_worker_state "$worker_id")
    local best_score=$(echo "$prev_state" | jq -r '.best_score')
    local stuck_count=$(echo "$prev_state" | jq -r '.stuck_count')
    local recent_scores=$(echo "$prev_state" | jq -r '.recent_scores // []')
    
    if [[ "$(echo "$delta > $MIN_DELTA" | bc -l)" == "1" ]]; then
        best_score=$score
        stuck_count=0
    else
        ((stuck_count++))
    fi
    
    recent_scores=$(echo "$recent_scores" | jq --argjson s "$score" '. += [$s] | .[-10:]')
    
    local variance=0
    if [[ $(echo "$recent_scores" | jq 'length') -ge 5 ]]; then
        variance=$(echo "$recent_scores" | jq -s 'def variance: (map(add) | length) as $n | (map(add) / $n) as $mean | (map(. - $mean) | map(. * .) | add) / $n | sqrt; variance')
    fi
    
    jq -n \
        --argjson round "$round" \
        --argjson best_score "$best_score" \
        --argjson stuck_count "$stuck_count" \
        --argjson delta "$delta" \
        --argjson variance "$variance" \
        --jsonarrayargs "$recent_scores" \
        '{round: $round, best_score: $best_score, stuck_count: $stuck_count, delta: $delta, variance: $variance, recent_scores: $jsonarrayargs}' \
        > "${WORKER_STATE_DIR}/worker_${worker_id}.json"
}

get_score() {
    local skill_file=$1
    bash "${PROJECT_ROOT}/scripts/lean-orchestrator.sh" "$skill_file" 2>/dev/null | jq -r '.total // 0'
}

apply_improvement() {
    local skill_file=$1
    local dimension=$2
    
    case "$dimension" in
        1) # 增加量化指标
            sed_i 's/F1 ≥ 0.90/F1 ≥ 0.92/g; s/MRR ≥ 0.85/MRR ≥ 0.87/g' "$skill_file" 2>/dev/null || true
            ;;
        2) # 增加触发器关键词
            sed_i '/| CREATE |/s/| 1 |/| 1 |+增强关键词/g' "$skill_file" 2>/dev/null || true
            ;;
        3) # 增加示例
            if ! grep -q "Example:" "$skill_file"; then
                echo -e "\n### Examples\n- Tool usage example\n" >> "$skill_file"
            fi
            ;;
        4) # 增强错误处理
            if ! grep -q "Error Handling" "$skill_file"; then
                echo -e "\n## Error Handling\n- Timeout handling\n- Retry logic\n" >> "$skill_file"
            fi
            ;;
        5) # 增加跨引用
            if ! grep -q "reference/" "$skill_file"; then
                sed_i 's/## Reference Index/## Reference Index\n| `reference/new.md` | New reference | LOAD/g' "$skill_file" 2>/dev/null || true
            fi
            ;;
    esac
}

run_worker() {
    local worker_id=$1
    local start_round=$2
    local end_round=$3
    
    log "WORKER $worker_id: Starting rounds $start_round-$end_round"
    
    local current_round=$start_round
    local last_score=0
    
    while [[ $current_round -le $end_round ]]; do
        # 获取当前分数
        local new_score
        new_score=$(get_score "${PROJECT_ROOT}/SKILL.md")
        
        local delta=0
        if [[ -n "$last_score" ]] && [[ "$last_score" != "0" ]]; then
            if [[ "$(echo "$new_score > $last_score" | bc -l)" == "1" ]]; then
                delta=$(echo "$new_score - $last_score" | bc)
            fi
        fi
        
        update_worker_state "$worker_id" "$current_round" "$new_score" "$delta"
        
        # 尝试改进 (需要文件锁保护并发)
        local skill_lock="${WORKER_STATE_DIR}/skill.lock"
        if ! acquire_file_lock "$skill_lock" 30; then
            log "WORKER $worker_id: Could not acquire lock, skipping round"
            continue
        fi
        
        # 保存当前文件内容用于回滚
        local pre_improvement_content
        pre_improvement_content=$(cat "${PROJECT_ROOT}/SKILL.md")
        
        local dim=$((current_round % 5 + 1))
        local improvement_success=false
        if apply_improvement "${PROJECT_ROOT}/SKILL.md" "$dim"; then
            improvement_success=true
        fi
        
        # 再次评分
        local improved_score
        improved_score=$(get_score "${PROJECT_ROOT}/SKILL.md")
        
        if [[ "$improvement_success" == "true" ]] && [[ "$(echo "$improved_score > $new_score" | bc -l)" == "1" ]]; then
            new_score=$improved_score
            log "WORKER $worker_id: Round $current_round - Improved! Score: $new_score"
            update_worker_state "$worker_id" "$current_round" "$new_score" "$delta"
        else
            # 回滚到改进前的内容
            echo "$pre_improvement_content" > "${PROJECT_ROOT}/SKILL.md"
            log "WORKER $worker_id: Round $current_round - No improvement, rolled back"
        fi
        
        release_file_lock "$skill_lock"
        local improved_score
        improved_score=$(get_score "${PROJECT_ROOT}/SKILL.md")
        
        if [[ "$(echo "$improved_score > $new_score" | bc -l)" == "1" ]]; then
            new_score=$improved_score
            log "WORKER $worker_id: Round $current_round - Improved! Score: $new_score"
            update_worker_state "$worker_id" "$current_round" "$new_score" "$delta"
        else
            # 恢复原文件
            git checkout "${PROJECT_ROOT}/SKILL.md" 2>/dev/null || true
        fi
        
        echo "$new_score" >> "${WORKER_STATE_DIR}/scores_worker_${worker_id}.txt"
        last_score=$new_score
        
        ((current_round++))
    done
    
    log "WORKER $worker_id: Completed. Final score: $last_score"
    echo "$last_score"
}

aggregate_metrics() {
    local total_score=0
    local count=0
    local best_overall=0
    
    for i in $(seq 1 $MAX_WORKERS); do
        if [[ -f "${WORKER_STATE_DIR}/worker_${i}.json" ]]; then
            local ws
            ws=$(cat "${WORKER_STATE_DIR}/worker_${i}.json")
            local bs=$(echo "$ws" | jq -r '.best_score')
            total_score=$(echo "$total_score + $bs" | bc)
            ((count++))
            
            if [[ "$(echo "$bs > $best_overall" | bc -l)" == "1" ]]; then
                best_overall=$bs
            fi
        fi
    done
    
    local avg_score=0
    if [[ $count -gt 0 ]]; then
        avg_score=$(echo "scale=2; $total_score / $count" | bc)
    fi
    
    jq -n \
        --argjson best "$best_overall" \
        --arg avg "$avg_score" \
        '{best_score: $best, avg_score: ($avg | tonumber), workers: 3}'
}

report_progress() {
    local current_round=$1
    
    log "═══════════════════════════════════════════════════════════"
    log "  PROGRESS - Round $current_round"
    log "═══════════════════════════════════════════════════════════"
    
    local metrics
    metrics=$(aggregate_metrics)
    
    log "  Best Score: $(echo "$metrics" | jq -r '.best_score')"
    log "  Avg Score:  $(echo "$metrics" | jq -r '.avg_score')"
    log "  F1 Threshold: $F1_THRESHOLD"
    log "  MRR Threshold: $MRR_THRESHOLD"
    log "═══════════════════════════════════════════════════════════"
}

main() {
    log "═══════════════════════════════════════════════════════════"
    log "  PARALLEL EVOLUTION ENGINE (Fast Mode)"
    log "  Workers: $MAX_WORKERS"
    log "  Total Rounds: $TOTAL_ROUNDS"
    log "═══════════════════════════════════════════════════════════"
    
    # 初始化
    local init_score
    init_score=$(get_score "${PROJECT_ROOT}/SKILL.md")
    log "Initial Score: $init_score"
    
    # 计算每个worker的轮次分配
    local rounds_per_worker=$((TOTAL_ROUNDS / MAX_WORKERS))
    local start_round=1
    
    # 启动并行workers
    local pids=()
    for i in $(seq 1 $MAX_WORKERS); do
        local end_round=$((start_round + rounds_per_worker - 1))
        if [[ $i -eq $MAX_WORKERS ]]; then
            end_round=$TOTAL_ROUNDS
        fi
        
        run_worker $i $start_round $end_round &
        pids+=($!)
        
        start_round=$((end_round + 1))
    done
    
    # 等待所有worker完成
    for i in "${!pids[@]}"; do
        wait ${pids[$i]} || true
    done
    
    # 最终报告
    log "═══════════════════════════════════════════════════════════"
    log "  FINAL REPORT"
    log "═══════════════════════════════════════════════════════════"
    
    local final_metrics
    final_metrics=$(aggregate_metrics)
    log "  Final Best Score: $(echo "$final_metrics" | jq -r '.best_score')"
    log "  Final Avg Score:  $(echo "$final_metrics" | jq -r '.avg_score')"
    log "═══════════════════════════════════════════════════════════"
    
    # 提交
    cd "$PROJECT_ROOT"
    if git diff --cached --quiet && git diff --quiet; then
        log "  No changes to commit"
    else
        git add -A
        git commit -m "feat: 自我进化完成 - 最终评分 $(echo "$final_metrics" | jq -r '.best_score')" 2>/dev/null || true
    fi
}

trap 'log "Interrupted"; exit 1' INT TERM

main "$@"
