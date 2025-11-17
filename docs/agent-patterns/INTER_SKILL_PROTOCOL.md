# Agent Pattern Inter-Skill Protocol

## Overview

This document defines the standard data formats for communication between agent pattern skills, enabling seamless handoffs and consistent execution.

---

## 1. Universal Task Context

Every task carries this context throughout the workflow:

```typescript
interface TaskContext {
  task_id: string;                    // Unique identifier
  original_request: string;           // User's original input
  current_phase: string;              // Which skill is executing
  history: PhaseRecord[];             // Execution history
  artifacts: Map<string, Artifact>;   // Generated outputs
  metadata: {
    created_at: timestamp;
    last_updated: timestamp;
    total_duration_ms: number;
  };
}

interface PhaseRecord {
  skill: string;                      // Which skill executed
  input: SkillInput;                  // What it received
  output: SkillOutput;                // What it produced
  duration_ms: number;
  status: "success" | "partial" | "failed";
}

interface Artifact {
  type: "code" | "document" | "data" | "report";
  content: string | object;
  created_by: string;                 // Which skill created it
  version: number;
}
```

---

## 2. Skill-Specific Input/Output Formats

### 2.1 Router Input/Output

```typescript
// INPUT to Router
interface RouterInput {
  task_context: TaskContext;
  request: string;                    // Task to classify
  available_patterns: string[];       // Patterns to choose from
}

// OUTPUT from Router
interface RouterOutput {
  classification: {
    primary_category: string;         // bug_fix, feature_development, etc.
    secondary_categories: string[];
    confidence: number;               // 0-100%
  };
  complexity: {
    score: number;                    // 0.0 - 1.0
    factors: string[];                // What contributes to score
  };
  model_recommendation: "haiku" | "sonnet" | "opus";
  routing_decision: {
    target_skill: string;             // Which skill to use
    reasoning: string;                // Why this choice
    alternatives: {
      skill: string;
      use_if: string;                 // Condition for alternative
    }[];
  };
  handoff_data: {
    enriched_context: object;         // Additional context for next skill
    priority: "critical" | "high" | "medium" | "low";
    estimated_duration_minutes: number;
  };
}
```

### 2.2 Sequential Input/Output

```typescript
// INPUT to Sequential
interface SequentialInput {
  task_context: TaskContext;
  steps: StepDefinition[];
  gate_criteria: GateCriteria;
  max_retries: number;                // Default: 3
}

interface StepDefinition {
  step_id: string;
  name: string;
  description: string;
  expected_output: string;            // What this step should produce
  gate_checks: string[];              // Validation criteria
}

interface GateCriteria {
  auto_pass_threshold: number;        // Score above which auto-passes
  require_all_checks: boolean;        // All criteria must pass?
}

// OUTPUT from Sequential
interface SequentialOutput {
  completion_status: "all_passed" | "partial" | "failed";
  steps_completed: number;
  total_steps: number;
  step_results: StepResult[];
  final_artifacts: Artifact[];
  validation_log: GateLog[];
}

interface StepResult {
  step_id: string;
  status: "passed" | "failed" | "skipped";
  output: Artifact;
  gate_result: {
    passed: boolean;
    score: number;                    // 0-10
    checks_passed: string[];
    checks_failed: string[];
    retry_count: number;
  };
  duration_ms: number;
}

interface GateLog {
  step_id: string;
  attempt: number;
  result: "pass" | "fail" | "retry";
  feedback: string;                   // Why it passed/failed
}
```

### 2.3 Parallel Input/Output

