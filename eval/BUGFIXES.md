# unified-skill-eval Bug Fixes & Lessons Learned

> **更新时间**: 2026-03-28
> **版本**: v2.0

---

## 一、本次修复的 Bug

### 1. JSON 解析问题

**问题描述**：
LLM 返回的 `content[0].text` 是嵌套 JSON 字符串，需要二次解析。

**现象**：
```bash
# 直接提取
text=$(echo "$response" | jq -r '.content[0].text')
# 输出: "{\"score\":85}" (带引号的字符串)

# 需要二次解析
echo "$text" | jq '.score'  # 输出: 85
```

**修复方案**：
```bash
extract_json_from_response() {
    local response="$1"
    local text=$(echo "$response" | jq -r '.content[0].text')
    
    # 去除 markdown 代码块
    text=$(echo "$text" | tr -d '\n' | sed 's/```json//g' | sed 's/```//g')
    
    # 如果是字符串，解析它
    if [[ "$text" == \"* ]]; then
        text=$(echo "$text" | jq -r '.')
    fi
    
    echo "$text"
}
```

**根因**：Kimi Code API 返回格式是 `{"content":[{"type":"text","text":"..."}]}`，text 字段本身是 JSON 字符串。

---

### 2. jq -e 错误检查问题

**问题描述**：
`jq -e '.error'` 在字段不存在时也返回 exit code 1。

**现象**：
```bash
# 响应没有 error 字段
echo '{"id":"msg_xxx"}' | jq -e '.error'
# exit code: 1 (错误地认为有 error)
```

**修复方案**：
```bash
# 之前
echo "$response" | jq -e '.error' >/dev/null 2>&1

# 之后
echo "$response" | jq -e '.error // empty' >/dev/null 2>&1
```

---

### 3. LLM markdown 输出问题

**问题描述**：
当 user prompt 包含 JSON 样本文本时，LLM 会用 markdown 代码块包装输出。

**现象**：
```bash
# Prompt: "Give me {\"score\":85}"
# LLM 返回: ```json\n{"score":85}\n```
```

**修复方案**：
```bash
# 去除 markdown 代码块
text=$(echo "$text" | tr -d '\n' | sed 's/```json//g' | sed 's/```//g')
```

---

### 4. 字符串拼接导致 JSON 格式错误

**问题描述**：
用字符串拼接构建 JSON 请求可能导致格式错误。

**现象**：
```bash
# 之前（错误）
-d '{"model":"'"$model"'","max_tokens":1024,...}'

# 之后（正确）
json_data=$(jq -n --arg model "$model" ... '{"model": $model, ...}')
```

**修复方案**：
```bash
json_data=$(jq -n \
    --arg model "$model" \
    --arg system "$system" \
    --arg user "$user" \
    '{"model": $model, "max_tokens": 1024, "system": $system, "messages": [{"role": "user", "content": $user}]}')
```

---

### 5. stdout 污染问题

**问题描述**：
`runtime_agent_tester.sh` 中的警告信息输出到 stdout，污染了结果解析。

**现象**：
```bash
# 捕获的结果包含警告
results=$(./scorer/runtime_agent_tester.sh ... 2>/dev/null)
# results = "WARNING: No LLM available\n40:50:..."
```

**修复方案**：
```bash
# 所有 echo 警告改为 stderr
echo "WARNING: No LLM API key found." >&2
```

---

### 6. cross_evaluate 双调用问题

**问题描述**：
当有多个 provider 时，`cross_evaluate` 会调用每个 provider，导致速度慢 2 倍。

**修复方案**：
```bash
# 只使用第一个 provider
first_provider=$(echo "$providers" | cut -d' ' -f1)
result=$(call_llm "$system_prompt" "$user_prompt" "auto" "$first_provider")
echo "single:$result"
```

---

### 7. Tier 计算在 main 中而非 run_phase4

**问题描述**：
`tier` 在 `run_phase4` 中设为 "UNKNOWN"，后在 `main` 中重新计算，但 phase4.json 不会更新。

**修复方案**：
在 `main` 中计算完 tier 后，重新写入 phase4.json：
```bash
# 在 main 中
tier="BRONZE"
tier_score=20

cat > "$OUTPUT_DIR/phase4.json" <<EOF
{
    "tier": "$tier",
    "tier_score": $tier_score,
    ...
}
EOF
```

---

## 二、性能优化

### 1. 超时设置
```bash
# 之前: --max-time 30
# 之后: --max-time 10
response=$(curl -s --max-time 10 ...)
```

### 2. 测试用例数量
```bash
# 之前: max_tests=20
# 之后: max_tests=10
```

### 3. Provider 选择
```bash
# 之前: 双 provider 调用
# 之后: 只用 kimi-code (最快)
```

---

## 三、API 配置

### Kimi Code API
```bash
export KIMI_CODE_API_KEY="sk-kimi-..."
export KIMI_CODE_ENDPOINT="https://api.kimi.com/coding/v1"
export DEFAULT_KIMI_CODE_MODEL="kimi-for-coding"
```

### Anthropic API
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

---

## 四、经验总结

### 1. LLM API 调用必须
- 设置 `--max-time` 超时
- 检查 exit code
- 验证 JSON 格式
- 处理 markdown 包装

### 2. jq 使用注意
- `jq -e` 在值不存在时返回 1
- 用 `.error // empty` 避免误判
- `jq -r` 输出 raw 字符串（带引号）

### 3. 性能考虑
- 测试时只用一个 provider
- 限制测试用例数量
- 使用较短超时

### 4. stderr vs stdout
- 警告信息 → stderr
- 数据结果 → stdout

---

## 五、调试技巧

### 测试 LLM 调用
```bash
source ~/.bashrc 2>/dev/null
cd unified-skill-eval
source lib/agent_executor.sh

# 单次调用测试
result=$(call_kimi_code "Respond with JSON." "Give me score")
echo "$result" | jq '.score'
```

### 检查 provider 可用性
```bash
source lib/agent_executor.sh
check_llm_available
# 输出: kimi-code minimax
```

### 逐步调试
```bash
# 1. 检查 source
source lib/agent_executor.sh && echo "OK"

# 2. 检查函数
call_kimi_code "test" "test" && echo "OK"

# 3. 检查返回值
result=$(call_kimi_code ...)
jq '.score' <<< "$result"
```
