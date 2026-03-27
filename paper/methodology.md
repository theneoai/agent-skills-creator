# Methodology: Multi-Agent Autonomous Skill Optimization

This section presents the methodological framework for autonomous skill optimization, termed the **Multi-Agent Autonomous Loop (MAAL)**. The framework integrates dual-track validation, parallel multi-agent execution, and iterative optimization cycles to achieve and maintain high-quality skill implementations. The methodology addresses three fundamental challenges in autonomous skill development: ensuring consistent quality across textual specification and runtime behavior, scaling evaluation through parallel agent architectures, and maintaining optimization momentum through principled decision rules.

## 1. Dual-Track Validation Framework

The dual-track validation framework constitutes the foundational evaluation infrastructure of the optimization system. This approach recognizes that skill quality cannot be adequately assessed through textual analysis alone; rather, a comprehensive evaluation must encompass both the documented specification and actual runtime behavior. The framework maintains two independent scoring channels that must converge for a skill to achieve certification.

### 1.1 Text Quality Scoring

Text quality evaluation employs a six-dimensional rubric that assesses the structural and content completeness of skill documentation. Each dimension carries a specific weight reflecting its relative importance to overall skill quality, derived from empirical analysis of optimization rounds spanning over 70 iterations across multiple skill domains.

| Dimension | Weight | Score Range | Excellence Criteria |
|-----------|--------|-------------|---------------------|
| System Prompt | 20% | 0–10 | §1.1 Identity + §1.2 Framework + §1.3 Thinking |
| Domain Knowledge | 20% | 0–10 | Quantitative benchmarks, specific case studies |
| Workflow | 20% | 0–10 | 4–6 phases with explicit Done/Fail criteria |
| Error Handling | 15% | 0–10 | Named failure modes, recovery steps, anti-patterns |
| Examples | 15% | 0–10 | 5+ scenarios with realistic inputs and outputs |
| Metadata | 10% | 0–10 | Frontmatter completeness, trigger alignment |
| Long-Context Handling | 10% | 0–10 | Chunking strategy, RAG accuracy, context preservation |

**Note:** Domain-specific weight adaptations are available for specialized skill categories (see Section 5.5).

The System Prompt dimension evaluates three mandatory subsections: the Identity section (§1.1) establishing the agent's role and expertise boundaries; the Framework section (§1.2) defining architectural components, available tools, and memory structures; and the Thinking section (§1.3) articulating cognitive processing patterns. Skills lacking any of these subsections receive a maximum ceiling of 6.0 regardless of other qualities, enforcing structural completeness as a prerequisite for excellence.

Domain Knowledge assessment prioritizes quantitative specificity over generic assertions. The rubric penalizes undefined references such as "McKinsey report" or "industry best practices" without supporting specifics. Excellence requires concrete data points including benchmarks (e.g., "128K context window"), named frameworks (e.g., "ReAct", "Chain-of-Thought"), and measurable outcomes (e.g., "16.7% error reduction"). This emphasis on specificity ensures that skills encode actionable knowledge rather than aspirational descriptions.

The Workflow dimension requires explicit definition of 4–6 processing phases, each accompanied by explicit Done criteria specifying conditions for phase completion and Fail criteria identifying irrecoverable error states. This formalization enables both human reviewers and automated systems to verify that skill execution follows defined pathways with unambiguous termination conditions.

Error Handling evaluation assesses coverage of named failure modes, documented recovery strategies, and identified anti-patterns. The rubric distinguishes between generic error messages and specific recovery procedures; a skill demonstrating "retry with exponential backoff" scores higher than one merely stating "handle errors gracefully."

Examples assessment requires minimum five scenarios with fully specified inputs, expected outputs, and verification steps. Generic scenarios receive lower scores than those containing realistic data structures, specific domain parameters, and explicit validation criteria enabling automated verification.

Metadata evaluation confirms frontmatter compliance with the agentskills specification, including name uniqueness, description accuracy, license specification, and version consistency. Additionally, the description field must correctly trigger pattern matching to ensure discoverability.

### 1.2 Runtime Effectiveness Scoring

Runtime evaluation operates through a separate scoring channel that validates actual skill behavior against expected specifications. This channel executes skill implementations under controlled conditions and measures behavioral fidelity to documented specifications. The runtime channel employs black-box testing methodology, invoking skills through standardized interfaces and assessing outputs against expected results without access to internal implementation details. This approach ensures that runtime evaluation measures genuine capability rather than merely confirming that code follows specified patterns.

The runtime evaluation protocol encompasses five validation categories, each targeting distinct behavioral aspects of skill functionality:

**Identity Consistency Verification** confirms that the executing skill maintains coherent self-representation across extended interactions. This verification proceeds by engaging the skill in extended conversation sequences designed to test identity boundaries. For example, prompts challenging the skill to adopt conflicting roles test whether the skill maintains its defined identity or exhibits boundary drift. Similarly, requests exceeding the skill's defined scope test whether appropriate boundary enforcement occurs. Skills exhibiting role confusion or boundary drift receive reduced scores on this dimension, with severity of confusion correlating with score penalty magnitude.