```typescript
// INPUT to Parallel
interface ParallelInput {
  task_context: TaskContext;
  mode: "sectioning" | "voting";

  // For Sectioning
  subtasks?: SubtaskDefinition[];
  merge_strategy?: "auto" | "manual" | "custom";

  // For Voting
  approaches?: ApproachDefinition[];
  evaluation_criteria?: WeightedCriterion[];

  max_workers: number;                // Default: 5
  timeout_seconds: number;            // Default: 300
}

interface SubtaskDefinition {
  subtask_id: string;
  description: string;
  dependencies: string[];             // Other subtask IDs
  expected_output_type: string;
}

interface ApproachDefinition {
  approach_id: string;
  name: string;
  strategy_description: string;
}

interface WeightedCriterion {
  name: string;
  weight: number;                     // 0-1, sum to 1.0
  threshold: number;                  // Minimum acceptable score
}

// OUTPUT from Parallel
interface ParallelOutput {
  mode: "sectioning" | "voting";

  // Sectioning results
  sectioning_results?: {
    workers_used: number;
    subtask_outputs: SubtaskOutput[];
    merge_result: {
      status: "success" | "conflicts";
      conflicts_resolved: number;
      conflicts_manual_review: ConflictDescription[];
      merged_artifact: Artifact;
    };
    speedup_factor: number;           // vs sequential execution
  };

  // Voting results
  voting_results?: {
    approaches_evaluated: number;
    scores: ApproachScore[];
    winner: {
      approach_id: string;
      total_score: number;
      rationale: string;
    };
    consensus_points: string[];       // Where all approaches agree
  };

  execution_time_ms: number;
}

interface SubtaskOutput {
  subtask_id: string;
  status: "complete" | "failed";
  output: Artifact;
  worker_id: string;
}

interface ConflictDescription {
  type: "file" | "import" | "type" | "logic";
  location: string;
  resolution_suggestion: string;
}

interface ApproachScore {
  approach_id: string;
  criterion_scores: {
    criterion: string;
    score: number;                    // 0-10
    reasoning: string;
  }[];
  weighted_total: number;
}
```

### 2.4 Orchestrator Input/Output

```typescript
// INPUT to Orchestrator
interface OrchestratorInput {
  task_context: TaskContext;
  project_description: string;
  initial_requirements: string[];
  orchestration_mode: "autonomous" | "guided" | "collaborative";
  max_replanning_cycles: number;      // Default: 10
  max_subtasks: number;               // Default: 50
}

// OUTPUT from Orchestrator
interface OrchestratorOutput {
  project_status: "complete" | "partial" | "blocked";
  execution_summary: {
    initial_subtasks: number;
    final_subtasks: number;
    discovered_subtasks: number;
    replanning_cycles: number;
    workers_used: WorkerUsage[];
  };
  worker_contributions: WorkerContribution[];
  discoveries: Discovery[];
  final_artifacts: Artifact[];
  project_state: {
    completion_percentage: number;
    remaining_work: string[];
    blockers: string[];
  };
  recommendations: string[];
}

interface WorkerUsage {
  worker_type: string;
  tasks_completed: number;
  total_duration_ms: number;
}

interface WorkerContribution {
  worker_type: string;
  subtask_id: string;
  output: Artifact;
  discoveries_reported: Discovery[];
}

interface Discovery {
  discovered_at: string;              // During which subtask
  type: "new_subtask" | "dependency" | "blocker" | "requirement";
  description: string;
  impact: "critical" | "high" | "medium" | "low";
  action_taken: string;
}
```

### 2.5 Evaluator Input/Output

```typescript
// INPUT to Evaluator
interface EvaluatorInput {
  task_context: TaskContext;
  artifact_to_evaluate: Artifact;
  evaluation_dimensions: DimensionConfig[];
  target_total_score: number;         // Default: 9.0
  max_iterations: number;             // Default: 5
  improvement_threshold: number;      // Minimum improvement to continue
}

interface DimensionConfig {
  name: string;                       // functionality, performance, etc.
  weight: number;                     // 0-1
  threshold: number;                  // Minimum acceptable score
  evaluation_criteria: string[];      // Specific checks
}

// OUTPUT from Evaluator
interface EvaluatorOutput {
  final_status: "threshold_met" | "max_iterations" | "diminishing_returns";
  initial_score: number;
  final_score: number;
  improvement_percentage: number;
  iterations_completed: number;
  iteration_history: IterationRecord[];
  final_artifact: Artifact;
  recommendations: string[];          // Future improvements
}

interface IterationRecord {
  iteration: number;
  scores: {
    dimension: string;
    score: number;
    threshold: number;
    passed: boolean;
  }[];
  weighted_total: number;
  feedback_provided: FeedbackItem[];
  improvements_applied: string[];
  improvement_delta: number;
}

interface FeedbackItem {
  priority: number;
  dimension: string;
  issue: string;
  location: string;
  action: string;
  expected_impact: number;
}
```

