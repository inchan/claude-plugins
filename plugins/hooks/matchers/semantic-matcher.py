#!/usr/bin/env python3
"""
Semantic Skill Matcher
Uses sentence-transformers to compute semantic similarity between prompts and skill descriptions

v3.0.0 - Embedding-based semantic matching
"""

import json
import sys
import time
from sentence_transformers import SentenceTransformer
import numpy as np

# Global model instance (loaded once for performance)
_model = None

def get_model():
    """Lazy load the sentence transformer model"""
    global _model
    if _model is None:
        # Use lightweight model for fast inference
        _model = SentenceTransformer('all-MiniLM-L6-v2')
    return _model

def match_skills_semantic(user_prompt, candidates):
    """
    Match skills using semantic similarity via sentence embeddings

    Args:
        user_prompt (str): User's input prompt
        candidates (list): List of candidate skills with descriptions

    Returns:
        dict: Ranked skills with cosine similarity scores
    """
    start_time = time.time()

    model = get_model()

    # Prepare skill texts
    skill_texts = []
    for skill in candidates:
        text = ' '.join([
            skill.get('description', ''),
            skill.get('keywords', ''),
            skill.get('skill', '')
        ])
        skill_texts.append(text)

    # Compute embeddings
    prompt_embedding = model.encode(user_prompt, convert_to_numpy=True)
    skill_embeddings = model.encode(skill_texts, convert_to_numpy=True)

    # Compute cosine similarity
    similarities = np.dot(skill_embeddings, prompt_embedding) / (
        np.linalg.norm(skill_embeddings, axis=1) * np.linalg.norm(prompt_embedding)
    )

    # Build results
    matches = []
    for i, similarity in enumerate(similarities):
        if similarity > 0.1:  # Threshold for relevance
            matches.append({
                **candidates[i],
                'semanticScore': float(similarity)
            })

    # Sort by similarity (descending)
    matches.sort(key=lambda x: x['semanticScore'], reverse=True)

    elapsed_time = (time.time() - start_time) * 1000  # Convert to ms

    return {
        'matches': matches,
        'metadata': {
            'totalCandidates': len(candidates),
            'matchedCandidates': len(matches),
            'elapsedMs': elapsed_time,
            'method': 'semantic-embedding'
        }
    }

def main():
    """Main entry point"""

    # Test mode
    if '--test' in sys.argv:
        print('Semantic Matcher Test Mode')

        test_prompt = '버그를 수정하고 싶어요'
        test_candidates = [
            {'plugin': 'dev-guidelines', 'skill': 'frontend-dev-guidelines', 'description': 'React and TypeScript development patterns'},
            {'plugin': 'dev-guidelines', 'skill': 'error-tracking', 'description': 'Error tracking and bug fixing with Sentry'},
            {'plugin': 'workflow-automation', 'skill': 'intelligent-task-router', 'description': 'Task routing and classification'}
        ]

        result = match_skills_semantic(test_prompt, test_candidates)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 0

    # Read from stdin
    try:
        input_data = sys.stdin.read()
        data = json.loads(input_data)

        if 'prompt' not in data or 'candidates' not in data:
            raise ValueError('Missing required fields: prompt, candidates')

        result = match_skills_semantic(data['prompt'], data['candidates'])
        print(json.dumps(result, indent=2, ensure_ascii=False))

        return 0

    except json.JSONDecodeError as e:
        print(f'Error: Invalid JSON input - {e}', file=sys.stderr)
        return 1
    except Exception as e:
        print(f'Error: {e}', file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