**Framework Execution Testing** validates that the skill correctly invokes specified tools, accesses defined memory structures, and follows documented architectural patterns. This testing category compares execution traces against expected patterns derived from the Framework section documentation. The test suite includes scenarios designed to exercise each documented tool, memory access pattern, and architectural component. Execution traces are captured and compared programmatically against expected patterns, with mismatches flagged as framework execution failures. Common failure modes include tools invoked with incorrect parameters, memory accessed in unexpected sequences, and processing pipelines diverging from documented flow.

**Output Actionability Assessment** measures the proportion of skill outputs that enable direct subsequent action. This assessment categorizes skill outputs along an actionability spectrum ranging from fully actionable (precise specifications enabling immediate execution) through partially actionable (direction provided but requiring additional specification) to non-actionable (vague or incomplete responses). Skills producing vague or incomplete responses receive lower scores than those generating precisely specified action items with necessary parameters. The assessment specifically penalizes responses containing hedging language ("might try", "consider perhaps"), missing parameter specifications, and ambiguous outcome descriptions.

**Knowledge Accuracy Verification** cross-references skill outputs against known factual corpora within the skill's domain. This validation detects hallucinations or outdated information that may have crept into skill specifications. The verification protocol presents the skill with factual queries from the domain knowledge base, comparing outputs against known correct answers. Knowledge accuracy is computed as the proportion of queries answered correctly, with significant penalties for confidently stated incorrect information (hallucinations) that may mislead users. This verification ensures that skills demonstrate genuine domain expertise rather than superficially plausible but factually incorrect content.

**Trace Compliance Analysis** validates that skill execution traces adhere to behavioral rules extracted from the skill's specification. This analysis module, inspired by the AgentPex methodology (arXiv:2603.23806), implements a behavioral rule extraction pipeline that parses the System Prompt and Framework sections to automatically derive executable compliance checks. The module operates through three phases: First, rule extraction identifies procedural constraints, workflow routing conditions, tool invocation preconditions, and prompt-specified behavioral guardrails from the skill documentation. Second, trace generation captures actual skill execution sequences including tool invocations, decision points, and workflow branching. Third, compliance evaluation compares extracted rules against observed trace behavior, detecting procedural failures such as workflow routing errors, unsafe tool invocations, and prompt-specified rule violations. The compliance score is computed as the proportion of trace evaluations where skill behavior matches extracted rules, with certification requiring ≥0.90 compliance. This verification ensures that skills not only produce correct outputs but follow prescribed operational protocols, addressing a critical gap in runtime validation where outcomes may appear acceptable while underlying procedures deviate from specifications.

**Conversation Stability Testing** evaluates skill performance across extended multi-turn interactions, measuring consistency of behavior, memory correctness over time, and absence of cumulative degradation patterns. This testing category engages skills in conversation sequences of at least 20 turns, tracking behavioral consistency and memory accuracy throughout. Memory correctness is assessed through reference to earlier conversation content, verifying that skills maintain appropriate context and recall relevant details. Cumulative degradation is detected by comparing early-turn performance against late-turn performance, identifying skills that perform well initially but degrade over extended interactions due to context management issues, state corruption, or resource exhaustion.

**Long-Document Stability Testing** evaluates skill performance on documents exceeding 100K tokens, assessing the ability to maintain quality and consistency when processing large-scale inputs. This testing category presents skills with extensive documents designed to stress-test context management capabilities, measuring three key dimensions: context chunking effectiveness (how well the skill segments large documents into processable units while preserving semantic coherence), information retrieval accuracy across chunks (whether the skill can accurately locate and引用 information distributed throughout the document), and preservation of cross-references (whether the skill correctly handles references, citations, and dependencies that span multiple chunks or sections).

### 1.3 Variance Control

Variance between text score and runtime score constitutes a critical quality indicator reflecting the degree of alignment between documented specifications and actual implementation behavior. The certification formula requires:

```
CERTIFIED = (Text Score ≥ 8.5) AND (Runtime Score ≥ 8.5) AND (Variance < 1.5)
```

Variance exceeding 1.0 indicates disagreement between documented specification and actual behavior—a condition termed **specification-behavior divergence**. Variance exceeding 2.0 triggers immediate red-flag status, indicating either excellent documentation of poor implementation or poorly documented but accidentally functional implementation. Neither state represents acceptable skill quality.

The variance control mechanism operates as a gatekeeper preventing premature certification. Skills achieving high text scores but low runtime scores must undergo runtime hardening—enhancing actual behavioral fidelity to match documented specifications. Conversely, skills with excellent runtime behavior but poor documentation must undergo specification enrichment—improving documentation to accurately represent existing capabilities. Only convergence between both tracks enables certification.

The variance computation itself follows a symmetric absolute difference formulation: Variance = |Text Score - Runtime Score|. This formulation treats over-documentation (text exceeds runtime) and under-documentation (runtime exceeds text) as equally problematic, ensuring neither direction of divergence proceeds unchecked. In practice, over-documentation may indicate skills describing aspirational capabilities not yet implemented, while under-documentation indicates implemented capabilities not yet captured in documentation.

Stability checks complement variance control by ensuring evaluation consistency across multiple runs. The stability verification protocol runs each evaluation three times and confirms identical results, detecting non-deterministic evaluation behavior that might compromise score reliability. Trigger match consistency checks verify that different evaluation scripts agree on pattern matching within a tolerance of two mismatches, ensuring consistent interpretation of trigger definitions across the evaluation infrastructure.

