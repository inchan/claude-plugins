"""
Intent-based Task Classification
Analyzes the underlying intent and action verbs in task requests.
"""

import re
from typing import Dict, List, Tuple
from enum import Enum


class IntentType(Enum):
    """Types of user intents."""
    CREATE = "create"
    MODIFY = "modify"
    DELETE = "delete"
    ANALYZE = "analyze"
    OPTIMIZE = "optimize"
    DEBUG = "debug"
    DOCUMENT = "document"
    TEST = "test"


class IntentClassifier:
    """Classifies tasks based on user intent and action verbs."""

    def __init__(self):
        """Initialize the intent classifier with action patterns."""
        self.intent_patterns = {
            IntentType.CREATE: {
                'verbs': ['생성', '추가', '만들', '구현', 'create', 'add', 'build', 'implement', 'develop'],
                'patterns': [r'새로운?\s+\w+', r'new\s+\w+']
            },
            IntentType.MODIFY: {
                'verbs': ['수정', '변경', '업데이트', '개선', 'modify', 'change', 'update', 'improve', 'enhance'],
                'patterns': [r'바꾸', r'바꿔', r'change\s+to']
            },
            IntentType.DELETE: {
                'verbs': ['삭제', '제거', '없애', 'delete', 'remove', 'eliminate'],
                'patterns': [r'지워', r'없애']
            },
            IntentType.ANALYZE: {
                'verbs': ['분석', '조사', '확인', '검토', 'analyze', 'investigate', 'check', 'review'],
                'patterns': [r'어떻게\s+\w+', r'왜\s+\w+', r'how\s+\w+', r'why\s+\w+']
            },
            IntentType.OPTIMIZE: {
                'verbs': ['최적화', '개선', '빠르게', 'optimize', 'improve', 'speed up', 'enhance'],
                'patterns': [r'성능', r'속도', r'performance', r'speed']
            },
            IntentType.DEBUG: {
                'verbs': ['수정', '고치', '해결', 'fix', 'debug', 'resolve', 'solve'],
                'patterns': [r'버그', r'에러', r'오류', r'bug', r'error', r'issue']
            },
            IntentType.DOCUMENT: {
                'verbs': ['문서화', '설명', '작성', 'document', 'explain', 'describe', 'write'],
                'patterns': [r'문서', r'주석', r'README', r'documentation', r'comment']
            },
            IntentType.TEST: {
                'verbs': ['테스트', '검증', '확인', 'test', 'verify', 'validate'],
                'patterns': [r'테스트\s+\w+', r'test\s+\w+']
            }
        }

    def extract_action_verbs(self, text: str) -> List[str]:
        """
        Extract action verbs from text.

        Args:
            text: Input text to analyze

        Returns:
            List of action verbs found
        """
        text_lower = text.lower()
        found_verbs = []

        for intent_type, patterns in self.intent_patterns.items():
            for verb in patterns['verbs']:
                if verb.lower() in text_lower:
                    found_verbs.append(verb)

        return found_verbs

    def detect_intent(self, text: str) -> Tuple[IntentType, float]:
        """
        Detect the primary intent from text.

        Args:
            text: Input text to analyze

        Returns:
            Tuple of (intent_type, confidence_score)
        """
        text_lower = text.lower()
        intent_scores = {intent: 0.0 for intent in IntentType}

        for intent_type, patterns in self.intent_patterns.items():
            score = 0.0

            # Check verbs
            for verb in patterns['verbs']:
                if verb.lower() in text_lower:
                    score += 1.0

            # Check patterns
            for pattern in patterns['patterns']:
                if re.search(pattern, text_lower):
                    score += 0.5

            intent_scores[intent_type] = score

        # Get top intent
        max_intent = max(intent_scores.items(), key=lambda x: x[1])

        # Calculate confidence (normalize by max possible score)
        max_score = len(self.intent_patterns[max_intent[0]]['verbs']) + \
                   len(self.intent_patterns[max_intent[0]]['patterns']) * 0.5
        confidence = min(max_intent[1] / max_score, 1.0) if max_score > 0 else 0.0

        return max_intent[0], confidence

    def classify(self, text: str) -> Dict[str, any]:
        """
        Classify task intent with detailed analysis.

        Args:
            text: Task description

        Returns:
            Dictionary containing intent classification results
        """
        intent_type, confidence = self.detect_intent(text)
        action_verbs = self.extract_action_verbs(text)

        return {
            'intent': intent_type.value,
            'confidence': confidence,
            'action_verbs': action_verbs,
            'is_question': '?' in text or any(q in text.lower() for q in ['어떻게', '왜', 'how', 'why', 'what'])
        }


def main():
    """Example usage of IntentClassifier."""
    classifier = IntentClassifier()

    test_cases = [
        "새로운 로그인 기능을 구현해주세요",
        "버그를 수정해주세요",
        "코드 성능을 최적화해주세요",
        "이 함수가 어떻게 동작하는지 설명해주세요",
        "테스트 케이스를 작성해주세요"
    ]

    for text in test_cases:
        result = classifier.classify(text)
        print(f"\n입력: {text}")
        print(f"의도: {result['intent']}")
        print(f"신뢰도: {result['confidence']:.2f}")
        print(f"동작 동사: {result['action_verbs']}")
        print(f"질문 여부: {result['is_question']}")


if __name__ == "__main__":
    main()