### 2.6 Advisor Input/Output

```typescript
// INPUT to Advisor
interface AdvisorInput {
  task_context: TaskContext;
  user_request: string;
  constraints?: {
    time_limit_minutes?: number;
    preferred_pattern?: string;
    avoid_patterns?: string[];
  };
}

// OUTPUT from Advisor
interface AdvisorOutput {
  analysis: {
    task_summary: string;
    complexity_score: number;
    structure: "fixed" | "variable" | "unknown";
    predictability: "high" | "medium" | "low";
    dependencies: "sequential" | "independent" | "mixed";
  };
  recommendation: {
    primary_pattern: string | "no_pattern";
    reasoning: string[];
    confidence: number;
  };
  alternatives: {
    pattern: string;
    use_if: string;
    trade_offs: string;
  }[];
  clarification_needed?: {
    questions: string[];
    impact_on_recommendation: string;
  };
  execution_guidance: {
    first_steps: string[];
    considerations: string[];
    expected_outcome: string;
  };
}
```

---

## 3. Handoff Protocol

### 3.1 Direct Handoff (Skill A → Skill B)

```typescript
interface Handoff {
  from_skill: string;
  to_skill: string;
  handoff_type: "direct" | "conditional" | "checkpoint";

  payload: {
    task_context: TaskContext;        // Updated context
    skill_specific_input: object;     // Input for receiving skill
    enrichment_data: object;          // Additional context from sender
  };

  conditions?: {
    proceed_if: string;               // Condition to continue
    fallback_skill?: string;          // Alternative if condition fails
  };

  checkpoint?: {
    require_user_approval: boolean;
    auto_proceed_after_seconds?: number;
  };
}
```

### 3.2 Common Handoff Patterns

**Router → Sequential**
```typescript
{
  from_skill: "router",
  to_skill: "sequential",
  handoff_type: "direct",
  payload: {
    task_context: context,
    skill_specific_input: {
      steps: router_output.suggested_steps,
      gate_criteria: { auto_pass_threshold: 0.8 }
    },
    enrichment_data: {
      category: router_output.classification.primary_category,
      model: router_output.model_recommendation
    }
  }
}
```

**Sequential → Evaluator**
```typescript
{
  from_skill: "sequential",
  to_skill: "evaluator",
  handoff_type: "conditional",
  payload: {
    task_context: context,
    skill_specific_input: {
      artifact_to_evaluate: sequential_output.final_artifacts[0],
      evaluation_dimensions: default_dimensions
    }
  },
  conditions: {
    proceed_if: "sequential_output.completion_status === 'all_passed'",
    fallback_skill: "advisor"
  }
}
```

**Orchestrator → Parallel (nested)**
```typescript
{
  from_skill: "orchestrator",
  to_skill: "parallel",
  handoff_type: "direct",
  payload: {
    task_context: context,
    skill_specific_input: {
      mode: "sectioning",
      subtasks: orchestrator_identified_independent_tasks
    }
  }
}
```

---

## 4. Error Handling Protocol

```typescript
interface SkillError {
  skill: string;
  error_type: "validation" | "execution" | "timeout" | "resource";
  severity: "critical" | "recoverable" | "warning";
  message: string;
  context: object;
  recovery_options: RecoveryOption[];
}

interface RecoveryOption {
  action: "retry" | "skip" | "fallback" | "escalate";
  description: string;
  auto_execute: boolean;
  requires_user_input: boolean;
}
```

---

## 5. Checkpoint Protocol

```typescript
interface Checkpoint {
  checkpoint_id: string;
  task_context: TaskContext;
  current_skill: string;
  state_snapshot: object;             // Skill-specific state
  artifacts_so_far: Artifact[];
  timestamp: timestamp;
  resumable: boolean;
}

// To save checkpoint
function saveCheckpoint(context: TaskContext, skill: string, state: object): Checkpoint;

// To resume from checkpoint
function resumeFromCheckpoint(checkpoint_id: string): TaskContext;
```

---

## 6. Execution Examples