## 2. Multi-Agent Parallel Optimization

The multi-agent architecture decomposes the optimization problem across five specialized agent types, each responsible for evaluating and improving specific skill aspects. This specialization enables parallel execution while maintaining evaluation comprehensiveness.

### 2.1 Agent Type Specifications

**Security Agent** maintains responsibility for anti-pattern detection, injection risk identification, and data leakage prevention. This agent implements validation gates aligned with OWASP guidelines and Common Weakness Enumeration (CWE) standards. Specific checks include detection of hardcoded credentials (CWE-798), command injection vectors (CWE-77), improper input validation (CWE-20), and path traversal vulnerabilities. The Security Agent implements a comprehensive security review protocol encompassing five distinct validation pathways: injection risk detection scanning for eval(), exec(), and system() calls that may execute attacker-controlled input; data exposure scanning identifying hardcoded API keys, passwords, and tokens that may leak credentials; privilege escalation detection identifying improper use of administrative or elevated privileges; and path traversal validation confirming proper sanitization of file paths before access operations. The Security Agent carries P0 priority—security issues require immediate remediation regardless of other quality dimensions, and no certification may proceed with unresolved security findings.

**Trigger Agent** focuses on pattern recognition accuracy and trigger coverage. This agent parses skill trigger definitions across four pattern categories (CREATE, EVALUATE, RESTORE, TUNE) and verifies accurate matching against expected invocation scenarios. The Trigger Agent implements a systematic coverage analysis protocol that examines each defined trigger pattern against a corpus of valid and invalid invocation samples. For CREATE patterns, the agent verifies that skill creation requests trigger appropriate responses; for EVALUATE patterns, it confirms that assessment requests correctly invoke evaluation logic; for RESTORE patterns, it validates that recovery requests activate restoration procedures; and for TUNE patterns, it ensures that optimization requests engage tuning mechanisms. Trigger accuracy metrics measure the proportion of correctly matched invocations against total invocations, with certification requiring ≥99% accuracy. The agent additionally detects trigger ambiguity where multiple patterns may match identical inputs, flagging such conditions for clarification to prevent routing uncertainty.

**Runtime Agent** conducts runtime verification through actual skill execution. This agent implements the runtime scoring protocol, measuring identity consistency across extended interactions where skills must maintain coherent self-representation without role confusion or boundary drift; framework execution fidelity validating correct tool invocation, memory structure access, and architectural pattern adherence; output actionability measuring the proportion of skill outputs enabling direct subsequent action with precisely specified parameters; knowledge accuracy cross-referencing outputs against domain-specific factual corpora to detect hallucinations or outdated information; and conversation stability evaluating sustained performance quality across multi-turn interactions without cumulative degradation. The Runtime Agent produces runtime scores feeding into the dual-track validation system, serving as the primary behavioral assessment channel.

**Quality Agent** computes composite quality scores through weighted aggregation of multiple evaluation dimensions. This agent implements the six-dimensional rubric, coordinates with other agents for specialized assessments, and calculates variance metrics for certification determination. The Quality Agent serves as the central aggregation point for evaluation results, receiving outputs from Security, Trigger, Runtime, and EdgeCase agents, then computing the weighted composite scores that feed into the certification determination logic. Additionally, the Quality Agent maintains scoring consistency across multiple evaluation runs, detecting drift in scoring behavior that may indicate non-deterministic evaluation or corpus updates affecting accuracy measurements.

**EdgeCase Agent** analyzes boundary conditions and exception handling through systematic injection of adversarial inputs. Test scenarios include empty input injection testing skill behavior when receiving null or blank inputs; extreme value testing with boundary parameters such as maximum lengths, minimum values, and overflow conditions; contradictory instruction sequences presenting logically inconsistent requests to evaluate error handling; role confusion attempts presenting conflicting role definitions to test identity stability; and resource limit scenarios with zero budgets, minimal timelines, or restricted tool access. The EdgeCase Agent produces resilience scores indicating skill robustness under exceptional conditions, identifying specific failure modes and documenting recovery strategies observed during adversarial testing.

### 2.2 Parallel Execution Architecture

The orchestration architecture employs a hierarchical model where an aggregator coordinates parallel execution across specialized agents. This design enables simultaneous evaluation across multiple dimensions, reducing total evaluation time from the sequential sum of individual evaluations to approximately the duration of the longest single evaluation. The architecture maintains comprehensive coverage by ensuring each specialized agent performs thorough evaluation within its domain while the aggregator synthesizes findings into coherent composite assessments.

```
                      ┌─────────────────┐
                      │   Orchestrator  │
                      └────────┬────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│   Security    │      │    Trigger    │      │    Runtime    │
│    Agent     │      │     Agent     │      │     Agent     │
└───────┬───────┘      └───────┬───────┘      └───────┬───────┘
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│    Quality    │      │   EdgeCase   │      │  (Results     │
│     Agent     │      │    Agent     │      │  Aggregation) │
└───────┬───────┘      └───────┬───────┘      └───────────────┘
        │                      │
        └──────────────┬───────┘
                       ▼
                ┌─────────────┐
                │  Aggregator  │
                └─────────────┘
```

