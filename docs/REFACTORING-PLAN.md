# Skill 项目重构计划

**版本**: 2.4.0  
**日期**: 2026-03-29  
**状态**: 待执行

---

## 一、重构目标

1. **业务统一**: 统一评分标准、简化流程、聚焦核心
2. **架构精简**: 目录扁平、模块解耦、消除重复
3. **代码质量**: 每功能有测试、300用例、多LLM验证
4. **路线清晰**: 明确定位、制定发展规划

---

## 二、最终目录结构

```
skill/
├── SKILL.md               # 主文档
├── README.md              # 项目说明
├── CHANGELOG.md           # 变更记录
│
├── cli/                   # 用户入口
│   └── skill              # 唯一CLI
│
├── tools/                 # 工具脚本 (给AI用)
│   ├── bootstrap/         # 启动加载
│   │   └── bootstrap.sh
│   ├── agents/           # Agent模块
│   │   ├── agent.sh
│   │   ├── create.sh
│   │   ├── evaluate.sh
│   │   ├── optimize.sh
│   │   ├── restore.sh
│   │   └── security.sh
│   ├── engine/           # 进化引擎
│   │   ├── engine.sh     # 合并learner/convergence/storage/summarizer
│   │   ├── rollback.sh
│   │   └── decider.sh
│   ├── eval/             # 评估模块
│   │   ├── main.sh
│   │   ├── analyzer.sh   # 合并trigger/variance/dimension
│   │   ├── report.sh     # 合并html/json
│   │   └── scorer/
│   ├── lib/              # 公共库
│   │   ├── constants.sh
│   │   ├── scoring.sh
│   │   ├── errors.sh
│   │   ├── utils.sh
│   │   └── concurrency.sh
│   └── orchestrator.sh   # 合并_state/_workflow/_actions/_parallel
│
├── refs/                  # 参考文档 (给AI看)
│   ├── workflows.md
│   ├── triggers.md
│   └── tools.md
│
├── docs/                  # 项目文档 (给人看)
│   ├── guide/
│   │   ├── index.md
│   │   └── quick-start.md
│   ├── standards/
│   │   ├── scoring.md
│   │   ├── tiers.md
│   │   ├── quality.md
│   │   ├── security.md
│   │   ├── patterns.md
│   │   └── evolution.md
│   ├── reports/
│   └── design/
│
├── tests/                 # 测试 (300用例)
│   ├── unit/           # 100个单元测试
│   ├── business/       # 100个业务测试
│   ├── integration/     # 60个集成测试
│   └── e2e/           # 40个端到端测试
│
└── .github/
    └── workflows/
        ├── ci.yml
        └── pages.yml
```

---

## 三、文件合并清单

| 合并来源 | 合并目标 |
|----------|----------|
| `_state.sh, _workflow.sh, _actions.sh, _parallel.sh` | `orchestrator.sh` |
| `learner.sh, convergence.sh, _storage.sh, summarizer.sh` | `engine.sh` |
| `bootstrap.sh, integration.sh` | `bootstrap.sh` |
| `trigger_analyzer.sh, variance_analyzer.sh, dimension_analyzer.sh` | `analyzer.sh` |
| `html_reporter.sh, json_reporter.sh` | `report.sh` |
| `utils.sh, i18n.sh` | `utils.sh` |
| `constants.sh (两处)` | `constants.sh` |

---

## 四、脚本重命名清单

| 原名 | 新名 |
|------|------|
| `creator.sh` | `create.sh` |
| `evaluator.sh` | `evaluate.sh` |
| `restorer.sh` | `restore.sh` |
| `evolve_decider.sh` | `decider.sh` |
| `unified_scoring.sh` | `scoring.sh` |

---

## 五、删除清单

| 类型 | 路径 |
|------|------|
| 目录 | `.codex/` |
| 目录 | `.opencode/` |
| 文件 | `eval/BUGFIXES.md` |
| 文件 | `eval/DESIGN.md` |
| 文件 | `eval/RETROSPECTIVE.md` |
| 文件 | `reference/loader.sh` |
| 文件 | `reference/skill_reference.sh` |
| 目录 | `docs/technical/` |
| 文件 | `docs/WORKFLOWS.md` |
| 文件 | `docs/README.md` |
| 文件 | `engine/base.sh` |

---

## 六、测试用例分布 (300个)

| 类型 | 数量 | 说明 |
|------|------|------|
| 单元测试 | 100 | 按函数+边界条件 |
| 业务测试 | 100 | 按功能点+场景 |
| 集成测试 | 60 | 按用户场景 |
| 端到端 | 40 | 完整流程 |

**多LLM验证**: 100%覆盖，双LLM独立计算对比

### 6.1 单元测试用例 (100个)

| 模块 | 用例数 | 测试点 |
|------|--------|--------|
| constants.sh | 20 | GOLD/SILVER/BRONZE/REJECTED 各5个边界 |
| scoring.sh | 30 | 正常/边界/异常/精度 |
| utils.sh | 20 | 读写/权限/路径 |
| concurrency.sh | 15 | 获取/超时/释放/死锁 |
| errors.sh | 10 | 正常/异常/边界 |
| rollback.sh | 15 | 创建/回滚/损坏/并发 |

### 6.2 业务测试用例 (100个)