### Example: Simple Feature Pipeline
```
1. Router receives: "Add password reset feature"
   Output: { target_skill: "sequential", complexity: 0.55 }

2. Handoff to Sequential with steps:
   [analyze_requirements, design_flow, implement, test, document]

3. Sequential executes with gates:
   - Step 1: Gate PASS (requirements clear)
   - Step 2: Gate PASS (design complete)
   - Step 3: Gate PASS (code compiles)
   - Step 4: Gate PASS (tests pass)
   - Step 5: Gate PASS (docs complete)

4. Handoff to Evaluator:
   Input: final code artifact
   Evaluates: security (password handling), functionality
   Output: 9.2/10 (threshold met)

5. Final output with full execution history
```

### Example: Complex Project Pipeline
```
1. Advisor analyzes: "Build e-commerce platform"
   Output: { primary_pattern: "orchestrator", complexity: 0.85 }

2. Orchestrator decomposes:
   Initial subtasks: [user_service, product_service, order_service]

3. For independent services, handoff to Parallel:
   Mode: sectioning
   Workers: 3 parallel

4. Each worker uses Sequential internally:
   Steps with gates for each service

5. Orchestrator receives merged results
   Discovers: Need payment_service, need API_gateway
   Replan: Add 2 more subtasks

6. Continue execution...

7. Final handoff to Evaluator:
   Evaluate entire integrated system
   Iterations: 2 (performance optimization)

8. Complete with all artifacts and history
```

---

## 7. Flow-Level Enhancements

### 7.1 Step Generator for Sequential (Router → Sequential)

```typescript
interface StepTemplate {
  id: string;
  name: string;
  description: string;
  expected_output: string;
  gate_checks: string[];
}

const STEP_TEMPLATES: Record<string, StepTemplate[]> = {
  feature_development: [
    { id: "requirements", name: "Requirements Analysis", description: "Analyze and document requirements", expected_output: "Requirements document", gate_checks: ["complete", "consistent", "testable"] },
    { id: "design", name: "System Design", description: "Design the system architecture", expected_output: "Design specification", gate_checks: ["feasible", "scalable", "maintainable"] },
    { id: "implement", name: "Implementation", description: "Write the code", expected_output: "Working code", gate_checks: ["compiles", "follows_conventions", "no_vulnerabilities"] },
    { id: "test", name: "Testing", description: "Write and run tests", expected_output: "Test results", gate_checks: ["all_pass", "coverage_adequate", "edge_cases_covered"] },
    { id: "document", name: "Documentation", description: "Write documentation", expected_output: "Documentation files", gate_checks: ["complete", "accurate", "accessible"] }
  ],
  bug_fix: [
    { id: "reproduce", name: "Reproduce Bug", description: "Reproduce the issue", expected_output: "Reproduction steps", gate_checks: ["consistently_reproducible", "environment_documented"] },
    { id: "diagnose", name: "Root Cause Analysis", description: "Find the root cause", expected_output: "Root cause report", gate_checks: ["cause_identified", "evidence_provided"] },
    { id: "fix", name: "Implement Fix", description: "Write the fix", expected_output: "Fixed code", gate_checks: ["compiles", "addresses_root_cause", "no_regressions"] },
    { id: "verify", name: "Verify Fix", description: "Verify the fix works", expected_output: "Verification report", gate_checks: ["bug_resolved", "tests_pass", "no_side_effects"] }
  ],
  refactoring: [
    { id: "analyze", name: "Code Analysis", description: "Analyze current code structure", expected_output: "Analysis report", gate_checks: ["issues_identified", "impact_assessed"] },
    { id: "plan", name: "Refactoring Plan", description: "Plan the refactoring", expected_output: "Refactoring plan", gate_checks: ["safe_steps", "reversible", "testable"] },
    { id: "execute", name: "Execute Refactoring", description: "Apply refactoring", expected_output: "Refactored code", gate_checks: ["behavior_preserved", "improved_structure"] },
    { id: "validate", name: "Validate", description: "Ensure no regressions", expected_output: "Validation report", gate_checks: ["all_tests_pass", "performance_maintained"] }
  ]
};

function generateStepsFromRouterGuidance(
  routerOutput: RouterOutput,
  taskDescription: string
): StepDefinition[] {
  const category = routerOutput.classification.primary_category;
  const templates = STEP_TEMPLATES[category] || STEP_TEMPLATES.feature_development;

  return templates.map(template => ({
    step_id: template.id,
    name: template.name,
    description: `${template.description} for: ${taskDescription}`,
    expected_output: template.expected_output,
    gate_checks: enrichGateChecks(template.gate_checks, routerOutput)
  }));
}

function enrichGateChecks(baseChecks: string[], routerOutput: RouterOutput): string[] {
  const enriched = [...baseChecks];

  // Add security checks if security-sensitive
  if (routerOutput.complexity.factors.includes("security_sensitive")) {
    enriched.push("no_security_vulnerabilities", "input_validation_present");
  }

  // Add performance checks if performance-critical
  if (routerOutput.complexity.factors.includes("performance_critical")) {
    enriched.push("performance_acceptable", "no_memory_leaks");
  }

  return enriched;
}
```

