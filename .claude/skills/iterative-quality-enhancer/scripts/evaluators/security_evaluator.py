"""Security Evaluator - Vulnerability detection and security best practices."""

from typing import Dict, Any, List
import re


class SecurityEvaluator:
    """Evaluate security: vulnerabilities, auth/authz, data protection."""

    def __init__(self, weight: float = 0.15, threshold: float = 0.95):
        self.weight = weight
        self.threshold = threshold

    def evaluate(self, artifact: Dict[str, Any]) -> Dict[str, Any]:
        """Evaluate security dimension."""
        code = artifact.get('code', '')

        scores = {
            'vulnerability_free': self._check_vulnerabilities(code),
            'auth_implementation': self._check_authentication(code),
            'data_protection': self._check_data_protection(code)
        }

        total_score = sum(scores.values()) / len(scores)

        return {
            'dimension': 'security',
            'score': total_score,
            'weight': self.weight,
            'threshold': self.threshold,
            'meets_threshold': total_score >= self.threshold,
            'sub_scores': scores,
            'feedback': self._generate_feedback(scores, code),
            'recommendations': self._generate_recommendations(scores, code)
        }

    def _check_vulnerabilities(self, code: str) -> float:
        """Check for common vulnerabilities."""
        score = 1.0

        # SQL Injection patterns
        sql_injection_patterns = [
            r'execute\([^?]*\+',  # String concatenation in SQL
            r'f"SELECT.*{',  # F-string in SQL
            r'"SELECT.*%s".*%',  # Old-style formatting
        ]

        for pattern in sql_injection_patterns:
            if re.search(pattern, code):
                score *= 0.3  # CRITICAL vulnerability

        # XSS patterns
        if re.search(r'\.innerHTML\s*=|document\.write', code):
            score *= 0.5

        # Command injection
        if re.search(r'os\.system|subprocess\.call.*\+', code):
            score *= 0.4

        # Eval usage
        if re.search(r'\beval\(', code):
            score *= 0.5

        return max(0.0, score)

    def _check_authentication(self, code: str) -> float:
        """Check authentication/authorization implementation."""
        score = 0.5  # Default neutral

        # Look for auth indicators
        has_auth = any(term in code.lower() for term in [
            'authenticate', 'login', 'password', 'token', 'session'
        ])

        if has_auth:
            # Check for weak hashing
            if 'hashlib.md5' in code or 'hashlib.sha1' in code:
                score = 0.3
            # Check for strong hashing
            elif 'bcrypt' in code or 'argon2' in code:
                score = 0.9
            else:
                score = 0.6

        return score

    def _check_data_protection(self, code: str) -> float:
        """Check data protection measures."""
        score = 1.0

        # Check for hardcoded secrets
        secrets_patterns = [
            r'password\s*=\s*["\'](?!{{)[\w!@#$%^&*]+["\']',
            r'api_key\s*=\s*["\'][\w-]+["\']',
            r'secret\s*=\s*["\'][\w-]+["\']',
        ]

        for pattern in secrets_patterns:
            if re.search(pattern, code, re.IGNORECASE):
                score *= 0.4

        # Check for encryption usage
        if any(term in code for term in ['encrypt', 'decrypt', 'AES', 'RSA']):
            score = min(1.0, score * 1.1)

        return max(0.3, score)

    def _generate_feedback(self, scores: Dict[str, float], code: str) -> List[str]:
        """Generate security feedback."""
        feedback = []

        if scores['vulnerability_free'] < 0.95:
            feedback.append("CRITICAL: Security vulnerabilities detected (SQL injection, XSS, etc.)")

        if scores['auth_implementation'] < 0.95:
            feedback.append("Authentication issues: Use strong hashing (bcrypt/argon2)")

        if scores['data_protection'] < 0.95:
            feedback.append("Data protection concerns: Remove hardcoded secrets")

        return feedback

    def _generate_recommendations(self, scores: Dict[str, float], code: str) -> List[str]:
        """Generate security recommendations."""
        recommendations = []

        if scores['vulnerability_free'] < 0.95:
            recommendations.append("Use parameterized queries to prevent SQL injection")
            recommendations.append("Sanitize and validate all user inputs")
            recommendations.append("Avoid using eval() or exec()")

        if scores['auth_implementation'] < 0.95:
            recommendations.append("Replace MD5/SHA1 with bcrypt or argon2")
            recommendations.append("Implement session timeout")
            recommendations.append("Add rate limiting to prevent brute force")

        if scores['data_protection'] < 0.95:
            recommendations.append("Use environment variables for secrets")
            recommendations.append("Encrypt sensitive data at rest")
            recommendations.append("Use HTTPS for data in transit")

        return recommendations