The Orchestrator component serves as the entry point for evaluation requests, managing the overall evaluation lifecycle including initialization, coordination, and result collection. Upon receiving an evaluation request, the Orchestrator broadcasts task specifications to all specialized agents, monitors execution progress, handles timeouts and failures, and aggregates results upon completion. The Orchestrator implements retry logic for failed agent executions, ensuring evaluation robustness against transient failures.

The Security, Trigger, and Runtime agents execute as first-tier parallel workers, each performing specialized evaluation within its domain. These agents operate concurrently upon receiving task specifications, with execution times varying based on evaluation complexity. The Security Agent typically requires 15–30 seconds due to comprehensive scanning requirements; the Trigger Agent requires approximately 5–10 seconds for pattern matching validation; the Runtime Agent requires 30–60 seconds for execution-based testing.

The Quality and EdgeCase agents execute as second-tier workers, receiving inputs from the first-tier agents and performing synthesis and adversarial testing respectively. The Quality Agent aggregates dimensional scores from the six-dimensional rubric, combining its independent assessment with findings from specialized agents. The EdgeCase Agent receives skill specifications and generates adversarial test scenarios, executing these tests to assess resilience under exceptional conditions.

The Aggregator component implements weighted combination rules synthesizing agent findings into composite assessments. The weighting schema reflects empirical analysis of agent reliability and importance: Quality Agent contributions receive 30% weight as the primary quality assessment mechanism; Runtime Agent contributions receive 25% weight as the behavioral validation channel; and specialized agents (Security, Trigger, EdgeCase) each receive 15% weight reflecting their supporting but non-exclusive domains. This weighting ensures that primary quality assessment dominates while specialized findings appropriately influence final determinations.

Human-agent collaboration achieves better results than pure autonomous optimization. The c-CRAB methodology finds that autonomous agents alone achieve only 40% pass rate on skill certification tasks. Integrating human expert review as a supplementary validation track—particularly when autonomous optimization plateaus—significantly improves success rates. This hybrid approach leverages both the scalability of autonomous agents and the nuanced judgment of human experts.

### 2.3 Conflict Resolution Mechanisms

When multiple agents produce conflicting findings—particularly when different evaluation scripts assign divergent scores to identical dimensions—the system employs a structured resolution protocol.

**Score Conflict Resolution**: When multiple evaluation paths produce scores differing by less than 1.5 points, the system flags the inconsistency for investigation but accepts the average. When divergence exceeds 1.5 points, the system defaults to the lower score as a conservative measure and logs the discrepancy for manual review.

**Priority Conflict Resolution**: When multiple issues compete for remediation resources, a priority matrix governs allocation:

| Issue Type | Priority | Resolution Timeline |
|------------|----------|-------------------|
| Security vulnerability | P0 | Immediate |
| Runtime crash | P1 | Within 24 hours |
| Trigger misalignment > 20% | P2 | Within 48 hours |
| Quality score < 7.0 | P3 | Within 72 hours |
| Edge case failure | P4 | Next iteration |

**Suggestion Conflict Resolution**: When agents propose contradictory modifications, precedence follows security-critical paths. Security suggestions override Runtime suggestions, which override Quality suggestions. Among suggestions of equal precedence, the more conservative (smaller change) takes priority to minimize introduction of new failure modes.

## 3. The Autonomous Loop

The autonomous optimization loop constitutes the core operational mechanism driving skill improvement. This eight-step cycle repeats iteratively, each iteration either improving skill quality or resetting to the prior state. The loop operates without human intervention in tuning mode, executing experiments and evaluating results continuously until reaching target quality, encountering resource limits, or detecting stuck states.

### 3.1 Eight-Step Cycle Architecture

**Step 1: READ** — The system reads the current skill state by executing the scoring script and parsing dimensional scores. Output provides per-dimension scores with warnings indicating specific deficiencies (e.g., "⚠generic-content" for domain knowledge, "⚠no-recovery" for error handling). The READ step establishes the baseline for subsequent analysis. The scoring script output format provides each dimension with its raw score, weight multiplier, and any warnings indicating specific deficiency categories. For example, a skill with generic domain knowledge content produces output showing "Domain Knowledge 6/10 (×0.20) ⚠generic-content", enabling targeted remediation by clearly identifying the deficiency type. The READ step additionally captures overall composite scores and variance metrics, providing complete state information for the subsequent analysis phase.

**Step 2: ANALYZE** — The system identifies the single highest-priority improvement opportunity through a deterministic selection algorithm. Priority rules prioritize dimensions scoring below 6.0 (the minimum acceptable floor), then dimensions with higher weights (System Prompt at 20% takes precedence over Domain Knowledge at 20%, which takes precedence over Workflow at 20%), and finally rotate among tied dimensions based on loop round to prevent systematic bias that might neglect certain dimensions across extended optimization runs. The Analyze step outputs a specific weakness dimension and the specific deficiency type within that dimension. For System Prompt deficiencies, the algorithm distinguishes between missing §1.1 Identity, missing §1.2 Framework, missing §1.3 Thinking, and insufficient constraint specification. For Domain Knowledge, it distinguishes between missing quantitative benchmarks, missing named framework references, and insufficient case study coverage.