### 7.2 Independence Verification (Router → Parallel)

```typescript
interface ConflictReport {
  verified: boolean;
  conflicts: ConflictDetail[];
  recommendations: string[];
}

interface ConflictDetail {
  task_a: string;
  task_b: string;
  conflict_type: "shared_resource" | "data_dependency" | "state_dependency" | "file_conflict";
  description: string;
  resolution: string;
}

function verifySubtaskIndependence(subtasks: SubtaskDefinition[]): ConflictReport {
  const conflicts: ConflictDetail[] = [];

  for (let i = 0; i < subtasks.length; i++) {
    for (let j = i + 1; j < subtasks.length; j++) {
      const conflict = checkForConflict(subtasks[i], subtasks[j]);
      if (conflict) {
        conflicts.push(conflict);
      }
    }
  }

  return {
    verified: conflicts.length === 0,
    conflicts,
    recommendations: generateRecommendations(conflicts)
  };
}

function checkForConflict(a: SubtaskDefinition, b: SubtaskDefinition): ConflictDetail | null {
  // Check shared file modifications
  const aFiles = extractTargetFiles(a.description);
  const bFiles = extractTargetFiles(b.description);
  const sharedFiles = aFiles.filter(f => bFiles.includes(f));

  if (sharedFiles.length > 0) {
    return {
      task_a: a.subtask_id,
      task_b: b.subtask_id,
      conflict_type: "file_conflict",
      description: `Both tasks modify: ${sharedFiles.join(", ")}`,
      resolution: "Execute sequentially or use merge conflict resolution"
    };
  }

  // Check data dependencies
  if (taskDependsOnOutput(b, a) || taskDependsOnOutput(a, b)) {
    return {
      task_a: a.subtask_id,
      task_b: b.subtask_id,
      conflict_type: "data_dependency",
      description: "One task requires output from the other",
      resolution: "Execute dependent task after prerequisite completes"
    };
  }

  // Check state dependencies
  if (modifiesSharedState(a) && modifiesSharedState(b)) {
    return {
      task_a: a.subtask_id,
      task_b: b.subtask_id,
      conflict_type: "state_dependency",
      description: "Both tasks modify shared application state",
      resolution: "Use state synchronization or execute sequentially"
    };
  }

  return null;
}

function generateRecommendations(conflicts: ConflictDetail[]): string[] {
  if (conflicts.length === 0) {
    return ["Safe to parallelize all subtasks"];
  }

  const recommendations: string[] = [];

  const fileConflicts = conflicts.filter(c => c.conflict_type === "file_conflict");
  if (fileConflicts.length > 0) {
    recommendations.push("Consider using feature branches for conflicting file modifications");
  }

  const dataConflicts = conflicts.filter(c => c.conflict_type === "data_dependency");
  if (dataConflicts.length > 0) {
    recommendations.push("Reorder tasks to respect data dependencies");
  }

  const stateConflicts = conflicts.filter(c => c.conflict_type === "state_dependency");
  if (stateConflicts.length > 0) {
    recommendations.push("Implement state locking or execute conflicting tasks sequentially");
  }

  return recommendations;
}
```

### 7.3 Nesting Depth Management