| 模块 | 用例数 | 测试点 |
|------|--------|--------|
| F1计算 | 25 | 完美/部分/全不中/边界/空输入 |
| MRR计算 | 15 | 1个/多个/无命中/边界 |
| 触发词识别 | 20 | CREATE/EVALUATE/RESTORE/SECURITY/OPTIMIZE |
| 解析验证 | 20 | 有效/缺YAML/缺section/有占位符 |
| 评分阈值 | 10 | BRONZE/SILVER/GOLD/PLATINUM边界 |
| 并行执行 | 10 | 正常/竞争/超时/死锁避免 |

### 6.3 集成测试用例 (60个)

| 场景 | 用例数 | 测试点 |
|------|--------|--------|
| CREATE | 15 | 正常/空输入/无效/并行/继承 |
| EVALUATE | 15 | 有效/无效/边界/并行 |
| OPTIMIZE | 10 | 单轮/多轮/收敛/发散/回滚 |
| RESTORE | 10 | 损坏/缺失/语法错误/并行 |
| SECURITY | 10 | 凭证/SQL注入/路径遍历/命令注入 |

### 6.4 端到端测试用例 (40个)

| 流程 | 用例数 | 测试点 |
|------|--------|--------|
| CREATE→EVALUATE | 10 | 正常/质量差/高质量 |
| CREATE→OPTIMIZE→EVALUATE | 10 | 提升/收敛/保持 |
| RESTORE→EVALUATE | 10 | 修复后达标/仍不达标 |
| 完整生命周期 | 10 | CREATE→EVALUATE→OPTIMIZE→SECURITY→RESTORE |

---

## 七、实施阶段 (19步)

| 阶段 | 任务 | 用例数 |
|------|------|--------|
| 1 | 删除临时文件 | - |
| 2 | 创建目录结构 | - |
| 3 | 合并lib/ (constants, utils, scoring) | - |
| 4 | 合并orchestrator/*.sh | - |
| 5 | 合并engine/*.sh | - |
| 6 | 合并eval/analyzer/*.sh | - |
| 7 | 合并eval/report/*.sh | - |
| 8 | 重命名脚本 | - |
| 9 | 移动文件到新目录 | - |
| 10 | 更新source路径 | - |
| 11 | 创建cli/skill入口 | - |
| 12 | 建设单元测试 (1-100) | +100 |
| 13 | 建设业务测试 (101-200) | +100 |
| 14 | 建设集成测试 (201-260) | +60 |
| 15 | 建设端到端测试 (261-300) | +40 |
| 16 | 多LLM验证框架 | - |
| 17 | 更新CI配置 | - |
| 18 | 测试验证 | - |
| 19 | 提交推送 | - |

---

## 八、CI配置

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run shellcheck
        run: find . -name "*.sh" -type f | xargs shellcheck || true

  unit-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: chmod +x cli/* tools/**/*.sh tests/**/*.sh
      - name: Run unit tests
        run: bash tests/unit/run_tests.sh
      - name: Multi-LLM verify
        run: bash tests/unit/verify.sh kimi-code minimax

  business-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: chmod +x cli/* tools/**/*.sh tests/**/*.sh
      - name: Run business tests
        run: bash tests/business/run_tests.sh
      - name: Cross-validate
        run: bash tests/business/cross_validate.sh

  integration-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: chmod +x cli/* tools/**/*.sh tests/**/*.sh
      - name: Run integration tests
        run: bash tests/integration/run_tests.sh
      - name: Multi-LLM verify
        run: bash tests/integration/multi_llm_verify.sh

  e2e-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: chmod +x cli/* tools/**/*.sh tests/**/*.sh
      - name: Run E2E tests
        run: bash tests/e2e/run_tests.sh
      - name: Multi-LLM verify
        run: bash tests/e2e/multi_llm_verify.sh

  eval-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run full eval
        run: bash tools/eval/main.sh --skill SKILL.md --fast --no-agent
```

---

## 九、验证清单

| 验证项 | 方法 | 预期 |
|--------|------|------|
| 临时文件已删除 | `find . -name ".codex" -o -name ".opencode"` | 无结果 |
| 脚本数量 | `find tools/ -name "*.sh" \| wc -l` | ~22 |
| CLI正常 | `./cli/skill help` | 输出帮助 |
| 单元测试 | `bash tests/unit/run_tests.sh` | 100个PASS |
| 业务测试 | `bash tests/business/run_tests.sh` | 100个PASS |
| 集成测试 | `bash tests/integration/run_tests.sh` | 60个PASS |
| 端到端测试 | `bash tests/e2e/run_tests.sh` | 40个PASS |
| 多LLM验证 | 全部测试 | 双LLM一致 |

---

## 十、风险与回滚

| 风险 | 缓解措施 |
|------|----------|
| 路径引用遗漏 | 分阶段验证，每步后运行测试 |
| 文件删除错误 | 先移动到临时目录，确认后再删除 |
| CI失败 | 保留旧配置，逐步替换 |

---

## 十一、重构后目标

- 文件数减少: ~57 → ~22 (减少61%)
- 目录层级: 4-5层 → 3层
- CLI入口: 9个 → 1个
- 测试用例: ~18 → 300个
- 多LLM验证: 100%覆盖
