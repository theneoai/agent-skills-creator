#!/usr/bin/env bash
# convergence.sh - 收敛判定算法
#
# 检测进化是否趋于收敛，提供3层收敛检测:
# 1. 波动检测: 分数标准差 < 阈值
# 2. Plateau检测: 连续N轮 delta < 阈值
# 3. 趋势检测: 无明显上升趋势

CONVERGENCE_VERSION="1.0"

check_convergence() {
    local skill_name="$1"
    local window_size="${2:-10}"
    local volatility_threshold="${3:-2.0}"
    local plateau_threshold="${4:-0.5}"
    local min_rounds="${5:-5}"
    
    local scores
    scores=$(storage_get_all_scores "$skill_name")
    
    local score_count
    score_count=$(echo "$scores" | jq 'length')
    
    if [[ $score_count -lt $min_rounds ]]; then
        echo "NOT_CONVERGED: insufficient_data"
        return 1
    fi
    
    local recent_scores
    recent_scores=$(echo "$scores" | jq -c ".[-$window_size:]")
    
    local volatility_status
    volatility_status=$(check_volatility "$recent_scores" "$volatility_threshold")
    
    local plateau_status
    plateau_status=$(check_plateau "$recent_scores" "$plateau_threshold")
    
    local trend_status
    trend_status=$(check_trend "$recent_scores")
    
    if [[ "$volatility_status" == "CONVERGED" ]] && \
       [[ "$plateau_status" == "CONVERGED" ]]; then
        echo "CONVERGED: volatility=${volatility_status}, plateau=${plateau_status}, trend=${trend_status}"
        return 0
    fi
    
    if [[ "$trend_status" == "DIVERGING" ]]; then
        echo "NOT_CONVERGED: trend=diverging"
        return 1
    fi
    
    echo "NOT_CONVERGED: volatility=${volatility_status}, plateau=${plateau_status}, trend=${trend_status}"
    return 1
}

check_volatility() {
    local scores_json="$1"
    local threshold="$2"
    
    local values
    values=$(echo "$scores_json" | jq -r '.[].score | @text')
    
    if [[ -z "$values" ]]; then
        echo "UNKNOWN"
        return
    fi
    
    local count=0
    local sum=0
    local sum_sq=0
    
    while IFS= read -r score; do
        [[ -z "$score" ]] && continue
        count=$((count + 1))
        sum=$(echo "$sum + $score" | bc -l)
        sum_sq=$(echo "$sum_sq + $score * $score" | bc -l)
    done <<< "$values"
    
    if [[ $count -lt 2 ]]; then
        echo "UNKNOWN"
        return
    fi
    
    local mean
    mean=$(echo "$sum / $count" | bc -l)
    
    local variance
    variance=$(echo "($sum_sq / $count) - ($mean * $mean)" | bc -l)
    
    local stddev
    stddev=$(echo "sqrt($variance)" | bc -l)
    
    local stddev_cmp
    stddev_cmp=$(echo "$stddev < $threshold" | bc -l)
    
    if [[ "$stddev_cmp" == "1" ]]; then
        echo "CONVERGED"
    else
        echo "VOLATILE(stddev=$stddev)"
    fi
}

check_plateau() {
    local scores_json="$1"
    local threshold="$2"
    
    local count
    count=$(echo "$scores_json" | jq 'length')
    
    if [[ $count -lt 3 ]]; then
        echo "UNKNOWN"
        return
    fi
    
    local deltas=""
    local plateau_count=0
    local total_delta=0
    
    for ((i=1; i<count; i++)); do
        local prev
        prev=$(echo "$scores_json" | jq -r ".[$((i-1))].score")
        local curr
        curr=$(echo "$scores_json" | jq -r ".[$i].score")
        
        local delta
        delta=$(echo "$curr - $prev" | bc -l)
        
        if [[ -z "$deltas" ]]; then
            deltas="$delta"
        else
            deltas="$deltas $delta"
        fi
        
        local abs_delta
        abs_delta=$(echo "if ($delta < 0) -$delta else $delta" | bc -l)
        
        local is_small
        is_small=$(echo "$abs_delta < $threshold" | bc -l)
        
        if [[ "$is_small" == "1" ]]; then
            plateau_count=$((plateau_count + 1))
        fi
        
        total_delta=$(echo "$total_delta + $delta" | bc -l)
    done
    
    local plateau_ratio
    plateau_ratio=$(echo "$plateau_count / ($count - 1)" | bc -l)
    
    local improving
    improving=$(echo "$total_delta > 0" | bc -l)
    
    if [[ "$(echo "$plateau_ratio > 0.7" | bc -l)" == "1" ]] && [[ "$improving" != "1" ]]; then
        echo "CONVERGED"
    else
        echo "ACTIVE(delta=$total_delta, plateau_ratio=$plateau_ratio)"
    fi
}

check_trend() {
    local scores_json="$1"
    
    local count
    count=$(echo "$scores_json" | jq 'length')
    
    if [[ $count -lt 4 ]]; then
        echo "UNKNOWN"
        return
    fi
    
    local first_half_avg
    first_half_avg=$(echo "$scores_json" | jq -c '.[0:(length/2)]' | jq '[.[].score] | add / length')
    
    local second_half_avg
    second_half_avg=$(echo "$scores_json" | jq -c '.[(length/2):]' | jq '[.[].score] | add / length')
    
    local trend
    trend=$(echo "$second_half_avg - $first_half_avg" | bc -l)
    
    local improving
    improving=$(echo "$trend > 1.0" | bc -l)
    
    if [[ "$improving" == "1" ]]; then
        echo "IMPROVING"
    elif [[ "$(echo "$trend < -1.0" | bc -l)" == "1" ]]; then
        echo "DIVERGING"
    else
        echo "STABLE"
    fi
}

should_continue_evolution() {
    local skill_name="$1"
    local max_rounds="${2:-100}"
    local min_score_improvement="${3:-5}"
    
    local eval_count
    eval_count=$(storage_get_eval_count "$skill_name")
    
    if [[ $eval_count -ge $max_rounds ]]; then
        echo "STOP: max_rounds_reached"
        return 1
    fi
    
    local first_score
    first_score=$(echo "$(storage_get_all_scores "$skill_name")" | jq -r '.[0].score // 0')
    
    local last_score
    last_score=$(storage_get_last_score "$skill_name")
    
    local improvement
    improvement=$(echo "$last_score - $first_score" | bc -l)
    
    if [[ "$(echo "$improvement < $min_score_improvement" | bc -l)" == "1" ]] && [[ $eval_count -ge 10 ]]; then
        echo "STOP: insufficient_improvement"
        return 1
    fi
    
    local convergence_status
    if check_convergence "$skill_name" 10 2.0 0.5 5 2>/dev/null | grep -q "CONVERGED"; then
        echo "STOP: converged"
        return 1
    fi
    
    echo "CONTINUE: eval_count=$eval_count, improvement=$improvement"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Convergence Detection v${CONVERGENCE_VERSION}"
    echo "Usage: source convergence.sh and call check_convergence, should_continue_evolution"
fi
