#!/usr/bin/env node
import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { execSync } from 'child_process';

interface HookInput {
    session_id: string;
    transcript_path: string;
    cwd: string;
    permission_mode: string;
    prompt: string;
}

interface PromptTriggers {
    keywords?: string[];
    intentPatterns?: string[];
}

interface SkillRule {
    type: 'guardrail' | 'domain';
    enforcement: 'block' | 'suggest' | 'warn';
    priority: 'critical' | 'high' | 'medium' | 'low';
    promptTriggers?: PromptTriggers;
}

interface SkillRules {
    version: string;
    skills: Record<string, SkillRule>;
}

interface MatchedSkill {
    name: string;
    matchType: 'keyword' | 'intent';
    config: SkillRule;
}

interface EnhancementRule {
    patterns: string[];
    suggestions: string[];
    relatedSkill: string;
    priority: 'critical' | 'high' | 'medium' | 'low';
}

interface EnhancementRules {
    version: string;
    enhancementRules: Record<string, EnhancementRule>;
}

interface MatchedEnhancement {
    ruleName: string;
    suggestions: string[];
    relatedSkill: string;
    priority: string;
}

// Complexity analysis for default workflow recommendation
function analyzeComplexity(prompt: string): { skill: string; reason: string } {
    const lowerPrompt = prompt.toLowerCase();
    const length = prompt.length;

    // Keywords for parallel execution
    const parallelKeywords = ['여러', '동시', '병렬', 'parallel', 'concurrent', '각각', '모두', '전부'];
    const hasParallelIntent = parallelKeywords.some(kw => lowerPrompt.includes(kw));

    // Keywords for complex/orchestration
    const complexKeywords = ['복잡', '전체', '통합', '대규모', 'complex', 'full', 'entire', '시스템', '아키텍처'];
    const hasComplexIntent = complexKeywords.some(kw => lowerPrompt.includes(kw));

    // Keywords for simple sequential
    const simpleKeywords = ['간단', '단순', '하나', 'simple', 'single', 'quick', '빠르게'];
    const hasSimpleIntent = simpleKeywords.some(kw => lowerPrompt.includes(kw));

    // Decision logic
    if (hasSimpleIntent || length < 50) {
        return {
            skill: 'sequential-task-processor',
            reason: '간단한 순차 작업에 적합'
        };
    }

    if (hasParallelIntent) {
        return {
            skill: 'parallel-task-executor',
            reason: '독립 작업 병렬 처리에 최적'
        };
    }

    if (hasComplexIntent || length > 200) {
        return {
            skill: 'dynamic-task-orchestrator',
            reason: '복잡한 프로젝트 조율에 적합'
        };
    }

    // Default
    return {
        skill: 'agent-workflow-manager',
        reason: '자동 워크플로우 분석 및 실행'
    };
}