**Step 3: CURATION** — The system periodically reviews and consolidates accumulated optimization knowledge. This step addresses the "context collapse" problem identified in the ACE Framework by removing redundant or conflicting improvements and preserving essential insights before the next optimization cycle. During curation, the system examines the history of applied modifications, identifies patterns in successful improvements, eliminates contradictory or redundant knowledge entries, and maintains a clean semantic foundation for subsequent analysis. This prevents accumulation of conflicting heuristics that can degrade decision quality in later iterations.

**Step 4: PLAN** — The system selects an improvement strategy targeting the identified weakness through a deterministic mapping function. Strategies are implemented as switch-case logic mapping weakness types to specific remediation approaches. For example, "missing §1.1 Identity" maps to adding an Identity section with role definition, expertise boundaries, and behavioral constraints; "missing §1.2 Framework" maps to adding architectural definitions including tool specifications, memory structure definitions, and processing pipeline documentation; "missing §1.3 Thinking" maps to adding cognitive process documentation including decision frameworks and reasoning patterns. For Domain Knowledge, "generic-content" maps to replacing vague assertions with specific benchmarks, named frameworks, and measurable outcomes. The planning phase selects the most impactful single improvement to apply, ensuring clear attribution of subsequent score changes to specific modifications.

**Step 5: IMPLEMENT** — The system applies the planned modification to the skill file. Changes are isolated to the targeted dimension to enable clear attribution of subsequent score changes. The implementation phase employs atomic modifications, changing only the specific subsection identified in the analysis phase rather than making multiple simultaneous changes. This isolation ensures that observed score changes can be confidently attributed to the intended modification rather than confounding interactions between multiple simultaneous changes. Implementation includes pre-modification validation confirming the skill file remains syntactically valid and structurally compliant with the agentskills specification.

**Step 6: VERIFY** — The system re-runs scoring to measure improvement effect. The new score is compared against the baseline using decision rules. Verification executes the same scoring pipeline used in the READ step, ensuring comparable measurement conditions. The comparison extracts dimensional scores for both baseline and post-modification states, computing the delta for each dimension as well as the composite score delta. This granular comparison enables the decision rules to distinguish between genuine improvements in the targeted dimension versus incidental score changes in unrelated dimensions.

**Step 7: HUMAN_REVIEW** — Optional expert review for skills that remain below 8.0 after 10 optimization rounds. This step provides human feedback as an additional validation track when autonomous optimization plateaus. Human feedback is integrated as supplementary input weighted appropriately when the autonomous loop fails to achieve further improvement. This hybrid approach leverages both the scalability of autonomous agents and the nuanced judgment of human experts.

**Step 8: LOG** — The system records iteration results to the results log (results.tsv), including round number, new score, delta from baseline, keep/discard status, weakest dimension, and improvement applied. Logging enables subsequent analysis of optimization trajectories. The log format supports subsequent analysis including optimization trajectory visualization, improvement rate computation, and stuck state detection. Each log entry captures the complete state necessary for reconstructing the optimization history, including the specific modification applied and the outcome observed.

**Step 9: COMMIT** — Every ten rounds, the system commits changes to version control with a descriptive message summarizing the optimization progress. This provides checkpoint recovery capability and maintains an audit trail of the optimization process. Commit messages follow a structured format indicating the optimization phase, score progress, and specific dimensional improvements achieved. The commit frequency balances between providing adequate recovery points and avoiding excessive version control noise. Between commits, changes accumulate in the working directory, enabling the optimizer to build upon recent improvements before checkpointing.

### 3.2 Decision Rules

The decision rules govern whether to retain or discard each experimental modification:

| Score Change | Decision | Rationale |
|--------------|----------|----------|
| +0.1 or greater | Keep | Improvement detected, proceed with modified state |
| Same (within ±0.05) | Reset | No improvement, revert to baseline |
| Worse (any decrease) | Reset | Regression detected, revert immediately |
| Crashed/Broken | Fix or Skip | Validation failed, restore before continuing |

The +0.1 threshold prevents acceptance of trivial improvements while capturing meaningful advancement. The immediate reset on regression prevents accumulation of detrimental modifications. Complexity considerations supplement these rules: modifications achieving +0.1 score through addition of excessive complexity (defined as >50 lines of code for a single improvement) are flagged as "not worth complexity" and skipped even if technically improving scores.

### 3.3 Anti-Pattern Detection

The system maintains detection logic for common optimization failure patterns:

**Scoring Anti-Patterns**: Generic content patterns (undefined brand references, vague benchmarking claims), flat structure violations (all content in single file exceeding 300 lines), wrong tier assignment (complex skills underspecified as lite), thin examples (fewer than 5 scenarios), high variance indicating spec-behavior divergence, and gaming patterns (keyword stuffing, suspicious repetition).

**Iteration Anti-Patterns**: Non-deterministic selection (using RANDOM instead of targeting weakest dimension), failure to reset on regression, prompting for permission in autonomous mode, premature shipping (certification before reaching 9.0), and over-engineering (excessive complexity for minimal gain).

