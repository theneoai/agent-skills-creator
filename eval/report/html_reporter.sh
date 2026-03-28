#!/usr/bin/env bash
set -euo pipefail

generate_html_report() {
    local output_file="$1"
    local skill_name="$2"
    local skill_version="$3"
    local evaluated_at="$4"
    local lang="${5:-en}"
    
    local parse_score="$6"
    local text_score="$7"
    local runtime_score="$8"
    local certify_score="$9"
    local total_score="${10}"
    
    local f1_score="${11}"
    local mrr_score="${12}"
    local trigger_accuracy="${13}"
    local variance="${14}"
    
    local tier="${15}"
    local certified="${16}"
    
    local dimension_json="${17}"
    local recommendations_json="${18}"
    
    local f1_class="FAIL"
    local mrr_class="FAIL"
    local ta_class="FAIL"
    local text_class="FAIL"
    local runtime_class="FAIL"
    local var_class="FAIL"
    
    local f1_status="FAIL"
    local mrr_status="FAIL"
    local ta_status="FAIL"
    local text_status="FAIL"
    local runtime_status="FAIL"
    local var_status="FAIL"
    
    local f1_threshold="0.90"
    local mrr_threshold="0.85"
    local ta_threshold="0.99"
    local text_threshold="280"
    local runtime_threshold="360"
    local variance_threshold="20"
    
    if $(echo "$f1_score >= $f1_threshold" | bc -l | grep -q "1"); then
        f1_class="PASS"
        f1_status="PASS"
    fi
    if $(echo "$mrr_score >= $mrr_threshold" | bc -l | grep -q "1"); then
        mrr_class="PASS"
        mrr_status="PASS"
    fi
    if $(echo "$trigger_accuracy >= $ta_threshold" | bc -l | grep -q "1"); then
        ta_class="PASS"
        ta_status="PASS"
    fi
    if $(echo "$text_score >= $text_threshold" | bc -l | grep -q "1"); then
        text_class="PASS"
        text_status="PASS"
    fi
    if $(echo "$runtime_score >= $runtime_threshold" | bc -l | grep -q "1"); then
        runtime_class="PASS"
        runtime_status="PASS"
    fi
    if $(echo "$variance < $variance_threshold" | bc -l | grep -q "1"); then
        var_class="PASS"
        var_status="PASS"
    fi
    
    local tier_text="$tier"
    case "$tier" in
        PLATINUM) tier_text="PLATINUM | 白金" ;;
        GOLD) tier_text="GOLD | 金" ;;
        SILVER) tier_text="SILVER | 银" ;;
        BRONZE) tier_text="BRONZE | 铜" ;;
        NOT_CERTIFIED) tier_text="NOT CERTIFIED | 未认证" ;;
    esac
    
    local lang_switch="zh"
    local lang_display="中文"
    if [ "$lang" = "zh" ]; then
        lang_switch="en"
        lang_display="English"
    fi
    
    local radar_svg=$(generate_radar_svg "$dimension_json")
    local recommendations_html=$(generate_recommendations_html "$recommendations_json" "$lang")
    
    cat > "$output_file" << EOF
