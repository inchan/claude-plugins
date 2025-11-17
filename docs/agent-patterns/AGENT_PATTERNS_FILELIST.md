# 5 Agent Pattern Skills - Comprehensive File Listing

Based on Anthropic's "Building Effective Agents" Document
Reference: https://www.anthropic.com/engineering/building-effective-agents

## Summary

All 5 agent pattern skills have been successfully implemented in the `/home/user/cc-skills/skills/` directory. All skills explicitly reference the Anthropic "Building Effective Agents" document in their SKILL.md files.

---

## 1. PROMPT CHAINING / Sequential Task Processor

**Base Path:** `/home/user/cc-skills/skills/sequential-task-processor/`

**Anthropic Reference:** ✓ Explicit reference in SKILL.md (lines 3, 12)
- Pattern Name: Prompt Chaining
- Description: "Implements Anthropic's Prompt Chaining pattern from 'Building Effective Agents'"

### Directory Structure
```
sequential-task-processor/
├── SKILL.md                          (Main skill definition - 11.2 KB)
├── config.json                        (Configuration - 4.0 KB)
├── integration.py                     (Integration module - 10.8 KB)
├── assets/
│   └── templates/
│       ├── architecture.md.tmpl      (Architecture design template - 11.0 KB)
│       ├── requirements.md.tmpl      (Requirements template - 5.3 KB)
│       └── validation.md.tmpl        (Validation template - 10.8 KB)
├── examples/
│   └── web_app_example.md            (Complete example - 19.2 KB)
└── scripts/
    └── step_validator.py             (Validation script - 13.7 KB)
```

### Key Files
- **SKILL.md**: Comprehensive skill definition implementing Prompt Chaining
- **config.json**: Step templates, validation rules, integration settings
- **integration.py**: Integration module for inter-skill communication
- **Templates**: Markdown templates for requirements, architecture, validation
- **Validator**: Python script for step-by-step validation gates

### Main Concepts
- Sequential decomposition (3-7 steps)
- Validation gates between steps
- Artifact management with caching
- Integration with Router, Orchestrator, Evaluator

---

## 2. ROUTING / Intelligent Task Router

**Base Path:** `/home/user/cc-skills/skills/intelligent-task-router/`

**Anthropic Reference:** ✓ Explicit reference in SKILL.md (lines 3, 12) and config.json (line 81)
- Pattern Name: Routing
- Description: "Implements the Routing pattern from Anthropic's Building Effective Agents methodology"
- **Direct URL in config.json:** `https://www.anthropic.com/engineering/building-effective-agents`

### Directory Structure
```
intelligent-task-router/
├── SKILL.md                          (Main skill definition - 12.2 KB)
├── config.json                        (Configuration with metadata - 2.3 KB)
├── integration.py                     (Integration module - 7.5 KB)
├── classifiers/
│   ├── keyword_classifier.py         (Keyword-based classification - 6.9 KB)
│   ├── intent_classifier.py          (Intent detection - 5.6 KB)
│   └── complexity_analyzer.py        (Complexity analysis - 6.9 KB)
├── routing_rules/
│   ├── categories.yaml               (Category definitions - 3.4 KB)
│   └── skill_mapping.json            (Skill routing rules - 2.2 KB)
├── templates/
│   └── clarification_request.md      (Clarification template - 1.1 KB)
└── examples/
    ├── bug_fix_routing.md            (Bug fix example - 1.7 KB)
    └── feature_routing.md            (Feature example - 2.8 KB)
```

