# Example: Building a React Dashboard Application

This document demonstrates a complete walkthrough of using the Sequential Task Processor skill to build a React dashboard application with user authentication.

## Task Input

**Original Request:**
```json
{
  "task_id": "task_20241111_dashboard",
  "task_description": "Build a React dashboard application with user authentication",
  "from_skill": "user",
  "priority": "high",
  "context": {
    "user_requirements": "Need a modern dashboard to display analytics data with secure login",
    "constraints": [
      "Use TypeScript",
      "Use Material-UI for components",
      "Support JWT authentication",
      "Responsive design"
    ]
  }
}
```

## Step-by-Step Execution

### Step 1: Analysis (Requirements Gathering)

**Input**: Original task request

**Process:**
1. Load `assets/templates/requirements.md.tmpl`
2. Fill in task-specific details
3. Identify functional and non-functional requirements
4. Document constraints and assumptions

**Output**: `.sequential_cache/task_20241111_dashboard/requirements.md`

**Key Requirements Identified:**
- **FR-1**: User authentication (login/logout)
- **FR-2**: Dashboard with multiple widget types
- **FR-3**: Real-time data updates
- **FR-4**: User profile management
- **FR-5**: Role-based access control

**Non-Functional Requirements:**
- Performance: Page load < 2 seconds
- Security: JWT-based authentication
- Usability: Mobile-responsive design
- Browser: Support Chrome, Firefox, Safari (latest 2 versions)

**Validation:**
```bash
python3 scripts/step_validator.py task_20241111_dashboard analysis
```

**Validation Result:**
```
============================================================
Validation Result: PASSED
============================================================

Checks Run: 3
  ✅ PASS - completeness: Required sections: 5, Found: 5
  ✅ PASS - format: Markdown structure and frontmatter validation
  ✅ PASS - min_requirements: Found 5 requirements, minimum required: 3

Recommendation: PROCEED
============================================================
```

---

### Step 2: Design (Architecture)

**Input**: `requirements.md` from Step 1

**Process:**
1. Load `assets/templates/architecture.md.tmpl`
2. Read requirements from Step 1
3. Design system architecture
4. Define components and data models
5. Specify API contracts

**Output**: `.sequential_cache/task_20241111_dashboard/architecture.md`

**Architecture Pattern**: Component-Based Architecture with Redux for state management

**High-Level Components:**
```
┌─────────────────────────────────────────────┐
│         React Frontend (SPA)                │
│  ┌─────────────┐  ┌─────────────┐          │
│  │   Auth      │  │  Dashboard  │          │
│  │  Components │  │ Components  │          │
│  └──────┬──────┘  └──────┬──────┘          │
│         │                │                  │
│  ┌──────▼────────────────▼──────┐          │
│  │      Redux State Store       │          │
│  └──────────────┬────────────────┘          │
└─────────────────┼─────────────────────────┘
                  │
┌─────────────────▼─────────────────────────┐
│          Backend API (REST)                │
│  ┌─────────────┐  ┌─────────────┐         │
│  │    Auth     │  │  Dashboard  │         │
│  │   Service   │  │   Service   │         │
│  └──────┬──────┘  └──────┬──────┘         │
│         │                │                 │
│  ┌──────▼────────────────▼──────┐         │
│  │      PostgreSQL Database     │         │
│  └──────────────────────────────┘         │
└───────────────────────────────────────────┘
```

**Technology Stack:**
- **Frontend**: React 18, TypeScript, Material-UI v5, Redux Toolkit
- **Backend**: Node.js, Express, TypeScript
- **Database**: PostgreSQL 15
- **Authentication**: JWT with refresh tokens
- **Build**: Vite

**Data Models:**

```typescript
// User Model
interface User {
  id: string;
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  role: 'admin' | 'user';
  createdAt: Date;
  updatedAt: Date;
}

// Dashboard Widget Model
interface Widget {
  id: string;
  userId: string;
  type: 'chart' | 'metric' | 'table';
  title: string;
  config: WidgetConfig;
  position: { x: number; y: number; w: number; h: number };
}

// Analytics Data Model
interface AnalyticsData {
  id: string;
  widgetId: string;
  timestamp: Date;
  data: Record<string, any>;
}
```