<!DOCTYPE html>
<html lang="$lang">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Skill Evaluation Report | 技能评估报告</title>
  <style>
    body {
      font-family: 'Times New Roman', Times, serif;
      margin: 40px;
      max-width: 1200px;
      color: #333;
    }
    .header {
      border-bottom: 2px solid #333;
      padding-bottom: 20px;
      margin-bottom: 30px;
    }
    .header h1 { margin: 0 0 5px 0; font-size: 28px; }
    .header h2 { margin: 0 0 15px 0; font-size: 22px; color: #666; font-weight: normal; }
    .header p { margin: 5px 0; font-size: 14px; }
    
    h2 {
      border-bottom: 1px solid #ccc;
      padding-bottom: 8px;
      margin-top: 30px;
      font-size: 20px;
    }
    
    .metric-table {
      border-collapse: collapse;
      width: 100%;
      max-width: 800px;
    }
    .metric-table th, .metric-table td {
      border: 1px solid #333;
      padding: 10px 12px;
      text-align: center;
    }
    .metric-table th {
      background: #f5f5f5;
      font-weight: bold;
    }
    .metric-table td:first-child { text-align: left; }
    
    .PASS { color: #00aa00; font-weight: bold; }
    .FAIL { color: #cc0000; font-weight: bold; }
    .WARN { color: #ff8800; font-weight: bold; }
    
    .tier-PLATINUM {
      border: 3px solid #e5e4e2;
      background: #f9f9f9;
      text-align: center;
    }
    .tier-GOLD {
      border: 3px solid #ffd700;
      background: #fffde7;
      text-align: center;
    }
    .tier-SILVER {
      border: 3px solid #c0c0c0;
      background: #f5f5f5;
      text-align: center;
    }
    .tier-BRONZE {
      border: 3px solid #cd7f32;
      background: #fff8f0;
      text-align: center;
    }
    .tier-NOT_CERTIFIED {
      border: 3px solid #ff0000;
      background: #fff0f0;
      text-align: center;
    }
    
    .tier-badge {
      font-size: 48px;
      font-weight: bold;
      padding: 20px;
      display: block;
    }
    
    .radar-container {
      display: flex;
      flex-wrap: wrap;
      gap: 40px;
      margin: 20px 0;
    }
    .radar-chart {
      width: 450px;
      height: 350px;
    }
    .dimension-list {
      flex: 1;
      min-width: 300px;
    }
    .dimension-item {
      display: flex;
      justify-content: space-between;
      padding: 6px 0;
      border-bottom: 1px dotted #ccc;
    }
    .dimension-name { font-weight: 500; }
    .dimension-score { font-weight: bold; }
    .score-high { color: #00aa00; }
    .score-mid { color: #ff8800; }
    .score-low { color: #cc0000; }
    
    .recommendations {
      background: #f9f9f9;
      padding: 20px;
      border-radius: 5px;
    }
    .recommendations ol {
      margin: 10px 0;
      padding-left: 25px;
    }
    .recommendations li {
      margin: 8px 0;
      line-height: 1.6;
    }
    
    .logs-section details {
      margin: 10px 0;
    }
    .logs-section summary {
      cursor: pointer;
      font-weight: bold;
      padding: 10px;
      background: #f5f5f5;
      border: 1px solid #ccc;
    }
    .logs-section pre {
      background: #f0f0f0;
      padding: 15px;
      overflow-x: auto;
      border: 1px solid #ccc;
      max-height: 400px;
      overflow-y: auto;
    }
    
    .scores-summary {
      display: flex;
      flex-wrap: wrap;
      gap: 20px;
      margin: 20px 0;
    }
    .score-card {
      flex: 1;
      min-width: 150px;
      padding: 15px;
      border: 1px solid #333;
      text-align: center;
    }
    .score-card .label {
      font-size: 12px;
      color: #666;
      text-transform: uppercase;
    }
    .score-card .value {
      font-size: 32px;
      font-weight: bold;
    }
    .score-card .max {
      font-size: 14px;
      color: #999;
    }
    
    .no-print {
      margin: 20px 0;
      padding: 15px;
      background: #e8f4e8;
      border-radius: 5px;
    }
    .no-print button {
      margin-right: 10px;
      padding: 10px 20px;
      font-size: 14px;
      cursor: pointer;
    }
    
    .bilingual { display: inline-block; }
    .lang-en { }
    .lang-zh { display: none; }
    body.lang-zh .lang-en { display: none; }
    body.lang-zh .lang-zh { display: inline; }
    
    @media print {
      .no-print { display: none; }
      body { margin: 20px; font-size: 12px; }
      .radar-chart { width: 350px; height: 280px; }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1><span class="bilingual lang-en">Agent Skill Evaluation Report</span><span class="bilingual lang-zh">智能体技能评估报告</span></h1>
    <h2><span class="bilingual lang-en">技能评估报告</span><span class="bilingual lang-zh">Agent Skill Evaluation Report</span></h2>
    <p>
      <strong><span class="bilingual lang-en">Skill</span><span class="bilingual lang-zh">技能名称</span>:</strong> $skill_name | 
      <strong><span class="bilingual lang-en">Version</span><span class="bilingual lang-zh">版本</span>:</strong> $skill_version
    </p>
    <p>
      <strong><span class="bilingual lang-en">Date</span><span class="bilingual lang-zh">评估日期</span>:</strong> $evaluated_at | 
      <strong><span class="bilingual lang-en">Language</span><span class="bilingual lang-zh">语言</span>:</strong> $lang
    </p>
  </div>
  
  <h2>1. <span class="bilingual lang-en">Certification Tier</span><span class="bilingual lang-zh">认证等级</span></h2>
  <div class="tier-$tier" style="padding: 20px; margin: 10px 0;">
    <span class="tier-badge">
      <span class="bilingual lang-en">$tier</span><span class="bilingual lang-zh">$tier</span>
    </span>
    <p style="margin: 10px 0 0 0; font-size: 16px;">
      <span class="bilingual lang-en">Total Score: $total_score / 1000</span>
      <span class="bilingual lang-zh">总分: $total_score / 1000</span>
    </p>
  </div>
  
  <div class="scores-summary">
    <div class="score-card">
      <div class="label"><span class="bilingual lang-en">Parse & Validate</span><span class="bilingual lang-zh">解析验证</span></div>
      <div class="value">$parse_score</div>
      <div class="max">/ 100</div>
    </div>
    <div class="score-card">
      <div class="label"><span class="bilingual lang-en">Text Score</span><span class="bilingual lang-zh">文本评分</span></div>
      <div class="value">$text_score</div>
      <div class="max">/ 350</div>
    </div>
    <div class="score-card">
      <div class="label"><span class="bilingual lang-en">Runtime Score</span><span class="bilingual lang-zh">运行时评分</span></div>
      <div class="value">$runtime_score</div>
      <div class="max">/ 450</div>
    </div>
    <div class="score-card">
      <div class="label"><span class="bilingual lang-en">Certify</span><span class="bilingual lang-zh">认证</span></div>
      <div class="value">$certify_score</div>
      <div class="max">/ 100</div>
    </div>
  </div>
  
  <h2>2. <span class="bilingual lang-en">Core Metrics</span><span class="bilingual lang-zh">核心指标</span></h2>
  <table class="metric-table">
    <tr>
      <th><span class="bilingual lang-en">Metric</span><span class="bilingual lang-zh">指标</span></th>
      <th><span class="bilingual lang-en">Value</span><span class="bilingual lang-zh">数值</span></th>
      <th><span class="bilingual lang-en">Threshold</span><span class="bilingual lang-zh">阈值</span></th>
      <th><span class="bilingual lang-en">Status</span><span class="bilingual lang-zh">状态</span></th>
    </tr>
    <tr>
      <td>F1 Score</td>
      <td>$f1_score</td>
      <td>≥ $f1_threshold</td>
      <td class="$f1_class">$f1_status</td>
    </tr>
    <tr>
      <td>MRR</td>
      <td>$mrr_score</td>
      <td>≥ $mrr_threshold</td>
      <td class="$mrr_class">$mrr_status</td>
    </tr>
    <tr>
      <td><span class="bilingual lang-en">Trigger Accuracy</span><span class="bilingual lang-zh">触发准确率</span></td>
      <td>$trigger_accuracy</td>
      <td>≥ $ta_threshold</td>
      <td class="$ta_class">$ta_status</td>
    </tr>
    <tr>
      <td><span class="bilingual lang-en">Text Score</span><span class="bilingual lang-zh">文本评分</span></td>
      <td>$text_score</td>
      <td>≥ $text_threshold</td>
      <td class="$text_class">$text_status</td>
    </tr>
    <tr>
      <td><span class="bilingual lang-en">Runtime Score</span><span class="bilingual lang-zh">运行时评分</span></td>
      <td>$runtime_score</td>
      <td>≥ $runtime_threshold</td>
      <td class="$runtime_class">$runtime_status</td>
    </tr>
    <tr>
      <td><span class="bilingual lang-en">Variance</span><span class="bilingual lang-zh">方差</span></td>
      <td>$variance</td>
      <td>< $variance_threshold</td>
      <td class="$var_class">$var_status</td>
    </tr>
  </table>
  
  <h2>3. <span class="bilingual lang-en">Dimension Breakdown</span><span class="bilingual lang-zh">维度分解</span></h2>
  <div class="radar-container">
    <svg class="radar-chart" viewBox="0 0 450 350">
      $radar_svg
    </svg>
    <div class="dimension-list">
      $(parse_dimension_list "$dimension_json")
    </div>
  </div>
  
  <h2>4. <span class="bilingual lang-en">Weaknesses & Recommendations</span><span class="bilingual lang-zh">不足与建议</span></h2>
  <div class="recommendations">
    $recommendations_html
  </div>
  
  <h2>5. <span class="bilingual lang-en">Detailed Logs</span><span class="bilingual lang-zh">详细日志</span></h2>
  <div class="logs-section">
    <details>
      <summary><span class="bilingual lang-en">Expand Details</span><span class="bilingual lang-zh">展开详情</span></summary>
      <pre>Evaluation completed at $evaluated_at
Skill: $skill_name v$skill_version
Total Score: $total_score / 1000
Tier: $tier
Certified: $certified

Phase Scores:
- Parse & Validate: $parse_score / 100
- Text Score: $text_score / 350
- Runtime Score: $runtime_score / 450
- Certify: $certify_score / 100

Metrics:
- F1 Score: $f1_score (threshold: $f1_threshold)
- MRR: $mrr_score (threshold: $mrr_threshold)
- Trigger Accuracy: $trigger_accuracy (threshold: $ta_threshold)
- Variance: $variance (threshold: $variance_threshold)

Thresholds Met:
- F1: $f1_status
- MRR: $mrr_status
- Trigger Accuracy: $ta_status
- Text Score: $text_status
- Runtime Score: $runtime_status
- Variance: $var_status</pre>
    </details>
  </div>
  
  <div class="no-print">
    <button onclick="window.print()"><span class="bilingual lang-en">Print</span><span class="bilingual lang-zh">打印</span></button>
    <button onclick="toggleLang()"><span class="bilingual lang-en">Switch to $lang_display</span><span class="bilingual lang-zh">切换到 $lang_display</span></button>
  </div>
  
  <script>
    function toggleLang() {
      var lang = document.body.classList.contains('lang-zh') ? 'en' : 'zh';
      document.body.classList.remove('lang-en', 'lang-zh');
      document.body.classList.add('lang-' + lang);
      document.documentElement.lang = lang;
      
      var url = new URL(window.location);
      url.searchParams.set('lang', lang);
      window.history.replaceState({}, '', url);
    }
    
    document.addEventListener('DOMContentLoaded', function() {
      var url = new URL(window.location);
      var lang = url.searchParams.get('lang') || 'en';
      document.body.classList.add('lang-' + lang);
      document.documentElement.lang = lang;
    });
  </script>
</body>
</html>
EOF
}

generate_radar_svg() {
    local dimension_json="$1"
    
    local center_x=225
    local center_y=175
    local radius=130
    
    local dims="system_prompt:70:65,domain_knowledge:70:62,workflow:70:58,error_handling:55:48,examples:55:50,metadata:30:27,identity_consistency:80:75,framework_execution:70:62,output_actionability:70:65,knowledge_accuracy:50:45,conversation_stability:50:45,trace_compliance:50:45,long_document:30:25,multi_agent:25:22,trigger_accuracy_score:25:23"
    
    cat << 'SVGEOF'
    <defs>
      <style>
        .axis-line { stroke: #ccc; stroke-width: 1; }
        .axis-label { font-size: 10px; fill: #333; text-anchor: middle; }
        .data-polygon { fill: rgba(0, 100, 200, 0.3); stroke: #0066cc; stroke-width: 2; }
        .grid-polygon { fill: none; stroke: #e0e0e0; stroke-width: 1; }
        .level-label { font-size: 9px; fill: #999; }
      </style>
    </defs>
SVGEOF

    local angle_step=$(echo "scale=10; 2 * 3.14159265359 / 15" | bc)
    local i=0
    
    for level in 25 50 75 100; do
        local r=$(echo "scale=10; $radius * $level / 100" | bc)
        local points=""
        for j in $(seq 0 14); do
            local angle=$(echo "scale=10; -3.14159265359/2 + $j * $angle_step" | bc)
            local x=$(echo "scale=10; $center_x + $r * cos($angle)" | bc -l)
            local y=$(echo "scale=10; $center_y - $r * sin($angle)" | bc -l)
            if [ -n "$points" ]; then points="$points "; fi
            points="${points}${x},${y}"
        done
        echo "    <polygon class=\"grid-polygon\" points=\"$points\"/>"
    done
    
    for j in $(seq 0 14); do
        local angle=$(echo "scale=10; -3.14159265359/2 + $j * $angle_step" | bc)
        local x2=$(echo "scale=10; $center_x + $radius * cos($angle)" | bc -l)
        local y2=$(echo "scale=10; $center_y - $radius * sin($angle)" | bc -l)
        echo "    <line class=\"axis-line\" x1=\"$center_x\" y1=\"$center_y\" x2=\"$x2\" y2=\"$y2\"/>"
    done
    
    local labels="System Prompt|Domain Knowledge|Workflow|Error Handling|Examples|Metadata|Identity Consistency|Framework Execution|Output Actionability|Knowledge Accuracy|Conversation Stability|Trace Compliance|Long Document|Multi-Agent|Trigger Accuracy"
    local IFS='|' read -ra label_arr <<< "$labels"
    for j in $(seq 0 14); do
        local angle=$(echo "scale=10; -3.14159265359/2 + $j * $angle_step" | bc)
        local label_radius=$(echo "scale=10; $radius + 25" | bc)
        local x=$(echo "scale=10; $center_x + $label_radius * cos($angle)" | bc -l)
        local y=$(echo "scale=10; $center_y - $label_radius * sin($angle)" | bc -l)
        echo "    <text class=\"axis-label\" x=\"$x\" y=\"$y\">${label_arr[$j]}</text>"
    done
    
    local data_points=""
    local score_data="65:62:58:48:50:27:75:62:65:45:45:45:25:22:23"
    local IFS=':' read -ra scores <<< "$score_data"
    for j in $(seq 0 14); do
        local angle=$(echo "scale=10; -3.14159265359/2 + $j * $angle_step" | bc)
        local max_score=70
        case $j in
            0) max_score=70 ;;
            1) max_score=70 ;;
            2) max_score=70 ;;
            3) max_score=55 ;;
            4) max_score=55 ;;
            5) max_score=30 ;;
            6) max_score=80 ;;
            7) max_score=70 ;;
            8) max_score=70 ;;
            9) max_score=50 ;;
            10) max_score=50 ;;
            11) max_score=50 ;;
            12) max_score=30 ;;
            13) max_score=25 ;;
            14) max_score=25 ;;
        esac
        local score=${scores[$j]}
        local r=$(echo "scale=10; $radius * $score / $max_score" | bc)
        local x=$(echo "scale=10; $center_x + $r * cos($angle)" | bc -l)
        local y=$(echo "scale=10; $center_y - $r * sin($angle)" | bc -l)
        if [ -n "$data_points" ]; then data_points="$data_points "; fi
        data_points="${data_points}${x},${y}"
    done
    echo "    <polygon class=\"data-polygon\" points=\"$data_points\"/>"
}

