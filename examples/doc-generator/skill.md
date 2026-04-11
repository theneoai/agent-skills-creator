---
name: doc-generator
version: "1.0.0"
description: "Generate documentation from code and data sources — data pipeline for document automation."
description_i18n:
  en: "Data pipeline: extract, transform, validate, and format documentation from various sources"
  zh: "数据管道：从各种来源提取、转换、验证和格式化文档"

license: MIT
author:
  name: Skill Framework Team
  email: team@skillframework.dev
created: "2026-03-31"
updated: "2026-04-11"
type: data-pipeline

skill_tier: functional   # Reusable data pipeline: input=code/data sources, output=documentation

tags:
  - data
  - pipeline
  - documentation
  - code-analysis
  - multilingual

triggers:
  en:
    - "generate documentation"
    - "generate docs"
    - "create API docs"
    - "document this code"
    - "write README"
    - "batch document"
    - "convert docs to markdown"
  zh:
    - "生成文档"
    - "生成API文档"
    - "文档化这段代码"
    - "批量生成文档"

interface:
  input: multimodal       # Supports code files, markdown, JSON, images
  output: markdown        # Primary output format
  modes: [generate, batch, convert]

pipeline:
  input_schema: "schemas/input.yaml"
  output_schema: "schemas/output.yaml"
  max_record_count: 10000
  chunk_size: 100

use_to_evolve:
  enabled: true
  injected_by: "skill-writer v3.1.0"
  injected_at: "2026-04-11"
  check_cadence: {lightweight: 10, full_recompute: 50, tier_drift: 100}
  micro_patch_enabled: true
  feedback_detection: true
  certified_lean_score: 340
  last_ute_check: null
  pending_patches: 0
  total_micro_patches_applied: 0
  cumulative_invocations: 0
---

## Skill Summary

doc-generator extracts, transforms, validates, and formats documentation from code files, API specs, and data sources using an ETVF pipeline. Use it when you need to generate API reference docs, README files, or convert existing docs to markdown — for single files or batch processing entire projects. Designed for developers and technical writers who need consistent, structured documentation output. This skill does NOT write new code comments or features, review code quality, or perform UI testing — see Negative Boundaries.

---

## §N  Negative Boundaries

**Do NOT use this skill for**:

- **Writing inline code comments**: If the user asks "add JSDoc comments to my functions", use a code annotation skill. This skill extracts and formats existing documentation, it doesn't write comments into source files.
- **Code review or quality assessment**: If the user asks "review my code" or "check for bugs", route to the code-reviewer skill.
- **Generating test cases**: If the user asks "write tests for this API", use a test generation skill.
- **Content writing / marketing copy**: If the user asks "write a blog post about my API", use a content generation skill. This skill produces technical reference documentation only.
- **Real-time API introspection**: This skill processes files you provide. It cannot connect to live APIs and auto-discover endpoints — provide an OpenAPI spec or code files as input.

---

## §1  Identity

**Name**: Doc Generator
**Role**: Documentation Generation Pipeline Agent
**Purpose**: Automatically generate, transform, and format documentation from code comments, API specs, and data sources using the ETVF (Extract-Transform-Validate-Format) pipeline.

**Pipeline Stages (ETVF)**:
```
[INPUT: code/markdown/json]
    │
    ▼
[EXTRACT] → parse comments, extract metadata, identify doc blocks
    │
    ▼
[TRANSFORM] → normalize structure → enrich content → apply templates
    │
    ▼
[VALIDATE] → schema check → link verification → quality gates
    │
    ▼
[FORMAT] → render markdown → apply styling → output generation
    │
    ▼
[OUTPUT: formatted documentation]
```

**Red Lines (严禁)**:
- 严禁 process more than 10,000 records without explicit confirmation
- 严禁 discard source content silently — log every skipped section with reason
- 严禁 output documentation without passing quality validation
- 严禁 skip link verification when generating cross-references

---

## §2  Data Pipeline — ETVF Flow

### Extract Phase
| Step | Operation | Output |
|------|-----------|--------|
| E1 | Parse source files (code, markdown, JSON) | Raw doc blocks |
| E2 | Extract JSDoc/Docstring/Go doc comments | Structured metadata |
| E3 | Identify API endpoints and parameters | API specs |
| E4 | Extract code examples and usage patterns | Example snippets |

### Transform Phase
| Step | Operation | Output |
|------|-----------|--------|
| T1 | Normalize doc block structure | Standardized JSON |
| T2 | Enrich with type information | Typed signatures |
| T3 | Cross-reference internal links | Link mappings |
| T4 | Apply template transformations | Formatted sections |

