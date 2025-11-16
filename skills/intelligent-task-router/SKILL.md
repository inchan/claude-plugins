---
name: intelligent-task-router
description: Analyze incoming tasks and automatically route them to the optimal processing path using intelligent classification based on keywords, intent, complexity, and urgency. Implements the Routing pattern from Anthropic's Building Effective Agents guide.
---

# Intelligent Task Router

Automatically classify and route tasks to the optimal skill and model based on multi-factor analysis including category, intent, complexity, and urgency.

## Purpose

This skill implements the **Routing pattern** from Anthropic's Building Effective Agents methodology. Instead of using a single approach for all tasks, this skill acts as an intelligent dispatcher that analyzes each task request and routes it to the most appropriate processing path.

The router provides:
- **8-category classification system** for common development tasks
- **Intent detection** to understand the user's underlying goal
- **Complexity analysis** for effort estimation and model selection
- **Urgency assessment** for prioritization
- **Multi-label support** for tasks spanning multiple categories

## When to Use This Skill

Use this skill when:
- Starting a new task that could benefit from specialized handling
- The task type is unclear and needs classification
- You need to determine the optimal model (Haiku/Sonnet/Opus) for a task
- Breaking down complex requests into categorized sub-tasks
- Prioritizing multiple incoming tasks
- A user request could be handled by different approaches

**This skill should be used proactively** as the entry point for most development tasks before delegating to specialized skills.

## Task Categories

The router classifies tasks into 8 primary categories:

1. **bug_fix** - Code errors and issue resolution
2. **feature_development** - New functionality implementation
3. **refactoring** - Code structure improvement
4. **testing** - Test creation and quality validation
5. **documentation** - Documentation and explanation
6. **performance** - Performance optimization
7. **security** - Security hardening and vulnerability fixes
8. **data_processing** - Data transformation and ETL

Each category has associated keywords, complexity weights, and default skill mappings defined in `routing_rules/categories.yaml`.

## Classification Process

### Step 1: Keyword Analysis

Use `classifiers/keyword_classifier.py` to extract keywords and calculate category scores:

```python
from classifiers.keyword_classifier import KeywordClassifier

classifier = KeywordClassifier()
primary, secondary, confidence = classifier.classify(task_text)
```

This identifies:
- **Primary category** - The main task type
- **Secondary categories** - Additional relevant categories
- **Confidence score** - How certain the classification is

### Step 2: Intent Detection

Use `classifiers/intent_classifier.py` to understand user intent:

```python
from classifiers.intent_classifier import IntentClassifier

intent_classifier = IntentClassifier()
intent_result = intent_classifier.classify(task_text)
```

This detects intents like:
- CREATE - Building new functionality
- MODIFY - Changing existing code
- DEBUG - Fixing issues
- ANALYZE - Understanding code
- OPTIMIZE - Improving performance
- DOCUMENT - Writing documentation
- TEST - Creating tests

### Step 3: Complexity Analysis

Use `classifiers/complexity_analyzer.py` to assess task complexity:

```python
from classifiers.complexity_analyzer import ComplexityAnalyzer

analyzer = ComplexityAnalyzer()
complexity_result = analyzer.analyze(task_text, category=primary_category)
```

This calculates:
- **Scope score** - Single file vs. system-wide
- **Dependency score** - Interconnections and integrations
- **Technical depth** - Advanced concepts required
- **Overall complexity** (0.0 to 1.0)
- **Effort level** - low/medium/high/very_high
- **Estimated time** - in minutes

### Step 4: Urgency Assessment

Check for urgency indicators in the task text against patterns in `routing_rules/categories.yaml`:

- **High**: "긴급", "urgent", "critical", "asap", "즉시", "hotfix"
- **Medium**: "중요", "important", "priority", "우선"
- **Low**: "나중에", "later", "eventually", "when possible"

## Routing Decision

Combine all classification results to make a routing decision using `routing_rules/skill_mapping.json`:

```json
{
  "task_id": "unique_task_id",
  "classification": {
    "primary": "category_name",
    "secondary": ["category1", "category2"],
    "confidence": 0.85
  },
  "routing": {
    "target_skill": "skill_name",
    "model": "claude-3-sonnet",
    "priority": "medium"
  },
  "metadata": {
    "complexity_score": 0.65,
    "estimated_minutes": 45,
    "requires_clarification": false
  }
}
```

### Skill Selection Rules

Based on category and complexity:

- **sequential-task-processor**
  - Bug fixes (0.3-0.7 complexity)
  - Security tasks
  - Documentation
  - Tasks requiring step-by-step execution

- **parallel-executor**
  - Testing (0.2-0.6 complexity)
  - Data processing
  - Independent batch operations

- **dynamic-orchestrator**
  - Feature development (0.7-1.0 complexity)
  - Multi-component integration
  - Complex refactoring

- **quality-enhancer**
  - Performance optimization (0.5-0.9 complexity)
  - Refactoring
  - Architecture improvements

### Model Selection Rules

Based on complexity score:

- **claude-3-haiku** (complexity < 0.5)
  - Simple bug fixes
  - Basic data processing
  - Simple documentation

- **claude-3-sonnet** (complexity 0.5-0.7)
  - Medium complexity features
  - Refactoring
  - Security tasks
  - **Default choice for most tasks**

- **claude-3-opus** (complexity > 0.7)
  - Complex architecture design
  - Large-scale migrations
  - Critical security work

## Handling Low Confidence

When confidence < 0.6, use the clarification template:

1. Read `templates/clarification_request.md`
2. Fill in the template with classification results
3. Ask the user specific questions to improve routing accuracy
4. Re-classify with additional context