**Security Anti-Patterns**: Hardcoded secrets (API keys, passwords, tokens), eval/exec usage introducing injection vectors, missing path validation, absent timeouts on long-running operations, and missing circuit breakers enabling cascading failures.

**Stability Anti-Patterns**: Trigger inconsistency across scripts, score divergence between evaluation versions, and non-idempotent evaluation producing different results on identical inputs.

Detection of any anti-pattern triggers specific remediation protocols: gaming patterns cause immediate rejection with score penalty; security patterns block certification pending remediation; iteration anti-patterns cause loop reconfiguration.

## 4. Metric System

The metric system establishes quantitative targets ensuring optimization efforts achieve meaningful quality thresholds. These metrics operate across multiple levels, from dimensional scores to composite evaluations to system-wide stability measures. The hierarchical metric structure enables granular diagnosis of quality issues while maintaining clear targets for overall optimization success.

### 4.1 Primary Quality Metrics

**Text Quality Score** represents the weighted composite of seven dimensional evaluations computed as the sum of dimension scores multiplied by their respective weights, normalized to a 0–10 scale. Certification requires Text Score ≥ 8.0, with each dimension maintaining minimum floor values preventing degradation below acceptable thresholds. The floor enforcement mechanism operates as a hard constraint: any dimension falling below its floor immediately disqualifies the skill from certification regardless of composite score. System Prompt, Domain Knowledge, and Workflow dimensions carry 6.0 floors reflecting their foundational importance; Error Handling, Examples, Metadata, and Long-Context Handling dimensions carry 5.0 floors reflecting their supporting but secondary roles.

**Runtime Quality Score** represents the composite of six runtime validation categories: identity consistency, framework execution fidelity, output actionability, knowledge accuracy, conversation stability, and long-document stability. Each category receives equal weighting within the composite computation, reflecting their approximately equivalent importance to overall runtime quality. The Runtime Score provides the behavioral channel of dual-track validation, complementing the documentary assessment of the Text Score.

**F1 Score** measures the balance between precision and recall in skill trigger matching. Precision measures the proportion of skill activations that correctly match the intended trigger; recall measures the proportion of intended triggers that successfully activate the skill. The ≥0.90 threshold ensures skills respond correctly to intended invocations while avoiding false positives on unrelated inputs. F1 represents the harmonic mean of precision and recall, penalizing imbalance between the two measures even when one remains high.

**Mean Reciprocal Rank (MRR)** measures multi-turn conversation quality by evaluating whether correct responses appear in appropriate positions within response rankings. For each conversation turn, MRR computes the reciprocal of the rank position where the correct response appears, then averages across all turns. A perfect MRR of 1.0 indicates correct responses always appear in first position; MRR of 0.5 indicates correct responses average second position. The ≥0.85 threshold ensures skills maintain contextual appropriateness across conversation sequences, providing coherent multi-turn interactions rather than isolated single-turn responses.

**MultiTurn Pass Rate** measures the proportion of multi-turn interactions completed successfully without degradation. A conversation is counted as passing if all turns produce acceptable responses and the overall interaction achieves its intended outcome. The ≥85% threshold ensures sustained quality across extended interactions rather than merely single exchanges. This metric particularly penalizes skills that perform well initially but degrade over extended use, indicating memory or state management issues.

**Trace Compliance Score** measures the proportion of trace evaluations where skill behavior matches extracted behavioral rules. Following the AgentPex methodology (arXiv:2603.23806), this metric extracts procedural rules from the skill's System Prompt and Framework sections, then evaluates execution traces against these rules. The score ranges from 0 to 1, with certification requiring ≥0.90. This metric complements outcome-based evaluation by ensuring that skills not only produce correct results but follow prescribed operational procedures.

### 4.2 Specialized Accuracy Metrics

**Trigger Accuracy** measures pattern recognition precision across all four trigger categories (CREATE, EVALUATE, RESTORE, TUNE). The ≥99% threshold reflects the criticality of accurate trigger routing—misaligned triggers cause skills to execute inappropriate behaviors or fail to respond to valid invocations, both representing significant quality failures. Trigger accuracy is computed as the proportion of correctly matched invocations across a standardized test corpus of 1000 invocation samples per trigger category. The test corpus includes both positive examples (valid invocations that should match) and negative examples (invalid invocations that should not match), ensuring the metric captures both precision and recall aspects of trigger performance.

The four trigger categories serve distinct functional purposes within the skill ecosystem. CREATE triggers activate when users request new skill generation, routing to appropriate creation workflows. EVALUATE triggers activate during quality assessment requests, invoking evaluation logic. RESTORE triggers activate when recovering from failures or requesting rollback to prior states. TUNE triggers activate during optimization requests, engaging automated improvement mechanisms. Each category requires distinct pattern matching logic, and the trigger accuracy metric ensures each category achieves required precision independently.

**Stability** measures consistency of skill behavior across multiple evaluation runs, ensuring that scores reflect genuine quality differences rather than evaluation randomness or non-determinism. The ≥95% threshold ensures non-idempotent evaluation does not compromise reproducibility. Stability is computed as the proportion of runs producing identical primary scores across three consecutive executions. A skill achieving stability of 95% or higher produces consistent scores across repeated evaluations, enabling reliable comparison between optimization iterations and reproducible quality assessments.