```typescript
// Enhanced TaskContext with nesting control
interface TaskContext {
  task_id: string;
  original_request: string;
  current_phase: string;
  history: PhaseRecord[];
  artifacts: Map<string, Artifact>;
  metadata: {
    created_at: timestamp;
    last_updated: timestamp;
    total_duration_ms: number;
  };
  // Nesting control
  nesting: {
    current_depth: number;
    max_depth: number;  // Default: 3
    path: string[];     // ["orchestrator", "parallel", "sequential"]
  };
}

function validateNestingDepth(context: TaskContext, targetSkill: string): {
  allowed: boolean;
  reason?: string;
} {
  if (context.nesting.current_depth >= context.nesting.max_depth) {
    return {
      allowed: false,
      reason: `Maximum nesting depth (${context.nesting.max_depth}) reached. Current path: ${context.nesting.path.join(" → ")}`
    };
  }

  // Prevent circular nesting
  if (context.nesting.path.includes(targetSkill)) {
    return {
      allowed: false,
      reason: `Circular nesting detected: ${targetSkill} already in path ${context.nesting.path.join(" → ")}`
    };
  }

  return { allowed: true };
}

function createNestedContext(parentContext: TaskContext, childSkill: string): TaskContext {
  const validation = validateNestingDepth(parentContext, childSkill);
  if (!validation.allowed) {
    throw new Error(`Nesting validation failed: ${validation.reason}`);
  }

  return {
    ...parentContext,
    current_phase: childSkill,
    nesting: {
      current_depth: parentContext.nesting.current_depth + 1,
      max_depth: parentContext.nesting.max_depth,
      path: [...parentContext.nesting.path, childSkill]
    }
  };
}

function initializeTaskContext(request: string, maxDepth: number = 3): TaskContext {
  return {
    task_id: generateUniqueId(),
    original_request: request,
    current_phase: "init",
    history: [],
    artifacts: new Map(),
    metadata: {
      created_at: Date.now(),
      last_updated: Date.now(),
      total_duration_ms: 0
    },
    nesting: {
      current_depth: 0,
      max_depth: maxDepth,
      path: []
    }
  };
}
```

### 7.4 Evaluation Dimension Templates