Example questions to ask:
- Scope: "Does this affect a single file or multiple components?"
- Priority: "How urgent is this task?"
- Constraints: "Are there any technical constraints or requirements?"
- Expected outcome: "What should the final result look like?"

## Integration with Other Skills

### As Entry Point (Incoming)

The router receives tasks from:
- Direct user requests
- Orchestrator skills delegating sub-tasks
- Other skills requesting classification

### As Dispatcher (Outgoing)

The router delegates tasks to:
- **sequential-task-processor** - Linear workflows
- **parallel-executor** - Concurrent operations
- **dynamic-orchestrator** - Complex multi-step tasks
- **quality-enhancer** - Code improvement tasks

### Feedback Loop

Receive feedback from evaluator skills to improve routing:
- Track which routings led to successful outcomes
- Adjust classification weights based on results
- Learn project-specific patterns over time

## Usage Examples

### Example 1: Simple Bug Fix

**Input**: "로그인 페이지에서 버그 수정해주세요"

**Classification**:
- Primary: bug_fix (0.85)
- Intent: debug
- Complexity: 0.45 (medium)
- Urgency: medium

**Routing**:
- Skill: sequential-task-processor
- Model: claude-3-sonnet
- Time: 45 minutes

See `examples/bug_fix_routing.md` for complete analysis.

### Example 2: Feature Development

**Input**: "프로필 이미지 업로드 및 편집 기능 추가"

**Classification**:
- Primary: feature_development (0.85)
- Secondary: data_processing (0.30)
- Intent: create
- Complexity: 0.75 (high)
- Urgency: medium

**Routing**:
- Skill: dynamic-orchestrator
- Model: claude-3-opus
- Time: 90 minutes

See `examples/feature_routing.md` for complete analysis.

## Best Practices

### 1. Always Classify First
Before starting any task, run it through the router to determine the optimal approach.

### 2. Trust the Complexity Score
Use the complexity score to select the appropriate model. Don't use Opus for simple tasks or Haiku for complex ones.

### 3. Consider Secondary Categories
Secondary categories indicate cross-cutting concerns. For example, a feature_development task with a security secondary category should include security review.

### 4. Ask for Clarification
When confidence is low, always ask clarifying questions rather than guessing.

### 5. Update Routing Rules
As you learn project-specific patterns, update `routing_rules/categories.yaml` and `routing_rules/skill_mapping.json`.

### 6. Multi-step Tasks
For complex tasks, route the overall task first, then route sub-tasks as they emerge during execution.

## Workflow

To use this skill for routing a task:

1. **Receive Task Request**
   ```
   Input: User's natural language task description
   ```

2. **Run Classification Pipeline**
   ```python
   # Keyword classification
   keyword_result = keyword_classifier.classify(task)

   # Intent detection
   intent_result = intent_classifier.classify(task)

   # Complexity analysis
   complexity_result = complexity_analyzer.analyze(task, category)

   # Urgency detection
   urgency = detect_urgency(task)
   ```

3. **Make Routing Decision**
   ```python
   # Consult routing_rules/skill_mapping.json
   routing = determine_routing(
       category=keyword_result['primary'],
       complexity=complexity_result['complexity_score'],
       urgency=urgency
   )
   ```

4. **Check Confidence**
   ```python
   if confidence < 0.6:
       # Use templates/clarification_request.md
       request_clarification()
   else:
       # Proceed with routing
       delegate_to_skill(routing['target_skill'])
   ```

5. **Execute via Routed Skill**
   ```
   Pass task to selected skill with routing metadata
   ```

6. **Collect Feedback**
   ```
   Track outcome for future routing improvements
   ```

## Reference Files

- **routing_rules/categories.yaml** - Category definitions, keywords, and complexity weights
- **routing_rules/skill_mapping.json** - Skill selection rules and model preferences
- **templates/clarification_request.md** - Template for requesting task clarification
- **examples/bug_fix_routing.md** - Complete routing example for bug fixes
- **examples/feature_routing.md** - Complete routing example for feature development

## Classifier Scripts

- **classifiers/keyword_classifier.py** - Keyword-based category classification
- **classifiers/intent_classifier.py** - User intent detection
- **classifiers/complexity_analyzer.py** - Task complexity analysis

All classifiers can be executed standalone for testing:

```bash
python classifiers/keyword_classifier.py
python classifiers/intent_classifier.py
python classifiers/complexity_analyzer.py
```

## Adapting to Your Project

To customize the router for your specific project:

1. **Add Project-Specific Categories**
   - Edit `routing_rules/categories.yaml`
   - Add new categories with keywords and weights

2. **Define Custom Skills**
   - Edit `routing_rules/skill_mapping.json`
   - Map categories to your available skills

3. **Adjust Complexity Thresholds**
   - Modify complexity_weight in categories
   - Tune model selection thresholds

4. **Create Domain Templates**
   - Add templates for common clarification scenarios
   - Customize `templates/clarification_request.md`

## Output Format

The router should output a structured routing decision:

```json
{
  "task_id": "task_20250111_001",
  "original_request": "User's request text",
  "classification": {
    "primary": "bug_fix",
    "secondary": ["security"],
    "confidence": 0.85,
    "intent": "debug"
  },
  "routing": {
    "target_skill": "sequential-task-processor",
    "model": "claude-3-sonnet",
    "priority": "medium"
  },
  "analysis": {
    "complexity_score": 0.45,
    "scope_score": 0.3,
    "dependency_score": 0.4,
    "technical_depth_score": 0.5,
    "effort_level": "medium",
    "estimated_minutes": 45,
    "urgency": "medium"
  },
  "metadata": {
    "requires_clarification": false,
    "timestamp": "2025-01-11T10:30:00Z",
    "router_version": "1.0.0"
  }
}
```

---

*This skill implements the Routing pattern from [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) by Anthropic.*