Stability measurement distinguishes between acceptable variance within measurement noise and concerning variance indicating behavioral inconsistency. Small fluctuations within ±0.05 points are considered measurement noise and do not affect stability scores; larger fluctuations indicate genuine behavioral variability requiring investigation. Common causes of instability include reliance on external services with variable response times, non-deterministic ordering in parallel processing, and insufficient initialization of stateful components.

**Variance** measures specification-behavior divergence as defined in Section 1.3. The <1.0 threshold for certification ensures text and runtime scores agree sufficiently to confirm that documentation accurately represents implementation. Variance exceeding the threshold indicates either documentation describing capabilities not actually implemented or implementation containing capabilities not documented. Both conditions represent quality deficiencies: the former may mislead users about available functionality, while the latter may cause unexpected behavior when users rely on undocumented capabilities.

### 4.3 Certification Formula

Full certification requires satisfaction of all metric thresholds simultaneously, enforcing comprehensive quality across all evaluation dimensions rather than permitting excellence on subset of dimensions:

```
CERTIFIED = (Text ≥ 8.0) AND (Runtime ≥ 8.0) AND (Variance < 2.0) 
            AND (F1 ≥ 0.90) AND (MRR ≥ 0.85) AND (MultiTurnPassRate ≥ 85%)
            AND (TriggerAccuracy ≥ 99%) AND (Stability ≥ 95%)
            AND (LongContextScore ≥ 8.0)
            AND (TraceCompliance ≥ 0.90)
            AND (HumanScore ≥ 7.0 OR Rounds > 10)
```

The HumanScore condition enables certification for skills that incorporate human expert review, even if autonomous optimization alone cannot achieve the required thresholds. This hybrid approach reflects the c-CRAB finding that human-agent collaboration achieves better outcomes than pure autonomous optimization—agents alone achieve only 40% pass rate, while human feedback integration significantly improves success rates.

The conjunction of these requirements ensures that certification reflects genuine comprehensive quality rather than excellence on subset of dimensions while neglecting others. The certification formula implements an "all-or-nothing" approach: a skill achieving 9.5 on Text Score but 7.9 on Runtime Score fails certification despite impressive documentary quality. This approach prevents the common failure mode where optimization efforts concentrate on easily-measured dimensions while neglecting harder-to-measure aspects.

The threshold values were derived empirically through analysis of optimization rounds 52–70 on the skill-manager skill. These rounds documented the relationship between dimensional scores and observed skill quality as assessed through manual review. The 8.0 threshold for Text and Runtime scores corresponds to the transition point where manual reviewers consistently rated skills as "production-ready" rather than "needs improvement." The 0.90 F1 threshold corresponds to trigger accuracy below which users reported noticeable invocation failures. The 0.85 MRR threshold corresponds to multi-turn conversations becoming frustrating due to contextual breaks.

Certification operates as a binary determination with three possible outcomes: CERTIFIED indicating all thresholds satisfied, PROVISIONAL indicating some thresholds satisfied but others requiring remediation within specified timeframes, and REJECTED indicating fundamental quality issues preventing certification. PROVISIONAL status permits deployment with documented limitations, while REJECTED status requires complete remediation before any deployment consideration.

Beyond basic certification, the methodology defines three quality tiers reflecting increasing quality levels:

EXEMPLARY status requires Overall score ≥ 9.0 with all dimensions ≥ 8.0, indicating skills serving as benchmarks for other skill development. EXEMPLARY skills have demonstrated sustained quality across extended optimization and represent the highest quality tier in the framework.

CERTIFIED status requires satisfaction of all certification formula thresholds, indicating production-ready skills meeting established quality standards. CERTIFIED skills may be deployed in production environments with appropriate monitoring.

ACCEPTABLE status requires Text Score ≥ 6.0 and Runtime Score ≥ 6.0, indicating skills functional but requiring improvement before production deployment. ACCEPTABLE skills provide basic functionality and may be used in development or testing contexts.

Skills falling below ACCEPTABLE thresholds are classified as BELOW STANDARD, indicating fundamental quality issues requiring substantial remediation before any deployment consideration.

## 5. Integration Architecture

The methodology integrates with existing skill management infrastructure through a defined script mapping architecture that enables interoperability between specialized evaluation and optimization components. The integration layer ensures that modifications to one component propagate correctly through the evaluation pipeline without introducing inconsistencies or compatibility regressions.

### 5.1 Script Component Mapping

The scoring subsystem comprises multiple complementary scripts providing overlapping evaluation coverage with distinct methodological approaches:

The `score.sh` script implements the primary text quality scoring through heuristic analysis of skill documentation structure and content. This script parses skill files according to the six-dimensional rubric, computing weighted composites and generating deficiency warnings for specific content issues. The heuristic approach enables rapid evaluation without external model dependencies, providing baseline quality assessment within approximately five seconds.

The `score-v2.sh` script provides enhanced scoring incorporating consistency checking and executability validation. This script extends the base rubric with additional validation dimensions including internal consistency analysis across sections and verification that documented behaviors align with available tool definitions. The v2 scoring tends to produce more conservative estimates than base scoring, with typical divergence of 0.5–1.5 points.