**API Endpoints:**

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/login` | POST | User login |
| `/api/auth/logout` | POST | User logout |
| `/api/auth/refresh` | POST | Refresh JWT token |
| `/api/dashboard/widgets` | GET | Get user's widgets |
| `/api/dashboard/widgets` | POST | Create new widget |
| `/api/dashboard/widgets/:id` | PUT | Update widget |
| `/api/dashboard/widgets/:id` | DELETE | Delete widget |
| `/api/analytics/data/:widgetId` | GET | Get widget data |

**Validation:**
```bash
python3 scripts/step_validator.py task_20241111_dashboard design
```

**Validation Result:**
```
============================================================
Validation Result: PASSED
============================================================

Checks Run: 4
  ✅ PASS - completeness: Required sections: 4, Found: 4
  ✅ PASS - format: Markdown structure and frontmatter validation
  ✅ PASS - consistency: Content consistency validation
  ✅ PASS - references_previous_step: Verification of previous step references

Recommendation: PROCEED
============================================================
```

---

### Step 3: Implementation

**Input**: `architecture.md` from Step 2

**Process:**
1. Create project structure
2. Implement authentication system
3. Build dashboard components
4. Integrate API calls
5. Add state management
6. Style with Material-UI

**Output**: `.sequential_cache/task_20241111_dashboard/implementation/`

**Project Structure:**
```
dashboard-app/
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Auth/
│   │   │   │   ├── LoginForm.tsx
│   │   │   │   └── ProtectedRoute.tsx
│   │   │   └── Dashboard/
│   │   │       ├── DashboardLayout.tsx
│   │   │       ├── Widget.tsx
│   │   │       └── WidgetGrid.tsx
│   │   ├── store/
│   │   │   ├── authSlice.ts
│   │   │   ├── dashboardSlice.ts
│   │   │   └── store.ts
│   │   ├── services/
│   │   │   ├── authService.ts
│   │   │   └── dashboardService.ts
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── package.json
│   └── vite.config.ts
├── backend/
│   ├── src/
│   │   ├── controllers/
│   │   │   ├── authController.ts
│   │   │   └── dashboardController.ts
│   │   ├── services/
│   │   │   ├── authService.ts
│   │   │   └── dashboardService.ts
│   │   ├── models/
│   │   │   ├── User.ts
│   │   │   └── Widget.ts
│   │   ├── middleware/
│   │   │   └── authMiddleware.ts
│   │   ├── routes/
│   │   │   ├── authRoutes.ts
│   │   │   └── dashboardRoutes.ts
│   │   └── server.ts
│   ├── package.json
│   └── tsconfig.json
└── README.md
```

**Key Implementation Highlights:**

**1. Authentication Service (frontend/src/services/authService.ts):**
```typescript
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL;

export const authService = {
  async login(email: string, password: string) {
    const response = await axios.post(`${API_URL}/auth/login`, {
      email,
      password
    });

    const { token, refreshToken, user } = response.data;

    // Store tokens
    localStorage.setItem('token', token);
    localStorage.setItem('refreshToken', refreshToken);

    return user;
  },

  async logout() {
    const token = localStorage.getItem('token');
    await axios.post(`${API_URL}/auth/logout`, {}, {
      headers: { Authorization: `Bearer ${token}` }
    });

    localStorage.removeItem('token');
    localStorage.removeItem('refreshToken');
  },

  async refreshToken() {
    const refreshToken = localStorage.getItem('refreshToken');
    const response = await axios.post(`${API_URL}/auth/refresh`, {
      refreshToken
    });

    const { token } = response.data;
    localStorage.setItem('token', token);

    return token;
  }
};
```

**2. Dashboard Widget Component (frontend/src/components/Dashboard/Widget.tsx):**
```typescript
import React from 'react';
import { Card, CardContent, Typography, IconButton } from '@mui/material';
import { Delete, Edit } from '@mui/icons-material';
import { useAppDispatch } from '../../store/store';
import { deleteWidget } from '../../store/dashboardSlice';

interface WidgetProps {
  widget: Widget;
  onEdit: (widget: Widget) => void;
}

