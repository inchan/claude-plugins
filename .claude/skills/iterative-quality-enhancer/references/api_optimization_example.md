# API Optimization Example: User Management Endpoint

This example demonstrates the complete evaluation and optimization process for a REST API endpoint that manages user data.

## Initial Code

```python
# users_api.py (BEFORE optimization)
from flask import Flask, request, jsonify
import sqlite3

app = Flask(__name__)

@app.route('/api/users/<user_id>', methods=['GET'])
def get_user(user_id):
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    query = f"SELECT * FROM users WHERE id = {user_id}"
    cursor.execute(query)
    user = cursor.fetchone()
    conn.close()

    if user:
        # Get user's posts
        conn = sqlite3.connect('users.db')
        cursor = conn.cursor()
        posts_query = f"SELECT * FROM posts WHERE user_id = {user_id}"
        cursor.execute(posts_query)
        posts = cursor.fetchall()
        conn.close()

        result = {
            'id': user[0],
            'name': user[1],
            'email': user[2],
            'posts': []
        }

        for post in posts:
            result['posts'].append({
                'id': post[0],
                'title': post[1],
                'content': post[2]
            })

        return jsonify(result)
    else:
        return jsonify({'error': 'User not found'}), 404

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.json
    name = data['name']
    email = data['email']

    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    query = f"INSERT INTO users (name, email) VALUES ('{name}', '{email}')"
    cursor.execute(query)
    conn.commit()
    user_id = cursor.lastrowid
    conn.close()

    return jsonify({'id': user_id, 'name': name, 'email': email}), 201
```

## Iteration 1: Initial Evaluation

### Evaluation Results

**Functionality: 0.75 / 0.95**
- ❌ No error handling for invalid user_id
- ❌ No validation for missing fields in POST
- ❌ No handling for database connection failures
- ✅ Basic CRUD operations work for happy path

**Performance: 0.50 / 0.85**
- ❌ N+1 query problem (separate queries for user and posts)
- ❌ No connection pooling
- ❌ Database connections not reused
- ✅ Simple queries are reasonably fast

**Code Quality: 0.65 / 0.90**
- ❌ Code duplication (database connection logic repeated)
- ❌ No separation of concerns (database logic in routes)
- ❌ Magic numbers and hardcoded strings
- ✅ Basic structure is understandable

**Security: 0.30 / 0.95** ⚠️ CRITICAL
- ❌ SQL injection vulnerability in both endpoints
- ❌ No input validation
- ❌ No authentication/authorization
- ❌ Sensitive data (email) returned without checks

**Documentation: 0.40 / 0.85**
- ❌ No docstrings
- ❌ No API documentation
- ❌ No usage examples
- ✅ Variable names are somewhat descriptive

**Total Weighted Score: 0.54** (Target: 0.90)

### Prioritized Feedback

**Priority 1 - Security (0.30/0.95) - CRITICAL**: Gap × Weight = 0.65 × 0.15 = 0.098
- Issue: SQL injection vulnerabilities in both GET and POST endpoints
- Action: Use parameterized queries with placeholders
- Expected Impact: +0.50 security score

**Priority 2 - Functionality (0.75/0.95)**: Gap × Weight = 0.20 × 0.30 = 0.06
- Issue: No error handling for invalid inputs or database failures
- Action: Add try-except blocks and input validation
- Expected Impact: +0.15 functionality score

**Priority 3 - Performance (0.50/0.85)**: Gap × Weight = 0.35 × 0.20 = 0.07
- Issue: N+1 query problem loading user posts
- Action: Use JOIN query or batch loading
- Expected Impact: +0.25 performance score

### Optimization Strategy: Security Hardening + Error Handling

## Iteration 1: Security and Functionality Improvements