async function main() {
    try {
        // Read input from stdin
        const input = readFileSync(0, 'utf-8');
        const data: HookInput = JSON.parse(input);
        const prompt = data.prompt.toLowerCase();
        const originalPrompt = data.prompt;

        // Skip if already enhanced (prevent infinite loop)
        if (process.env.SKIP_PROMPT_ENHANCE === '1' ||
            prompt.includes('[enhanced]') ||
            prompt.includes('__skip_enhance__')) {
            process.exit(0);
        }

        // Load skill rules - check multiple locations
        const homeDir = process.env.HOME || process.env.USERPROFILE || '';
        const globalRulesPath = join(homeDir, '.claude', 'skills', 'skill-rules.json');
        const projectRulesPath = join(data.cwd, '.claude', 'skills', 'skill-rules.json');

        // Priority: project > global
        let rulesPath = globalRulesPath;
        if (existsSync(projectRulesPath)) {
            rulesPath = projectRulesPath;
        } else if (!existsSync(globalRulesPath)) {
            // No rules found anywhere, exit silently
            process.exit(0);
        }

        const rules: SkillRules = JSON.parse(readFileSync(rulesPath, 'utf-8'));

        // Load enhancement rules
        const enhancementRulesPath = join(data.cwd, '.claude', 'skills', 'prompt-enhancement-rules.json');
        let enhancementRules: EnhancementRules | null = null;
        if (existsSync(enhancementRulesPath)) {
            enhancementRules = JSON.parse(readFileSync(enhancementRulesPath, 'utf-8'));
        }

        const matchedSkills: MatchedSkill[] = [];
        const matchedEnhancements: MatchedEnhancement[] = [];

        // Check each skill for matches
        for (const [skillName, config] of Object.entries(rules.skills)) {
            const triggers = config.promptTriggers;
            if (!triggers) {
                continue;
            }

            // Keyword matching
            if (triggers.keywords) {
                const keywordMatch = triggers.keywords.some(kw =>
                    prompt.includes(kw.toLowerCase())
                );
                if (keywordMatch) {
                    matchedSkills.push({ name: skillName, matchType: 'keyword', config });
                    continue;
                }
            }

            // Intent pattern matching
            if (triggers.intentPatterns) {
                const intentMatch = triggers.intentPatterns.some(pattern => {
                    const regex = new RegExp(pattern, 'i');
                    return regex.test(prompt);
                });
                if (intentMatch) {
                    matchedSkills.push({ name: skillName, matchType: 'intent', config });
                }
            }
        }

        // Check enhancement rules
        if (enhancementRules) {
            for (const [ruleName, rule] of Object.entries(enhancementRules.enhancementRules)) {
                const patternMatch = rule.patterns.some(pattern =>
                    prompt.includes(pattern.toLowerCase())
                );
                if (patternMatch) {
                    matchedEnhancements.push({
                        ruleName,
                        suggestions: rule.suggestions,
                        relatedSkill: rule.relatedSkill,
                        priority: rule.priority
                    });
                }
            }
        }

        // Enhance prompt using Claude CLI headless mode
        let enhancedPrompt = '';
        const shouldEnhance = matchedSkills.length > 0 || matchedEnhancements.length > 0;

        if (shouldEnhance && originalPrompt.length > 10) {
            try {
                const enhanceInstruction = `prompt-enhancer 스킬을 사용하여 다음 프롬프트를 개선해주세요.
개선된 프롬프트만 간결하게 출력하세요. 설명 없이 개선된 프롬프트 텍스트만 출력.

원본 프롬프트: ${originalPrompt}`;

                enhancedPrompt = execSync(
                    `SKIP_PROMPT_ENHANCE=1 claude --print "${enhanceInstruction.replace(/"/g, '\\"')}"`,
                    {
                        encoding: 'utf-8',
                        timeout: 30000,
                        cwd: data.cwd,
                        env: { ...process.env, SKIP_PROMPT_ENHANCE: '1' }
                    }
                ).trim();
            } catch (err) {
                // If enhancement fails, continue without it
                enhancedPrompt = '';
            }
        }

        // Generate output if matches found
        if (matchedSkills.length > 0 || matchedEnhancements.length > 0) {
            let output = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
            output += '🎯 SKILL ACTIVATION CHECK\n';
            output += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';

            // Group skills by priority
            if (matchedSkills.length > 0) {
                const critical = matchedSkills.filter(s => s.config.priority === 'critical');
                const high = matchedSkills.filter(s => s.config.priority === 'high');
                const medium = matchedSkills.filter(s => s.config.priority === 'medium');
                const low = matchedSkills.filter(s => s.config.priority === 'low');

                if (critical.length > 0) {
                    output += '⚠️ CRITICAL SKILLS (REQUIRED):\n';
                    critical.forEach(s => output += `  → ${s.name}\n`);
                    output += '\n';
                }

                if (high.length > 0) {
                    output += '📚 RECOMMENDED SKILLS:\n';
                    high.forEach(s => output += `  → ${s.name}\n`);
                    output += '\n';
                }

                if (medium.length > 0) {
                    output += '💡 SUGGESTED SKILLS:\n';
                    medium.forEach(s => output += `  → ${s.name}\n`);
                    output += '\n';
                }

                if (low.length > 0) {
                    output += '📌 OPTIONAL SKILLS:\n';
                    low.forEach(s => output += `  → ${s.name}\n`);
                    output += '\n';
                }
            }

            // Add context enhancements
            if (matchedEnhancements.length > 0) {
                // Deduplicate suggestions
                const allSuggestions = new Set<string>();
                matchedEnhancements.forEach(e => {
                    e.suggestions.forEach(s => allSuggestions.add(s));
                });

                if (allSuggestions.size > 0) {
                    output += '📝 CONTEXT ENHANCEMENT:\n';
                    // Limit to top 5 suggestions
                    const suggestions = Array.from(allSuggestions).slice(0, 5);
                    suggestions.forEach(s => output += `  → ${s}\n`);
                    output += '\n';
                }
            }

            // Add enhanced prompt if available
            if (enhancedPrompt && enhancedPrompt.length > 0) {
                output += '🚀 ENHANCED PROMPT:\n';
                output += `${enhancedPrompt}\n\n`;
                output += 'ACTION: Use the enhanced prompt above\n';
            } else {
                output += 'ACTION: Use Skill tool BEFORE responding\n';
            }
            output += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';

            console.log(output);
        } else if (originalPrompt.length > 20) {
            // No matches found - recommend default workflow based on complexity
            const recommendation = analyzeComplexity(originalPrompt);

            let output = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
            output += '🎯 SKILL ACTIVATION CHECK\n';
            output += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
            output += '💡 DEFAULT WORKFLOW RECOMMENDATION:\n';
            output += `  → ${recommendation.skill}\n`;
            output += `    (${recommendation.reason})\n\n`;
            output += 'TIP: /auto-workflow 커맨드로 자동 분석 실행 가능\n';
            output += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';

            console.log(output);
        }

        process.exit(0);
    } catch (err) {
        console.error('Error in skill-activation-prompt hook:', err);
        process.exit(1);
    }
}

main().catch(err => {
    console.error('Uncaught error:', err);
    process.exit(1);
});
