---
name: {{SKILL_NAME}}
version: {{VERSION}}
description: {{DESCRIPTION}}
description_i18n:
  en: {{DESCRIPTION_EN}}
  zh: {{DESCRIPTION_ZH}}
license: {{LICENSE}}
author: {{AUTHOR}}
created: {{CREATED_DATE}}
updated: {{UPDATED_DATE}}
type: {{TYPE}}
tags:
  - {{TAG_1}}
  - {{TAG_2}}
  - {{TAG_3}}
interface:
  input: {{INPUT_TYPE}}
  output: {{OUTPUT_TYPE}}
---

# {{SKILL_NAME}}

## Identity

### Name
{{SKILL_NAME}}

### Role
{{ROLE_DESCRIPTION}}

### Purpose
{{PURPOSE_STATEMENT}}

### Core Principles
1. {{PRINCIPLE_1}}
2. {{PRINCIPLE_2}}
3. {{PRINCIPLE_3}}
4. {{PRINCIPLE_4}}

### Red Lines
- {{RED_LINE_1}}
- {{RED_LINE_2}}
- {{RED_LINE_3}}

## Mode Router

Use the confidence formula to determine which mode to activate:

```
Confidence Score = Σ(Trigger Matches × Weight)

Thresholds:
- MODE_1: {{MODE_1_THRESHOLD}}+
- MODE_2: {{MODE_2_THRESHOLD}}+
- Default: MODE_1
```

## Mode 1: {{MODE_1_NAME}}

### Triggers
- {{MODE_1_TRIGGER_1}}
- {{MODE_1_TRIGGER_2}}
- {{MODE_1_TRIGGER_3}}

### Input
- {{MODE_1_INPUT_1}}
- {{MODE_1_INPUT_2}}

### Steps
1. {{MODE_1_STEP_1}}
2. {{MODE_1_STEP_2}}
3. {{MODE_1_STEP_3}}
4. {{MODE_1_STEP_4}}

### Output
{{MODE_1_OUTPUT_DESCRIPTION}}

### Exit Criteria
- {{MODE_1_EXIT_1}}
- {{MODE_1_EXIT_2}}

## Mode 2: {{MODE_2_NAME}}

### Triggers
- {{MODE_2_TRIGGER_1}}
- {{MODE_2_TRIGGER_2}}
- {{MODE_2_TRIGGER_3}}

### Input
- {{MODE_2_INPUT_1}}
- {{MODE_2_INPUT_2}}

### Steps
1. {{MODE_2_STEP_1}}
2. {{MODE_2_STEP_2}}
3. {{MODE_2_STEP_3}}
4. {{MODE_2_STEP_4}}

### Output
{{MODE_2_OUTPUT_DESCRIPTION}}

### Exit Criteria
- {{MODE_2_EXIT_1}}
- {{MODE_2_EXIT_2}}

## Quality Gates

| Gate | Check | Action if Failed |
|------|-------|------------------|
| {{GATE_1}} | {{GATE_1_CHECK}} | {{GATE_1_ACTION}} |
| {{GATE_2}} | {{GATE_2_CHECK}} | {{GATE_2_ACTION}} |
| {{GATE_3}} | {{GATE_3_CHECK}} | {{GATE_3_ACTION}} |

## Security Baseline

- {{SECURITY_1}}
- {{SECURITY_2}}
- {{SECURITY_3}}

## Usage Examples

### Example 1: {{EXAMPLE_1_NAME}}

**Input:**
```
{{EXAMPLE_1_INPUT}}
```

**Process:**
{{EXAMPLE_1_PROCESS}}

**Output:**
```
{{EXAMPLE_1_OUTPUT}}
```

### Example 2: {{EXAMPLE_2_NAME}}

**Input:**
```
{{EXAMPLE_2_INPUT}}
```

**Process:**
{{EXAMPLE_2_PROCESS}}

**Output:**
```
{{EXAMPLE_2_OUTPUT}}
```
