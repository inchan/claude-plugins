#!/usr/bin/env node
/**
 * TF-IDF Skill Matcher
 * Uses Term Frequency-Inverse Document Frequency to rank skills by relevance
 *
 * v3.0.0 - TF-IDF based semantic matching
 */

const natural = require('natural');
const TfIdf = natural.TfIdf;
const fs = require('fs');

/**
 * Match skills using TF-IDF
 * @param {string} userPrompt - User's input prompt
 * @param {Array} candidates - Array of candidate skills
 * @returns {Array} Ranked skills with scores
 */
function matchSkillsTfIdf(userPrompt, candidates) {
    const tfidf = new TfIdf();
    const startTime = Date.now();

    // Add skill descriptions as documents
    candidates.forEach(skill => {
        const document = [
            skill.description || '',
            skill.keywords || '',
            skill.skill || ''
        ].join(' ');

        tfidf.addDocument(document);
    });

    // Calculate TF-IDF scores for user prompt
    const scores = [];
    tfidf.tfidfs(userPrompt, (i, measure) => {
        if (measure > 0) {
            scores.push({
                ...candidates[i],
                tfidfScore: measure
            });
        }
    });

    // Sort by score (descending)
    scores.sort((a, b) => b.tfidfScore - a.tfidfScore);

    const elapsedTime = Date.now() - startTime;

    return {
        matches: scores,
        metadata: {
            totalCandidates: candidates.length,
            matchedCandidates: scores.length,
            elapsedMs: elapsedTime,
            method: 'tfidf'
        }
    };
}

/**
 * Parse input from stdin or command line
 */
async function main() {
    let input = '';

    // Check if running in test mode
    if (process.argv.includes('--test')) {
        console.log('TF-IDF Matcher Test Mode');

        const testPrompt = '버그를 수정하고 싶어요';
        const testCandidates = [
            { plugin: 'dev-guidelines', skill: 'frontend-dev-guidelines', description: 'React and TypeScript development patterns' },
            { plugin: 'dev-guidelines', skill: 'error-tracking', description: 'Error tracking and bug fixing with Sentry' },
            { plugin: 'workflow-automation', skill: 'intelligent-task-router', description: 'Task routing and classification' }
        ];

        const result = matchSkillsTfIdf(testPrompt, testCandidates);
        console.log(JSON.stringify(result, null, 2));
        process.exit(0);
    }

    // Read from stdin
    if (!process.stdin.isTTY) {
        for await (const chunk of process.stdin) {
            input += chunk;
        }
    } else {
        console.error('Usage: echo \'{"prompt": "...", "candidates": [...]}\' | node tfidf-matcher.js');
        process.exit(1);
    }

    try {
        const data = JSON.parse(input);

        if (!data.prompt || !data.candidates) {
            throw new Error('Missing required fields: prompt, candidates');
        }

        const result = matchSkillsTfIdf(data.prompt, data.candidates);
        console.log(JSON.stringify(result, null, 2));

    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

// Run if called directly
if (require.main === module) {
    main();
}

module.exports = { matchSkillsTfIdf };