export const Widget: React.FC<WidgetProps> = ({ widget, onEdit }) => {
  const dispatch = useAppDispatch();

  const handleDelete = () => {
    dispatch(deleteWidget(widget.id));
  };

  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Typography variant="h6" component="div">
          {widget.title}
          <IconButton size="small" onClick={() => onEdit(widget)}>
            <Edit fontSize="small" />
          </IconButton>
          <IconButton size="small" onClick={handleDelete}>
            <Delete fontSize="small" />
          </IconButton>
        </Typography>
        <WidgetContent widget={widget} />
      </CardContent>
    </Card>
  );
};
```

**3. Backend Authentication Middleware (backend/src/middleware/authMiddleware.ts):**
```typescript
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET!;

export interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    role: string;
  };
}

export const authMiddleware = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    req.user = {
      id: decoded.userId,
      email: decoded.email,
      role: decoded.role
    };
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};
```

**Validation:**
```bash
# Compile check
cd frontend && npm run build
cd backend && npm run build

# Lint check
cd frontend && npm run lint
cd backend && npm run lint
```

**Validation Result:**
```
============================================================
Validation Result: PASSED
============================================================

Checks Run: 3
  ✅ PASS - compile_check: TypeScript compilation successful
  ✅ PASS - lint_check: ESLint checks passed
  ✅ PASS - syntax_check: No syntax errors found

Recommendation: PROCEED
============================================================
```

---

### Step 4: Testing

**Input**: Implementation from Step 3

**Process:**
1. Write unit tests for components and services
2. Write integration tests for API endpoints
3. Write E2E tests for critical user flows
4. Run all tests and generate coverage report

**Output**: `.sequential_cache/task_20241111_dashboard/test_results.md`

**Test Suite Summary:**

**Unit Tests (Frontend):**
```bash
npm run test:unit

# Results:
PASS  src/components/Auth/LoginForm.test.tsx
PASS  src/components/Dashboard/Widget.test.tsx
PASS  src/store/authSlice.test.ts
PASS  src/store/dashboardSlice.test.ts
PASS  src/services/authService.test.ts

Test Suites: 5 passed, 5 total
Tests:       28 passed, 28 total
Time:        5.234s
```

**Unit Tests (Backend):**
```bash
npm run test:unit

# Results:
PASS  src/controllers/authController.test.ts
PASS  src/controllers/dashboardController.test.ts
PASS  src/services/authService.test.ts
PASS  src/middleware/authMiddleware.test.ts

Test Suites: 4 passed, 4 total
Tests:       22 passed, 22 total
Time:        3.891s
```

**Integration Tests:**
```bash
npm run test:integration

# Results:
PASS  tests/integration/auth.test.ts
PASS  tests/integration/dashboard.test.ts

Test Suites: 2 passed, 2 total
Tests:       15 passed, 15 total
Time:        8.123s
```

**E2E Tests:**
```bash
npm run test:e2e

# Results:
✓ User can login successfully
✓ User can view dashboard
✓ User can create new widget
✓ User can edit widget
✓ User can delete widget
✓ User can logout

Test Suites: 1 passed, 1 total
Tests:       6 passed, 6 total
Time:        24.567s
```

**Coverage Report:**
```
-------------------|---------|----------|---------|---------|
File               | % Stmts | % Branch | % Funcs | % Lines |
-------------------|---------|----------|---------|---------|
All files          |   87.34 |    82.15 |   89.12 |   87.89 |
 components/Auth   |   91.23 |    85.71 |   92.31 |   91.67 |
 components/Dash   |   85.67 |    78.95 |   88.24 |   86.11 |
 services          |   89.45 |    84.62 |   90.00 |   89.74 |
 store             |   88.92 |    80.43 |   87.50 |   89.23 |
-------------------|---------|----------|---------|---------|
```

**Validation:**
```bash
python3 scripts/step_validator.py task_20241111_dashboard testing
```

**Validation Result:**
```
============================================================
Validation Result: PASSED
============================================================

Checks Run: 4
  ✅ PASS - test_execution: All tests executed successfully
  ✅ PASS - min_coverage: Coverage 87.34% exceeds minimum 70%
  ✅ PASS - all_tests_pass: All 71 tests passed
  ✅ PASS - format: Markdown structure and frontmatter validation