### Validate Phase
| Step | Operation | Criteria |
|------|-----------|----------|
| V1 | Schema compliance check | 100% match |
| V2 | Link verification | All internal links valid |
| V3 | Completeness check | All public APIs documented |
| V4 | Quality score | ≥ 85/100 |

### Format Phase
| Step | Operation | Output |
|------|-----------|--------|
| F1 | Render Markdown | `.md` files |
| F2 | Generate HTML (optional) | `.html` files |
| F3 | Create PDF (optional) | `.pdf` files |
| F4 | Build navigation index | TOC and search index |

---

## §3  Input Schema

```yaml
input_schema:
  version: "1.0.0"
  
  sources:
    type: array
    items:
      type: object
      properties:
        path:
          type: string
          description: "Path to source file or directory"
        type:
          type: string
          enum: [file, directory, url, git]
        language:
          type: string
          enum: [javascript, typescript, python, go, rust, markdown, json, yaml]
        include_pattern:
          type: string
          default: "*"
        exclude_pattern:
          type: string
          default: "node_modules/**,dist/**,.git/**"
  
  extraction:
    type: object
    properties:
      doc_style:
        type: string
        enum: [jsdoc, google, numpy, restructuredtext, godoc, rustdoc]
        default: "jsdoc"
      extract_examples:
        type: boolean
        default: true
      extract_private:
        type: boolean
        default: false
      extract_internal:
        type: boolean
        default: false
  
  options:
    type: object
    properties:
      locale:
        type: string
        default: "en"
      bilingual:
        type: boolean
        default: false
        description: "Generate bilingual documentation (中文/English)"
```

---

## §4  Output Schema

```yaml
output_schema:
  version: "1.0.0"
  
  documentation:
    type: object
    properties:
      title:
        type: string
        required: true
      description:
        type: string
      version:
        type: string
      sections:
        type: array
        items:
          type: object
          properties:
            id:
              type: string
            title:
              type: string
              required: true
            content:
              type: string
              required: true
            code_examples:
              type: array
              items:
                type: object
                properties:
                  language:
                    type: string
                  code:
                    type: string
                  output:
                    type: string
      api_reference:
        type: array
        items:
          type: object
          properties:
            name:
              type: string
            type:
              type: string
              enum: [function, class, interface, enum, type]
            signature:
              type: string
            parameters:
              type: array
            returns:
              type: object
            description:
              type: string
            examples:
              type: array
      
  metadata:
    type: object
    properties:
      generated_at:
        type: string
        format: date-time
      source_count:
        type: integer
      section_count:
        type: integer
      api_count:
        type: integer
      quality_score:
        type: number
        minimum: 0
        maximum: 100
```

---

## §5  GENERATE Mode

**Triggers**: generate, create, doc, 生成, 创建, 文档

**Purpose**: Generate documentation for a single file or module.

**Workflow**:
```
1. INGEST → Load source file
2. EXTRACT → Parse doc comments and code structure
3. TRANSFORM → Apply templates and formatting
4. VALIDATE → Check completeness and quality
5. FORMAT → Render final markdown
6. EXPORT → Write to output file
```

**Input Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | string | Yes | Path to source file |
| `output` | string | No | Output file path (default: `./docs/<name>.md`) |
| `template` | string | No | Template to use (default: `default`) |
| `locale` | string | No | Output language (default: `en`) |

**Example**:
```
Input: "generate docs for src/api.js"
Output: docs/api.md
Status: PASS | Quality: 92/100 | APIs: 15 documented
```

---

## §6  BATCH Mode

**Triggers**: batch, process, directory, 批量, 处理, 目录

**Purpose**: Process an entire directory of source files.

**Workflow**:
```
1. DISCOVER → Find all matching source files
2. CHUNK → Group files into batches (max 100 per chunk)
3. PARALLEL → Process each chunk independently
4. MERGE → Combine outputs into unified documentation
5. INDEX → Generate navigation and search index
6. VALIDATE → Full quality check
```