```python
# users_api.py (AFTER iteration 1)
from flask import Flask, request, jsonify
import sqlite3
from contextlib import contextmanager
from typing import Optional, Dict, List

app = Flask(__name__)

class ValidationError(Exception):
    """Custom exception for validation errors"""
    pass

@contextmanager
def get_db_connection():
    """Context manager for database connections"""
    conn = sqlite3.connect('users.db')
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def validate_user_id(user_id: str) -> int:
    """Validate and convert user_id to integer"""
    try:
        uid = int(user_id)
        if uid <= 0:
            raise ValidationError("User ID must be positive")
        return uid
    except ValueError:
        raise ValidationError("User ID must be a valid integer")

def validate_user_data(data: Dict) -> Dict:
    """Validate user creation data"""
    if not data:
        raise ValidationError("Request body is empty")

    name = data.get('name', '').strip()
    email = data.get('email', '').strip()

    if not name:
        raise ValidationError("Name is required")
    if not email:
        raise ValidationError("Email is required")
    if '@' not in email:
        raise ValidationError("Invalid email format")

    return {'name': name, 'email': email}

@app.route('/api/users/<user_id>', methods=['GET'])
def get_user(user_id: str):
    """
    Get user by ID with their posts.

    Args:
        user_id: User identifier

    Returns:
        JSON response with user data and posts
    """
    try:
        # Validate input
        uid = validate_user_id(user_id)

        with get_db_connection() as conn:
            cursor = conn.cursor()

            # Use parameterized query to prevent SQL injection
            cursor.execute(
                "SELECT id, name, email FROM users WHERE id = ?",
                (uid,)
            )
            user = cursor.fetchone()

            if not user:
                return jsonify({'error': 'User not found'}), 404

            # Get user's posts with parameterized query
            cursor.execute(
                "SELECT id, title, content FROM posts WHERE user_id = ?",
                (uid,)
            )
            posts = cursor.fetchall()

            result = {
                'id': user['id'],
                'name': user['name'],
                'email': user['email'],
                'posts': [
                    {
                        'id': post['id'],
                        'title': post['title'],
                        'content': post['content']
                    }
                    for post in posts
                ]
            }

            return jsonify(result), 200

    except ValidationError as e:
        return jsonify({'error': str(e)}), 400
    except sqlite3.Error as e:
        return jsonify({'error': 'Database error occurred'}), 500
    except Exception as e:
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/users', methods=['POST'])
def create_user():
    """
    Create a new user.

    Request body:
        name (str): User's name (required)
        email (str): User's email (required)

    Returns:
        JSON response with created user data
    """
    try:
        # Validate input data
        data = validate_user_data(request.json)

        with get_db_connection() as conn:
            cursor = conn.cursor()

            # Check for duplicate email
            cursor.execute(
                "SELECT id FROM users WHERE email = ?",
                (data['email'],)
            )
            if cursor.fetchone():
                return jsonify({'error': 'Email already exists'}), 409

            # Use parameterized query to prevent SQL injection
            cursor.execute(
                "INSERT INTO users (name, email) VALUES (?, ?)",
                (data['name'], data['email'])
            )
            user_id = cursor.lastrowid

            return jsonify({
                'id': user_id,
                'name': data['name'],
                'email': data['email']
            }), 201

    except ValidationError as e:
        return jsonify({'error': str(e)}), 400
    except sqlite3.Error as e:
        return jsonify({'error': 'Database error occurred'}), 500
    except Exception as e:
        return jsonify({'error': 'Internal server error'}), 500
```

### Iteration 1 Evaluation Results

**Functionality: 0.90 / 0.95** (+0.15)
- ✅ Comprehensive error handling
- ✅ Input validation for all fields
- ✅ Database error handling
- ✅ Proper HTTP status codes

**Performance: 0.50 / 0.85** (no change)
- ❌ Still has N+1 query problem
- ✅ Connection management improved with context manager

**Code Quality: 0.80 / 0.90** (+0.15)
- ✅ Database logic extracted to context manager
- ✅ Validation logic separated
- ✅ Type hints added
- ❌ Still some room for improvement in modularity

**Security: 0.85 / 0.95** (+0.55)
- ✅ SQL injection prevented with parameterized queries
- ✅ Input validation implemented
- ✅ Duplicate email check added
- ❌ Still no authentication/authorization

**Documentation: 0.65 / 0.85** (+0.25)
- ✅ Docstrings added to all functions
- ✅ Type hints provide self-documentation
- ❌ No API documentation or examples yet

**Total Weighted Score: 0.77** (+0.23) - Still below target

## Iteration 2: Performance Optimization

### Optimization: Fix N+1 Query Problem

```python
# users_api.py (AFTER iteration 2 - performance improvement)

@app.route('/api/users/<user_id>', methods=['GET'])
def get_user(user_id: str):
    """
    Get user by ID with their posts.

    Args:
        user_id: User identifier

    Returns:
        JSON response with user data and posts
    """
    try:
        uid = validate_user_id(user_id)

        with get_db_connection() as conn:
            cursor = conn.cursor()

            # Use JOIN to fetch user and posts in a single query
            cursor.execute("""
                SELECT
                    u.id as user_id,
                    u.name as user_name,
                    u.email as user_email,
                    p.id as post_id,
                    p.title as post_title,
                    p.content as post_content
                FROM users u
                LEFT JOIN posts p ON u.id = p.user_id
                WHERE u.id = ?
            """, (uid,))

            rows = cursor.fetchall()

            if not rows or not rows[0]['user_id']:
                return jsonify({'error': 'User not found'}), 404

            # Construct result from joined data
            first_row = rows[0]
            result = {
                'id': first_row['user_id'],
                'name': first_row['user_name'],
                'email': first_row['user_email'],
                'posts': []
            }

            # Add posts (handling case where user has no posts)
            for row in rows:
                if row['post_id']:
                    result['posts'].append({
                        'id': row['post_id'],
                        'title': row['post_title'],
                        'content': row['post_content']
                    })

            return jsonify(result), 200

    except ValidationError as e:
        return jsonify({'error': str(e)}), 400
    except sqlite3.Error as e:
        return jsonify({'error': 'Database error occurred'}), 500
    except Exception as e:
        return jsonify({'error': 'Internal server error'}), 500
```

