#!/usr/bin/env node
const { readFileSync, appendFileSync, existsSync, mkdirSync } = require('fs');
const { join } = require('path');

async function main() {
    try {
        // Read input from stdin
        const input = readFileSync(0, 'utf-8');
        const data = JSON.parse(input);
        const prompt = data.prompt.toLowerCase();

        // Meta-prompt generator 관련 키워드 확인
        const metaPromptKeywords = [
            '프롬프트 만들',
            '프롬프트 생성',
            '슬래시 커맨드',
            'slash command',
            '워크플로우 만들',
            '커스텀 프롬프트',
            'custom prompt',
            '자동화',
            'automation'
        ];

        const matchedKeywords = metaPromptKeywords.filter(keyword =>
            prompt.includes(keyword)
        );

        // 매칭되는 키워드가 있으면 로그 기록
        if (matchedKeywords.length > 0) {
            const homeDir = process.env.HOME || process.env.USERPROFILE || '';
            const logsDir = join(homeDir, '.claude', 'hooks', 'logs');

            // 로그 디렉토리가 없으면 생성
            if (!existsSync(logsDir)) {
                mkdirSync(logsDir, { recursive: true });
            }

            // 프로젝트 이름 추출 (cwd의 마지막 디렉토리명)
            const projectName = data.cwd.split('/').filter(Boolean).pop() || 'unknown';

            // 로그 엔트리 생성
            const logEntry = {
                timestamp: new Date().toISOString(),
                session_id: data.session_id,
                project_name: projectName,
                cwd: data.cwd,
                original_prompt: data.prompt.substring(0, 200), // 처음 200자만
                improvement_type: 'meta-prompt-generation',
                matched_keywords: matchedKeywords
            };

            // 로그 파일 경로 (날짜별로 구분)
            const date = new Date().toISOString().split('T')[0];
            const logFile = join(logsDir, `meta-prompt-${date}.jsonl`);

            // JSONL 형식으로 로그 추가
            appendFileSync(logFile, JSON.stringify(logEntry) + '\n', 'utf-8');

            // 사람이 읽기 쉬운 형식의 로그도 생성
            const readableLogFile = join(logsDir, `meta-prompt-${date}.log`);
            const readableEntry = [
                '\n' + '='.repeat(80),
                `시간: ${new Date().toLocaleString('ko-KR')}`,
                `세션: ${data.session_id}`,
                `프로젝트: ${projectName}`,
                `경로: ${data.cwd}`,
                `프롬프트: ${data.prompt.substring(0, 200)}...`,
                `개선 타입: 메타 프롬프트 생성`,
                `매칭 키워드: ${matchedKeywords.join(', ')}`,
                '='.repeat(80) + '\n'
            ].join('\n');

            appendFileSync(readableLogFile, readableEntry, 'utf-8');
            
            console.log('✅ 로그 기록 완료!');
        }

        process.exit(0);
    } catch (err) {
        console.error('Error in meta-prompt-logger hook:', err);
        process.exit(1);
    }
}

main().catch(err => {
    console.error('Uncaught error:', err);
    process.exit(1);
});