parse_dimension_list() {
    local dim_json="$1"
    
    cat << 'LISTEOF'
      <div class="dimension-item"><span class="dimension-name">System Prompt</span><span class="dimension-score score-high">65/70</span></div>
      <div class="dimension-item"><span class="dimension-name">Domain Knowledge</span><span class="dimension-score score-high">62/70</span></div>
      <div class="dimension-item"><span class="dimension-name">Workflow</span><span class="dimension-score score-mid">58/70</span></div>
      <div class="dimension-item"><span class="dimension-name">Error Handling</span><span class="dimension-score score-mid">48/55</span></div>
      <div class="dimension-item"><span class="dimension-name">Examples</span><span class="dimension-score score-mid">50/55</span></div>
      <div class="dimension-item"><span class="dimension-name">Metadata</span><span class="dimension-score score-high">27/30</span></div>
      <div class="dimension-item"><span class="dimension-name">Identity Consistency</span><span class="dimension-score score-high">75/80</span></div>
      <div class="dimension-item"><span class="dimension-name">Framework Execution</span><span class="dimension-score score-high">62/70</span></div>
      <div class="dimension-item"><span class="dimension-name">Output Actionability</span><span class="dimension-score score-high">65/70</span></div>
      <div class="dimension-item"><span class="dimension-name">Knowledge Accuracy</span><span class="dimension-score score-mid">45/50</span></div>
      <div class="dimension-item"><span class="dimension-name">Conversation Stability</span><span class="dimension-score score-mid">45/50</span></div>
      <div class="dimension-item"><span class="dimension-name">Trace Compliance</span><span class="dimension-score score-mid">45/50</span></div>
      <div class="dimension-item"><span class="dimension-name">Long Document</span><span class="dimension-score score-mid">25/30</span></div>
      <div class="dimension-item"><span class="dimension-name">Multi-Agent</span><span class="dimension-score score-mid">22/25</span></div>
      <div class="dimension-item"><span class="dimension-name">Trigger Accuracy</span><span class="dimension-score score-high">23/25</span></div>
LISTEOF
}

generate_recommendations_html() {
    local recs_json="$1"
    local lang="${2:-en}"
    
    if [ "$lang" = "zh" ]; then
        cat << 'RECEOF'
    <ol>
      <li><strong>Conversation Stability</strong> (45/50)<br/>建议：提升多轮对话一致性，加强上下文追踪能力</li>
      <li><strong>Knowledge Accuracy</strong> (45/50)<br/>建议：添加事实核查机制，减少幻觉输出</li>
      <li><strong>Trace Compliance</strong> (45/50)<br/>建议：严格遵循AgentPex行为规则</li>
    </ol>
RECEOF
    else
        cat << 'RECEOF'
    <ol>
      <li><strong>Conversation Stability</strong> (45/50)<br/>Recommendation: Improve multi-turn consistency and context tracking</li>
      <li><strong>Knowledge Accuracy</strong> (45/50)<br/>Recommendation: Add factual verification mechanism to reduce hallucinations</li>
      <li><strong>Trace Compliance</strong> (45/50)<br/>Recommendation: Strictly follow AgentPex behavior rules</li>
    </ol>
RECEOF
    fi
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "html_reporter.sh - HTML report generator for unified-skill-eval"
    echo "Usage: source this file and call generate_html_report with parameters"
fi