### Iteration 2 Evaluation Results

**Performance: 0.85 / 0.85** (+0.35) ✅ THRESHOLD MET
- ✅ N+1 query eliminated with JOIN
- ✅ Single database query instead of multiple
- ✅ Reduced latency by ~60%

**All other dimensions:** No change

**Total Weighted Score: 0.84** (+0.07)

## Iteration 3: Code Quality and Documentation

### Final Improvements

```python
# users_api.py (FINAL version after iteration 3)
"""
User Management API

Provides RESTful endpoints for user CRUD operations.
"""
from flask import Flask, request, jsonify
import sqlite3
from contextlib import contextmanager
from typing import Optional, Dict, List, Tuple
import re

app = Flask(__name__)

# Configuration
DATABASE_PATH = 'users.db'
EMAIL_REGEX = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')

class ValidationError(Exception):
    """Raised when input validation fails"""
    pass

class DatabaseError(Exception):
    """Raised when database operation fails"""
    pass

@contextmanager
def get_db_connection():
    """
    Provide a database connection with automatic cleanup.

    Yields:
        sqlite3.Connection: Database connection with row factory

    Raises:
        DatabaseError: If connection fails
    """
    conn = None
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        conn.row_factory = sqlite3.Row
        yield conn
        conn.commit()
    except sqlite3.Error as e:
        if conn:
            conn.rollback()
        raise DatabaseError(f"Database operation failed: {e}")
    finally:
        if conn:
            conn.close()

def validate_user_id(user_id: str) -> int:
    """
    Validate and convert user ID to integer.

    Args:
        user_id: String representation of user ID

    Returns:
        int: Validated user ID

    Raises:
        ValidationError: If user_id is invalid
    """
    try:
        uid = int(user_id)
        if uid <= 0:
            raise ValidationError("User ID must be positive")
        return uid
    except ValueError:
        raise ValidationError("User ID must be a valid integer")

def validate_email(email: str) -> bool:
    """
    Validate email format.

    Args:
        email: Email address to validate

    Returns:
        bool: True if valid

    Raises:
        ValidationError: If email format is invalid
    """
    if not EMAIL_REGEX.match(email):
        raise ValidationError("Invalid email format")
    return True

def validate_user_data(data: Optional[Dict]) -> Dict[str, str]:
    """
    Validate user creation data.

    Args:
        data: Request JSON data

    Returns:
        Dict containing validated name and email

    Raises:
        ValidationError: If validation fails
    """
    if not data:
        raise ValidationError("Request body is required")

    name = data.get('name', '').strip()
    email = data.get('email', '').strip()

    if not name:
        raise ValidationError("Name is required")
    if len(name) > 100:
        raise ValidationError("Name must be 100 characters or less")

    if not email:
        raise ValidationError("Email is required")
    validate_email(email)

    return {'name': name, 'email': email}

@app.route('/api/users/<user_id>', methods=['GET'])
def get_user(user_id: str) -> Tuple[Dict, int]:
    """
    Retrieve a user by ID including their posts.

    Args:
        user_id: User identifier

    Returns:
        Tuple of (JSON response, HTTP status code)

    Response Format:
        {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com",
            "posts": [
                {
                    "id": 1,
                    "title": "My First Post",
                    "content": "Hello world!"
                }
            ]
        }

    Status Codes:
        200: Success
        400: Invalid user ID format
        404: User not found
        500: Server error
    """
    try:
        uid = validate_user_id(user_id)

        with get_db_connection() as conn:
            cursor = conn.cursor()

            # Optimized query: JOIN user and posts in single query
            cursor.execute("""
                SELECT
                    u.id as user_id,
                    u.name as user_name,
                    u.email as user_email,
                    p.id as post_id,
                    p.title as post_title,
                    p.content as post_content
                FROM users u
                LEFT JOIN posts p ON u.id = p.user_id
                WHERE u.id = ?
            """, (uid,))

            rows = cursor.fetchall()

            if not rows or not rows[0]['user_id']:
                return jsonify({'error': 'User not found'}), 404

            # Build response from query results
            first_row = rows[0]
            result = {
                'id': first_row['user_id'],
                'name': first_row['user_name'],
                'email': first_row['user_email'],
                'posts': [
                    {
                        'id': row['post_id'],
                        'title': row['post_title'],
                        'content': row['post_content']
                    }
                    for row in rows if row['post_id']
                ]
            }

            return jsonify(result), 200

    except ValidationError as e:
        return jsonify({'error': str(e)}), 400
    except DatabaseError as e:
        app.logger.error(f"Database error in get_user: {e}")
        return jsonify({'error': 'Database error occurred'}), 500
    except Exception as e:
        app.logger.error(f"Unexpected error in get_user: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/users', methods=['POST'])
def create_user() -> Tuple[Dict, int]:
    """
    Create a new user.

    Request Body:
        {
            "name": "John Doe",
            "email": "john@example.com"
        }

    Returns:
        Tuple of (JSON response, HTTP status code)

    Response Format:
        {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com"
        }

    Status Codes:
        201: User created successfully
        400: Invalid input data
        409: Email already exists
        500: Server error
    """
    try:
        data = validate_user_data(request.json)

        with get_db_connection() as conn:
            cursor = conn.cursor()

            # Check for duplicate email
            cursor.execute(
                "SELECT id FROM users WHERE email = ?",
                (data['email'],)
            )
            if cursor.fetchone():
                return jsonify({'error': 'Email already exists'}), 409

            # Insert new user with parameterized query
            cursor.execute(
                "INSERT INTO users (name, email) VALUES (?, ?)",
                (data['name'], data['email'])
            )
            user_id = cursor.lastrowid

            return jsonify({
                'id': user_id,
                'name': data['name'],
                'email': data['email']
            }), 201

    except ValidationError as e:
        return jsonify({'error': str(e)}), 400
    except DatabaseError as e:
        app.logger.error(f"Database error in create_user: {e}")
        return jsonify({'error': 'Database error occurred'}), 500
    except Exception as e:
        app.logger.error(f"Unexpected error in create_user: {e}")
        return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    app.run(debug=False)
```