**Input Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source_dir` | string | Yes | Source directory path |
| `output_dir` | string | No | Output directory (default: `./docs/`) |
| `pattern` | string | No | File pattern (default: `**/*.{js,ts,py,go,rs}`) |
| `recursive` | boolean | No | Process subdirectories (default: `true`) |

**Progress Reporting**:
```
Batch Progress: [██████░░░░] 60%
Files: 120/200 processed
Current: src/utils/helpers.js
Quality: 88/100 (PASS)
```

**Exit Criteria**: All files processed, index generated, quality ≥ 85.

---

## §7  CONVERT Mode

**Triggers**: convert, transform, format, 转换, 格式化

**Purpose**: Convert documentation between formats.

**Supported Conversions**:
| From | To | Status |
|------|-----|--------|
| Markdown | HTML | ✓ Supported |
| Markdown | PDF | ✓ Supported |
| JSDoc | Markdown | ✓ Supported |
| OpenAPI | Markdown | ✓ Supported |
| Markdown | JSON | ✓ Supported |
| HTML | Markdown | ✓ Supported |

**Input Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `input` | string | Yes | Input file path |
| `output` | string | Yes | Output file path |
| `from` | string | Yes | Source format |
| `to` | string | Yes | Target format |
| `theme` | string | No | Styling theme (for HTML/PDF) |

**Example**:
```
Input: "convert README.md to README.pdf --theme=github"
Output: README.pdf
Status: PASS | Pages: 12 | Size: 245KB
```

---

## §8  Quality Gates

| Metric | Threshold | Description |
|--------|-----------|-------------|
| Completeness | ≥ 95% | Public APIs must be documented |
| Accuracy | ≥ 90% | Code examples must be valid |
| Consistency | ≥ 95% | Style and formatting consistency |
| Link Validity | 100% | All internal links must resolve |
| Type Coverage | ≥ 80% | Type annotations present |
| Quality Score | ≥ 85/100 | Overall documentation quality |

**Quality Checkpoints**:
1. **Pre-transform**: Source validation
2. **Post-transform**: Structure validation
3. **Pre-export**: Content validation
4. **Post-export**: Link verification

---

## §9  Error Handling

### Error Categories
| Code | Category | Severity | Action |
|------|----------|----------|--------|
| E001 | Parse Error | ERROR | Skip file, log reason |
| E002 | Schema Violation | ERROR | Quarantine record |
| E003 | Link Broken | WARNING | Flag for review |
| E004 | Missing Example | WARNING | Generate placeholder |
| E005 | Type Mismatch | ERROR | Request clarification |
| E006 | Encoding Issue | WARNING | Normalize and continue |

### Recovery Strategies
- **Parse Error**: Skip file, continue with others
- **Schema Violation**: Quarantine invalid records, continue processing
- **Link Broken**: Flag for manual review, don't fail pipeline
- **Missing Example**: Auto-generate from signature, flag for review
- **Type Mismatch**: Request user input for ambiguous types
- **Encoding Issue**: Normalize to UTF-8, log warning

### Abort Conditions
- Quarantine rate > 10%
- Critical parse errors > 5 files
- User cancellation
- Disk space < 100MB

---

## §10  Usage Examples

### Example 1: 生成单个文件的API文档 (Generate API docs for single file)

**Input**:
```
为 src/auth.js 生成API文档，包含所有公共函数
```

**Pipeline Execution**:
```
Mode: GENERATE
Source: src/auth.js
Language: JavaScript

EXTRACT: Found 8 functions, 3 classes
TRANSFORM: Applied JSDoc template
VALIDATE: 7/8 functions documented (87.5%)
FORMAT: Rendered markdown with code examples

Output: docs/auth.md
Quality Score: 91/100 ✓

Sections:
- Overview
- Authentication Methods (3 functions)
- Token Management (3 functions)
- Error Handling (2 functions)
- Examples (5 code snippets)
```

### Example 2: 批量处理整个项目 (Batch process entire project)

**Input**:
```
批量生成整个项目的文档，源代码在 ./src，输出到 ./docs
包含中文和英文双语版本
```

**Pipeline Execution**:
```
Mode: BATCH
Source: ./src
Pattern: **/*.{js,ts}
Bilingual: true

DISCOVER: Found 45 source files
CHUNK: Split into 5 chunks (9-10 files each)

Processing:
  Chunk 1: 10 files ✓
  Chunk 2: 10 files ✓
  Chunk 3: 9 files ✓
  Chunk 4: 9 files ✓
  Chunk 5: 7 files ✓

MERGE: Combined into unified documentation
INDEX: Generated navigation and search

Output Structure:
  docs/
  ├── index.md (双语)
  ├── api/
  │   ├── auth.md
  │   ├── database.md
  │   └── utils.md
  ├── guides/
  │   ├── getting-started.md
  │   └── advanced-usage.md
  └── search-index.json