The `score-secure.sh` script implements comprehensive security evaluation including anti-injection pattern detection, credential exposure scanning, and privilege escalation vulnerability identification. This script requires longer execution time (15–30 seconds) due to the complexity of security checks, but provides essential validation preventing certification of insecure skill implementations.

The `score-v3.sh` script implements runtime execution testing through actual skill invocation under controlled conditions. This script exercises skill behavior against test scenarios, measuring response accuracy, behavioral consistency, and error handling quality. The runtime validation approach provides empirical evidence of skill capabilities beyond documentary assessment.

The `score-multi.sh` script implements multi-LLM cross-validation using both GPT-4o and Claude models for truth detection. This script distributes evaluation across two frontier models, combining results with anti-gaming detection to prevent score inflation through manipulation. The multi-LLM approach typically requires 60 seconds due to external API calls, but provides highest confidence evaluation by cross-checking assessments across different model architectures.

### 5.2 Validation Pipeline Integration

The validation pipeline coordinates execution across scoring scripts to ensure comprehensive evaluation without redundant processing. Pipeline orchestration follows a staged approach: structural validation precedes content evaluation, content evaluation precedes security scanning, and all evaluations precede certification determination.

The `validate.sh` script confirms structural compliance with the agentskills specification before advanced evaluation proceeds. This gate prevents wasted computation on malformed skills and ensures subsequent evaluations operate on valid inputs. Validation checks include frontmatter completeness, section structure integrity, and format compliance.

The `runtime-validate.sh` script orchestrates runtime verification, executing skill implementations under test conditions and capturing behavioral traces for analysis. This script implements the five-category runtime evaluation protocol, generating scores for identity consistency, framework execution, output actionability, knowledge accuracy, and conversation stability.

The `edge-case-check.sh` script executes adversarial testing scenarios against skill implementations, documenting resilience under exceptional conditions. This script systematically injects boundary conditions, contradictory inputs, and resource constraints, generating resilience metrics and specific failure mode documentation.

### 5.3 Optimization Loop Integration

The `tune.sh` script implements the autonomous optimization loop, orchestrating the eight-step cycle across continuous iterations until reaching target quality or encountering termination conditions. The script accepts configuration parameters controlling maximum rounds, target quality thresholds, and operational mode (quick, standard, or deep).

The `certify.sh` script implements final certification determination, validating that all metric thresholds are satisfied simultaneously. Certification requires positive determination across all gates: structural completeness, content quality, security compliance, runtime effectiveness, variance control, and stability maintenance.

### 5.4 Operational Modes

The integration supports three operational modes calibrated to different optimization scenarios:

**Quick Tune Mode** executes 10 rounds of optimization with aggressive improvement selection, designed for rapid quality improvement on skills already approaching acceptable quality. This mode sacrifices comprehensive exploration for speed, suitable for final polish before deployment or addressing regressions discovered during monitoring.

**Standard Mode** executes 50 rounds of optimization, providing balanced exploration versus speed for typical optimization scenarios. This mode follows the full optimization trajectory from initial state through certification, with appropriate checkpointing and evaluation density to ensure quality gains are genuine rather than artifacts.

**Deep Mode** executes 100 rounds of optimization for exhaustive exploration of the improvement space. This mode addresses skills requiring substantial enhancement or reaching for EXEMPLARY status beyond basic certification. Deep mode may reveal marginal improvement opportunities inaccessible through shorter optimization runs, though at significant time cost.

### 5.5 Domain-Specific Scoring Variants

The six-dimensional rubric supports domain-specific weight adaptations to optimize evaluation focus for different skill categories:

| Skill Type | Primary Weight Adjustments |
|------------|---------------------------|
| **Code Skills** | Workflow 25%, Error Handling 20%, Examples 20%, System Prompt 15%, Domain Knowledge 10%, Metadata 10% |
| **Document Skills** | Long-Context 20%, Domain Knowledge 25%, System Prompt 15%, Workflow 15%, Error Handling 15%, Examples 10% |
| **Creative Skills** | Examples 25%, System Prompt 20%, Workflow 15%, Domain Knowledge 15%, Error Handling 15%, Metadata 10% |

**Code Skills** emphasize procedural rigor and error recovery, reflecting the critical importance of deterministic behavior and robust exception handling in programmatic contexts.

**Document Skills** prioritize depth of knowledge and contextual understanding, recognizing that effective document processing requires extensive domain expertise and sustained comprehension across long inputs.

**Creative Skills** value illustrative examples and expressive system prompts, acknowledging that creative generation depends heavily on clear behavioral guidance and diverse demonstration scenarios.

## 6. Conclusion

The Multi-Agent Autonomous Loop methodology provides a principled approach to skill optimization that balances comprehensiveness with efficiency. The dual-track validation framework ensures documentation and implementation remain aligned; the multi-agent architecture enables parallel evaluation across specialized dimensions; the autonomous loop drives continuous improvement without requiring constant human guidance; and the metric system establishes clear quality targets with verifiable thresholds. Together, these components create an optimization system capable of achieving and maintaining CERTIFIED and EXEMPLARY skill quality through autonomous operation.

---

*Document Version: 1.0*  
*Methodology derived from autonomous optimization rounds 52–70 on skill-manager*  
*Date: 2026-03-27*