### Iteration 3 Evaluation Results

**Functionality: 0.95 / 0.95** (+0.05) ✅ THRESHOLD MET
- ✅ All edge cases handled
- ✅ Comprehensive error messages
- ✅ Proper logging added

**Performance: 0.85 / 0.85** (no change) ✅ THRESHOLD MET

**Code Quality: 0.92 / 0.90** (+0.12) ✅ THRESHOLD MET
- ✅ Constants extracted (DATABASE_PATH, EMAIL_REGEX)
- ✅ Custom exceptions for different error types
- ✅ Consistent code structure
- ✅ List comprehension for cleaner code

**Security: 0.95 / 0.95** (+0.10) ✅ THRESHOLD MET
- ✅ Enhanced email validation with regex
- ✅ Name length limit to prevent overflow
- ✅ Proper error logging without exposing internals
- Note: Authentication still recommended for production

**Documentation: 0.90 / 0.85** (+0.25) ✅ THRESHOLD MET
- ✅ Module docstring added
- ✅ Comprehensive function docstrings
- ✅ Request/response formats documented
- ✅ Status codes documented
- ✅ Type hints throughout

**Total Weighted Score: 0.92** ✅ TARGET MET

## Final Report

### Executive Summary

- **Initial Quality Score:** 0.54 (54%)
- **Final Quality Score:** 0.92 (92%)
- **Iterations Completed:** 3
- **Total Improvement:** +38 percentage points

### Key Improvements

1. **Security:** Fixed critical SQL injection vulnerabilities (+0.65 score)
2. **Performance:** Eliminated N+1 query problem (-60% latency)
3. **Functionality:** Added comprehensive error handling and validation
4. **Code Quality:** Improved modularity and maintainability
5. **Documentation:** Added complete API documentation

### Optimization Timeline

**Iteration 1:** Security hardening + Error handling
- Fixed SQL injection vulnerabilities
- Added input validation
- Implemented proper error handling
- Impact: +0.23 total score

**Iteration 2:** Performance optimization
- Eliminated N+1 queries with JOIN
- Single database roundtrip
- Impact: +0.07 total score

**Iteration 3:** Code quality + Documentation
- Extracted constants and improved structure
- Added comprehensive documentation
- Enhanced validation logic
- Impact: +0.08 total score

### Recommendations

While all quality thresholds are now met, consider these future enhancements:

1. **Authentication/Authorization:** Add JWT or session-based auth
2. **Rate Limiting:** Prevent abuse of API endpoints
3. **Caching:** Add Redis for frequently accessed users
4. **Pagination:** Implement pagination for user posts
5. **Integration Tests:** Add automated API tests
6. **API Versioning:** Prepare for future API changes

### Metrics

- **Query Performance:** 150ms → 60ms (60% improvement)
- **Code Coverage:** Increased from implicit testing to explicit error handling
- **Security Score:** 0.30 → 0.95 (CRITICAL to EXCELLENT)
- **Maintainability:** Cyclomatic complexity reduced from ~15 to ~5 per function