```typescript
interface DimensionTemplate {
  name: string;
  weight: number;
  threshold: number;
  evaluation_criteria: string[];
}

const EVALUATION_TEMPLATES: Record<string, DimensionTemplate[]> = {
  security_critical: [
    { name: "security", weight: 0.40, threshold: 9.0, evaluation_criteria: ["no_injection_vulnerabilities", "proper_authentication", "secure_data_handling", "rate_limiting", "audit_logging"] },
    { name: "functionality", weight: 0.25, threshold: 8.5, evaluation_criteria: ["all_features_work", "error_handling_complete", "edge_cases_handled"] },
    { name: "code_quality", weight: 0.20, threshold: 8.0, evaluation_criteria: ["follows_conventions", "maintainable", "no_code_smells"] },
    { name: "documentation", weight: 0.15, threshold: 7.5, evaluation_criteria: ["api_documented", "security_considerations_noted", "deployment_guide"] }
  ],
  performance_critical: [
    { name: "performance", weight: 0.35, threshold: 9.0, evaluation_criteria: ["response_time_acceptable", "resource_usage_efficient", "scalable", "no_memory_leaks", "optimized_queries"] },
    { name: "functionality", weight: 0.30, threshold: 8.5, evaluation_criteria: ["all_features_work", "graceful_degradation", "caching_implemented"] },
    { name: "code_quality", weight: 0.20, threshold: 8.0, evaluation_criteria: ["efficient_algorithms", "proper_data_structures", "no_bottlenecks"] },
    { name: "documentation", weight: 0.15, threshold: 7.5, evaluation_criteria: ["performance_benchmarks_documented", "optimization_rationale", "monitoring_guide"] }
  ],
  user_facing: [
    { name: "functionality", weight: 0.30, threshold: 9.0, evaluation_criteria: ["all_features_work", "intuitive_ux", "accessible", "responsive"] },
    { name: "code_quality", weight: 0.25, threshold: 8.0, evaluation_criteria: ["component_reusability", "state_management_clean", "follows_design_system"] },
    { name: "performance", weight: 0.25, threshold: 8.5, evaluation_criteria: ["fast_load_time", "smooth_interactions", "optimized_assets"] },
    { name: "documentation", weight: 0.20, threshold: 7.5, evaluation_criteria: ["component_usage_documented", "accessibility_notes", "user_guide"] }
  ],
  standard: [
    { name: "functionality", weight: 0.30, threshold: 8.5, evaluation_criteria: ["all_features_work", "error_handling", "input_validation"] },
    { name: "code_quality", weight: 0.25, threshold: 8.0, evaluation_criteria: ["readable", "maintainable", "follows_conventions", "testable"] },
    { name: "performance", weight: 0.20, threshold: 8.0, evaluation_criteria: ["acceptable_response_time", "no_obvious_inefficiencies"] },
    { name: "security", weight: 0.15, threshold: 8.0, evaluation_criteria: ["basic_security_practices", "no_obvious_vulnerabilities"] },
    { name: "documentation", weight: 0.10, threshold: 7.5, evaluation_criteria: ["code_comments", "api_docs", "readme_updated"] }
  ]
};

function selectEvaluationDimensions(routerOutput: RouterOutput): DimensionConfig[] {
  const factors = routerOutput.complexity.factors;
  const category = routerOutput.classification.primary_category;

  // Priority-based selection
  if (factors.includes("security_sensitive") || category === "security") {
    return EVALUATION_TEMPLATES.security_critical;
  }

  if (factors.includes("performance_critical") || category === "performance") {
    return EVALUATION_TEMPLATES.performance_critical;
  }

  if (factors.includes("user_facing") || factors.includes("ui_component")) {
    return EVALUATION_TEMPLATES.user_facing;
  }

  return EVALUATION_TEMPLATES.standard;
}

function customizeEvaluationDimensions(
  template: DimensionConfig[],
  userPreferences: {
    prioritize?: string[];
    threshold_overrides?: Record<string, number>;
    additional_criteria?: Record<string, string[]>;
  }
): DimensionConfig[] {
  let dimensions = [...template];

  // Apply priority overrides
  if (userPreferences.prioritize) {
    // Reweight to prioritize specified dimensions
    const totalWeight = 1.0;
    const priorityBoost = 0.1;

    dimensions = dimensions.map(dim => {
      if (userPreferences.prioritize.includes(dim.name)) {
        return { ...dim, weight: dim.weight + priorityBoost };
      }
      return dim;
    });

    // Normalize weights
    const sum = dimensions.reduce((acc, d) => acc + d.weight, 0);
    dimensions = dimensions.map(d => ({ ...d, weight: d.weight / sum }));
  }

  // Apply threshold overrides
  if (userPreferences.threshold_overrides) {
    dimensions = dimensions.map(dim => {
      if (userPreferences.threshold_overrides[dim.name]) {
        return { ...dim, threshold: userPreferences.threshold_overrides[dim.name] };
      }
      return dim;
    });
  }

  // Add additional criteria
  if (userPreferences.additional_criteria) {
    dimensions = dimensions.map(dim => {
      if (userPreferences.additional_criteria[dim.name]) {
        return {
          ...dim,
          evaluation_criteria: [
            ...dim.evaluation_criteria,
            ...userPreferences.additional_criteria[dim.name]
          ]
        };
      }
      return dim;
    });
  }

  return dimensions;
}
```

---

## 8. Implementation Notes

### For Claude Code Execution

When actually running these skills:

1. **Use Task tool** for spawning workers (Parallel mode)
2. **Use TodoWrite** for tracking progress (Sequential gates)
3. **Use structured prompts** for evaluations (Evaluator scoring)
4. **Maintain context in conversation** (no external state)

### Artifact Storage

Since we're in Claude Code:
- Artifacts are files on disk
- Context is maintained in conversation
- Checkpoints are conceptual (conversation history)

### Practical Limitations

- No actual parallel execution (sequential simulation)
- Scoring is qualitative (no true metrics)
- State management is conversational
- "Workers" are sub-conversations or Task tool

---

## Summary

This protocol defines:
1. **Standard data formats** for each skill
2. **Handoff mechanisms** between skills
3. **Error handling** and recovery
4. **Checkpoint** and resume capabilities

With these formats, skills can:
- **Communicate consistently**
- **Pass context reliably**
- **Handle errors gracefully**
- **Enable composability**

This addresses the core gap identified in unit validation: **inter-skill data standardization**.