### Key Files
- **SKILL.md**: Complete routing pattern implementation
- **config.json**: Metadata with direct Anthropic URL reference
- **classifiers/**: Three Python classifiers for task analysis
  - `keyword_classifier.py`: Keyword-based category classification
  - `intent_classifier.py`: User intent detection
  - `complexity_analyzer.py`: Task complexity scoring
- **routing_rules/**: YAML and JSON files defining routing logic
- **templates/**: Clarification request template for low-confidence scenarios
- **examples/**: Practical routing examples

### Main Concepts
- 8-category classification system
- Intent detection
- Complexity analysis (0.0-1.0 scale)
- Urgency assessment
- Model selection (Haiku/Sonnet/Opus)
- Skill routing decision making

---

## 3. PARALLELIZATION / Parallel Task Executor

**Base Path:** `/home/user/cc-skills/skills/parallel-task-executor/`

**Anthropic Reference:** ✓ Explicit reference in SKILL.md (line 10)
- Pattern Name: Parallelization
- Description: "Execute independent tasks in parallel...implementing Anthropic's Parallelization pattern from 'Building Effective Agents'"

### Directory Structure
```
parallel-task-executor/
├── SKILL.md                          (Main skill definition - 17.7 KB)
├── config.json                        (Configuration - 358 bytes)
├── integration.py                     (Integration module - 4.4 KB)
├── examples/
│   ├── fullstack_parallel.md         (Full-stack example - 7.4 KB)
│   └── code_review_voting.md         (Code review voting example - 11.7 KB)
└── scripts/
    ├── executors/
    │   ├── sectioning_executor.py    (Sectioning mode - 7.9 KB)
    │   ├── voting_executor.py        (Voting mode - 11.1 KB)
    │   └── worker_pool.py            (Worker pool management - 9.9 KB)
    ├── analyzers/
    │   ├── dependency_analyzer.py    (Dependency analysis - 9.2 KB)
    │   ├── dag_builder.py            (DAG construction - 8.7 KB)
    │   └── conflict_resolver.py      (Conflict resolution - 11.8 KB)
    ├── aggregators/
    │   ├── code_merger.py            (Code merging - 8.7 KB)
    │   ├── vote_aggregator.py        (Vote aggregation - 10.7 KB)
    │   └── result_synthesizer.py     (Result synthesis - 12.6 KB)
    └── monitors/
        └── progress_tracker.py       (Progress tracking - 11.5 KB)
```

### Key Files
- **SKILL.md**: Complete parallelization pattern with two modes
- **config.json**: Resource limits and parallelism settings
- **integration.py**: Integration with other skills
- **Executors**: 
  - `sectioning_executor.py`: File/module/test-level parallelization
  - `voting_executor.py`: Multi-approach evaluation and voting
  - `worker_pool.py`: Dynamic worker pool management
- **Analyzers**:
  - `dependency_analyzer.py`: Dependency extraction
  - `dag_builder.py`: DAG construction
  - `conflict_resolver.py`: Merge conflict resolution
- **Aggregators**:
  - `code_merger.py`: File merging with import deduplication
  - `vote_aggregator.py`: Weighted voting aggregation
  - `result_synthesizer.py`: Hybrid solution synthesis
- **monitors/**: Progress tracking and performance metrics

### Main Concepts
- Two core modes: Sectioning (parallel work) and Voting (multi-approach)
- Dependency analysis and DAG-based planning
- Dynamic worker pool (2-10 workers)
- Result aggregation and conflict resolution
- 2-10x performance speedup

---

## 4. ORCHESTRATOR-WORKER / Dynamic Task Orchestrator

**Base Path:** `/home/user/cc-skills/skills/dynamic-task-orchestrator/`

**Anthropic Reference:** ✓ Explicit reference in SKILL.md (line 10)
- Pattern Name: Orchestrator-Workers
- Description: "This skill implements the Orchestrator-Workers pattern from Anthropic's 'Building Effective Agents' framework"

### Directory Structure
```
dynamic-task-orchestrator/
├── SKILL.md                          (Main skill definition - 16.6 KB)
├── config.json                        (Configuration - 944 bytes)
├── integration.py                     (Integration module - 5.1 KB)
├── references/
│   └── saas_platform_example.md      (SaaS platform example - 6.8 KB)
└── scripts/
    ├── orchestrator/
    │   ├── orchestration_engine.py   (Main orchestration logic - 14.0 KB)
    │   ├── task_decomposer.py        (Task decomposition - 7.0 KB)
    │   ├── worker_selector.py        (Worker selection - 5.8 KB)
    │   └── adaptive_planner.py       (Adaptive replanning - 7.4 KB)
    ├── workers/
    │   ├── base_worker.py            (Base worker interface - 4.3 KB)
    │   ├── code_analyzer_worker.py   (Code analysis - 5.3 KB)
    │   ├── architect_worker.py       (Architecture design - 5.3 KB)
    │   ├── developer_worker.py       (Implementation - 3.9 KB)
    │   ├── tester_worker.py          (Testing - 4.6 KB)
    │   ├── documenter_worker.py      (Documentation - 4.5 KB)
    │   └── optimizer_worker.py       (Performance optimization - 4.6 KB)
    ├── state_management/
    │   ├── project_state.py          (Project state tracking - 9.3 KB)
    │   ├── context_manager.py        (Context management - 7.3 KB)
    │   └── checkpoint_manager.py     (Checkpointing - 8.3 KB)
    └── communication/
        ├── worker_protocol.py        (Worker protocol - 8.9 KB)
        └── message_bus.py            (Message routing - 8.9 KB)
```

### Key Files
- **SKILL.md**: Complete orchestrator pattern with 6 specialized workers
- **config.json**: Orchestration settings and worker timeouts
- **integration.py**: Integration with other skills
- **orchestrator/**: Core orchestration engine
  - `orchestration_engine.py`: Main coordination logic
  - `task_decomposer.py`: Adaptive task decomposition
  - `worker_selector.py`: Worker selection and matching
  - `adaptive_planner.py`: Dynamic replanning
- **workers/**: 6 specialized worker types
  - `base_worker.py`: Base worker interface
  - `code_analyzer_worker.py`: Existing code analysis
  - `architect_worker.py`: Architecture design
  - `developer_worker.py`: Code implementation
  - `tester_worker.py`: Testing and validation
  - `documenter_worker.py`: Documentation generation
  - `optimizer_worker.py`: Performance optimization
- **state_management/**: Shared execution state
  - `project_state.py`: Project-wide state tracking
  - `context_manager.py`: Worker context sharing
  - `checkpoint_manager.py`: Progress checkpointing
- **communication/**: Inter-worker communication
  - `worker_protocol.py`: Worker protocol specification
  - `message_bus.py`: Message routing and delivery

### Main Concepts
- One orchestrator + 6 specialized workers
- Dynamic task decomposition
- Adaptive replanning based on discoveries
- Shared project state and context
- Worker-to-worker communication
- Three orchestration modes: autonomous, guided, collaborative

---

## 5. EVALUATOR-OPTIMIZER / Iterative Quality Enhancer

**Base Path:** `/home/user/cc-skills/skills/iterative-quality-enhancer/`

**Anthropic Reference:** ✓ Explicit reference in SKILL.md (line 10)
- Pattern Name: Evaluator-Optimizer
- Description: "Implement the Evaluator-Optimizer pattern from Anthropic's 'Building Effective Agents'"

### Directory Structure
```
iterative-quality-enhancer/
├── SKILL.md                          (Main skill definition - 13.7 KB)
├── integration.py                     (Integration module - 7.1 KB)
├── references/
│   ├── evaluation_config.json        (Evaluation framework - 13.9 KB)
│   ├── api_optimization_example.md   (API optimization example - 21.6 KB)
│   └── security_enhancement_example.md (Security example - 29.0 KB)
└── scripts/
    ├── evaluators/
    │   ├── __init__.py               (Package init - 1.2 KB)
    │   ├── functionality_evaluator.py (Functionality checks - 7.8 KB)
    │   ├── performance_evaluator.py   (Performance analysis - 5.6 KB)
    │   ├── code_quality_evaluator.py  (Code quality metrics - 5.3 KB)
    │   ├── security_evaluator.py      (Security checks - 5.0 KB)
    │   └── documentation_evaluator.py (Documentation checks - 4.2 KB)
    ├── optimizers/
    │   └── code_optimizer.py          (Optimization logic - 5.3 KB)
    ├── feedback/
    │   └── feedback_generator.py      (Feedback generation - 4.9 KB)
    ├── reports/
    │   └── report_generator.py        (Report generation - 8.3 KB)
    └── iterative-quality-enhancer.zip (Compressed scripts - 93.9 KB)
```

### Key Files
- **SKILL.md**: Complete evaluator-optimizer pattern
- **integration.py**: Integration with sequential, parallel, orchestrator, router
- **references/**:
  - `evaluation_config.json`: 5-dimension evaluation framework with thresholds
  - `api_optimization_example.md`: Detailed REST API optimization walkthrough
  - `security_enhancement_example.md`: Security hardening scenario
- **evaluators/**: 5-dimensional evaluation
  - `functionality_evaluator.py`: Correctness, completeness, reliability
  - `performance_evaluator.py`: Time/space complexity, response time
  - `code_quality_evaluator.py`: Readability, maintainability, modularity
  - `security_evaluator.py`: Vulnerabilities, authentication, data protection
  - `documentation_evaluator.py`: Completeness, clarity, examples
- **optimizers/**: Targeted optimization strategies
  - `code_optimizer.py`: Algorithm and code improvements
- **feedback/**: Feedback generation
  - `feedback_generator.py`: Prioritized feedback generation
- **reports/**: Quality reporting
  - `report_generator.py`: Comprehensive quality reports

### Main Concepts
- 5-dimensional evaluation (Functionality, Performance, Code Quality, Security, Documentation)
- Weighted scoring (thresholds: 0.95, 0.85, 0.90, 0.95, 0.85)
- Iterative optimization (up to 5 iterations)
- Quality gates for other skills
- Comprehensive reports with before/after comparisons

---

## Anthropic URL References

### Direct References Found

1. **intelligent-task-router/config.json** (Line 81):
   ```json
   "url": "https://www.anthropic.com/engineering/building-effective-agents"
   ```

2. **intelligent-task-router/SKILL.md** (Line 413):
   ```markdown
   *This skill implements the Routing pattern from [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) by Anthropic.*
   ```

### Implicit References (Pattern names)

All 5 skills reference the document via pattern names:
- Sequential Task Processor: "Implements Anthropic's Prompt Chaining pattern from 'Building Effective Agents'"
- Intelligent Task Router: "Implements the Routing pattern from Anthropic's Building Effective Agents"
- Parallel Task Executor: "implementing Anthropic's Parallelization pattern from 'Building Effective Agents'"
- Dynamic Task Orchestrator: "Orchestrator-Workers pattern from Anthropic's 'Building Effective Agents' framework"
- Iterative Quality Enhancer: "Evaluator-Optimizer pattern from Anthropic's 'Building Effective Agents'"

---

## Integration Files

All 5 skills include `integration.py` files:

- `/home/user/cc-skills/skills/sequential-task-processor/integration.py` (10.8 KB)
- `/home/user/cc-skills/skills/intelligent-task-router/integration.py` (7.5 KB)
- `/home/user/cc-skills/skills/parallel-task-executor/integration.py` (4.4 KB)
- `/home/user/cc-skills/skills/dynamic-task-orchestrator/integration.py` (5.1 KB)
- `/home/user/cc-skills/skills/iterative-quality-enhancer/integration.py` (7.1 KB)

These modules enable inter-skill communication and workflow integration.

---

## Configuration Files

All skills include `config.json`:

- **sequential-task-processor/config.json**: Step templates, validation rules, presets
- **intelligent-task-router/config.json**: Classification settings, routing rules, skill mappings, **Anthropic URL**
- **parallel-task-executor/config.json**: Parallelism settings, timeouts, resource limits
- **dynamic-task-orchestrator/config.json**: Worker settings, checkpointing, communication
- **iterative-quality-enhancer/**: Uses references/evaluation_config.json for 5-dimension framework

---

## Quick Navigation

### By Anthropic Pattern
1. **Prompt Chaining** → `/home/user/cc-skills/skills/sequential-task-processor/`
2. **Routing** → `/home/user/cc-skills/skills/intelligent-task-router/`
3. **Parallelization** → `/home/user/cc-skills/skills/parallel-task-executor/`
4. **Orchestrator-Workers** → `/home/user/cc-skills/skills/dynamic-task-orchestrator/`
5. **Evaluator-Optimizer** → `/home/user/cc-skills/skills/iterative-quality-enhancer/`

### By File Type
- **Main Definitions** (SKILL.md): 5 files, each 11-18 KB
- **Configurations** (config.json): 5 files, each with pattern-specific settings
- **Integration Modules** (integration.py): 5 files for inter-skill communication
- **Python Scripts**: 40+ files implementing core logic
- **Templates & Examples**: 15+ markdown files for templates and examples
- **References**: Configuration JSONs and detailed examples

---

## Total Project Statistics

- **Total Skills**: 5
- **Total Directories**: 40+
- **Total Python Files**: 40+
- **Total Markdown Files**: 20+
- **Total Configuration Files**: 6
- **Total Size**: ~500+ KB of code and documentation
- **Anthropic References**: Explicit in 2 files, implicit in 5 SKILL.md files

---

**Generated**: 2025-11-17
**Source Document**: https://www.anthropic.com/engineering/building-effective-agents
**Repository**: /home/user/cc-skills/