Statistics:
  Files processed: 45
  APIs documented: 127
  Code examples: 89
  Quality Score: 88/100 ✓
  Generation time: 12.3s
```

---

**Triggers**: **generate** | **batch** | **convert** | **lean** | **evaluate** | **optimize** | **生成** | **批量** | **转换** | **快评** | **评测** | **优化**

---

## §UTE  Use-to-Evolve

**Status**: enabled
**Spec**: `refs/use-to-evolve.md`
**Injected**: 2026-04-01 by skill-writer v2.0.0

This skill is self-improving. After every invocation the Post-Invocation Hook
fires automatically. Do not skip it.

### Post-Invocation Hook (run at end of EVERY call)

**Step 1 — Record usage** (append to `.skill-audit/usage.jsonl`):
```json
{
  "timestamp": "<now-ISO-8601>",
  "skill_name": "doc-generator",
  "skill_version": "1.0.0",
  "mode": "<mode that ran>",
  "trigger_matched": "<true|false>",
  "trigger_input": "<first 80 chars of user input>",
  "confidence": "<0.00–1.00>",
  "success": "<true|false>",
  "latency_ms": "<elapsed>",
  "feedback_signal": "none|correction|rephrasing|approval|abandon"
}
```

**Step 2 — Detect feedback signal** from user's immediate response:

| Pattern | Signal |
|---------|--------|
| "wrong", "不对", "incorrect", user corrects output | `correction` → `success: false` |
| Same request rephrased within 2 turns | `rephrasing` → add to trigger candidates |
| "thanks", "好的", "perfect", user proceeds | `approval` → `success: true` |
| Session ends or topic switches immediately | `abandon` → `ambiguous` |
| No follow-up | `none` → `neutral` |

If signal = `rephrasing`: extract new phrase → log to `.skill-audit/trigger-candidates.jsonl`
with `count +1`. When any candidate reaches `count ≥ 3` → flag for micro-patch.

**Step 3 — Check triggers** (cadence-gated; check cumulative_invocations):

```
invocations % 10  == 0 → LIGHTWEIGHT CHECK
invocations % 50  == 0 → FULL METRIC RECOMPUTE
invocations % 100 == 0 → TIER DRIFT CHECK
```

**Lightweight check** (last 20 calls):
- rolling_success_rate < 0.80 OR rolling_trigger_acc < 0.85 → see §UTE Trigger Actions
- ≥ 3 consecutive failures → surface warning + queue OPTIMIZE

**Full recompute** (last 50 calls):
- Recompute F1, MRR, trigger_accuracy from usage log
- F1 < 0.90 → queue OPTIMIZE (D3/D5 dimension)
- MRR < 0.85 → queue OPTIMIZE (D3 dimension)
- trigger_accuracy < 0.90 → micro-patch (keyword add) if candidates exist

**Tier drift check** (last 100 calls):
- estimated_lean < 290 (certified 340 − 50) → queue full EVALUATE

### Trigger Actions

| Condition | Action |
|-----------|--------|
| trigger_candidate count ≥ 3 | Micro-patch: add candidate as primary keyword |
| ZH input failure rate > 20% | Micro-patch: add ZH trigger for failing mode |
| rolling_success_rate < 0.80 | Queue OPTIMIZE targeting lowest dimension |
| ≥ 3 consecutive failures | Warn user + queue OPTIMIZE |
| F1 < 0.90 (recompute) | Queue OPTIMIZE |
| tier drift > 50 pts | Queue full EVALUATE |

### Micro-Patch Rules

**Eligible** (apply autonomously after LEAN validation):
- Add trigger keyword (YAML + mode section)
- Add ZH trigger equivalent
- Update `updated` date + bump patch version

**Ineligible** (must queue for OPTIMIZE via skill-writer):
- Structural section changes
- Output contract changes
- Security baseline changes
- Anything touching Red Lines

**Apply at**: start of next session OR when user says "apply UTE patches".
**Safety**: run LEAN eval before and after; rollback if score drops > 10 pts.

### Evolution Queue

Structural issues write to `.skill-audit/evolution-queue.jsonl`:
```json
{
  "timestamp": "<ISO-8601>",
  "skill_name": "doc-generator",
  "reason": "<trigger condition>",
  "recommended_strategy": "S1|S2|S3|S4|S5",
  "target_dimension": "D1–D7",
  "priority": "high|medium|low"
}
```

Consume the queue by invoking skill-writer OPTIMIZE mode on this skill.