Recommendation: PROCEED
============================================================
```

---

### Step 5: Documentation

**Input**: All previous artifacts

**Process:**
1. Load `assets/templates/validation.md.tmpl`
2. Compile comprehensive documentation
3. Include installation, usage, API reference
4. Add troubleshooting guide
5. Document deployment process

**Output**: `.sequential_cache/task_20241111_dashboard/documentation.md`

**Documentation Includes:**

1. **Installation Guide**
   - Prerequisites
   - Step-by-step setup
   - Environment configuration

2. **Usage Guide**
   - Running in development
   - Building for production
   - Common use cases

3. **API Reference**
   - All endpoints documented
   - Request/response examples
   - Error codes

4. **Testing Documentation**
   - How to run tests
   - Coverage reports
   - Test scenarios

5. **Deployment Guide**
   - Production build
   - Environment setup
   - CI/CD pipeline

6. **Troubleshooting**
   - Common issues and solutions
   - Debug mode instructions
   - FAQ

**Validation:**
```bash
python3 scripts/step_validator.py task_20241111_dashboard documentation
```

**Validation Result:**
```
============================================================
Validation Result: PASSED
============================================================

Checks Run: 3
  ✅ PASS - completeness: Required sections: 5, Found: 5
  ✅ PASS - format: Markdown structure and frontmatter validation
  ✅ PASS - references_all_artifacts: All previous artifacts referenced

Recommendation: PROCEED
============================================================
```

---

## Final Output

**Task Status**: ✅ COMPLETED

**Output Artifacts:**
```
.sequential_cache/task_20241111_dashboard/
├── requirements.md          # Step 1 output
├── architecture.md          # Step 2 output
├── implementation/          # Step 3 output
│   ├── frontend/           # React app
│   └── backend/            # Express API
├── test_results.md         # Step 4 output
├── documentation.md        # Step 5 output
└── validation_log.json     # All validation results
```

**Validation Log Summary:**
```json
{
  "task_id": "task_20241111_dashboard",
  "total_steps": 5,
  "completed_steps": 5,
  "validation_passes": 5,
  "validation_failures": 0,
  "validation_retries": 0,
  "total_duration_minutes": 42,
  "status": "completed"
}
```

**Metrics:**
- Total steps: 5
- Validation passes: 5/5
- Retries needed: 0
- Test coverage: 87.34%
- Total time: 42 minutes

**Next Step Recommendation**:
Send to **evaluator** skill for final quality assessment before deployment.

---

## Lessons Learned

### What Worked Well:
1. **Sequential validation gates** caught issues early
2. **Template-driven approach** ensured consistency
3. **Artifact preservation** maintained full context
4. **Automated validation** reduced manual review time

### Challenges Encountered:
1. **Initial requirements** needed one clarification round
2. **Test coverage** initially at 75%, required additional test cases
3. **Documentation** needed minor format corrections

### Improvements for Next Time:
1. Include more specific acceptance criteria in Step 1
2. Add performance benchmarks in Step 4
3. Consider security audit as additional validation step

---

## Integration Example

**Sending to Evaluator Skill:**
```json
{
  "task_id": "task_20241111_dashboard",
  "status": "completed",
  "artifacts": {
    "requirements": ".sequential_cache/task_20241111_dashboard/requirements.md",
    "architecture": ".sequential_cache/task_20241111_dashboard/architecture.md",
    "code": ".sequential_cache/task_20241111_dashboard/implementation/",
    "tests": ".sequential_cache/task_20241111_dashboard/test_results.md",
    "docs": ".sequential_cache/task_20241111_dashboard/documentation.md"
  },
  "validation_log": ".sequential_cache/task_20241111_dashboard/validation_log.json",
  "next_skill_recommendation": "evaluator",
  "metrics": {
    "total_steps": 5,
    "validation_passes": 5,
    "validation_retries": 0,
    "test_coverage": 87.34,
    "total_duration_minutes": 42
  }
}
```

This example demonstrates the complete end-to-end workflow of building a React dashboard application using the Sequential Task Processor skill with validation gates at each step.
