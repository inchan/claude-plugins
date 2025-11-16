# Full-Stack Application - Parallel Execution Example

This example demonstrates using the parallel-task-executor skill in **sectioning mode** to build a full-stack application with independent components developed in parallel.

## Scenario

**User Request:** "Build a full-stack todo application with React frontend, Express backend, and PostgreSQL database"

**Analysis:** This task can be decomposed into three independent sections:
1. Frontend (React components and state management)
2. Backend (Express API routes and business logic)
3. Database (PostgreSQL schema and migrations)

## Execution Plan

### Task Decomposition

```json
{
  "task_id": "fullstack-todo-001",
  "mode": "sectioning",
  "main_task": {
    "description": "Build full-stack todo application",
    "components": [
      "React frontend with todo list UI",
      "Express backend API with CRUD operations",
      "PostgreSQL database schema and migrations"
    ]
  },
  "parallelism_hint": 3,
  "timeout_seconds": 600
}
```

### Dependency Analysis

```
Frontend
├── Dependencies: None (can start immediately)
└── Outputs: React components, API client

Backend
├── Dependencies: None (can start immediately)
└── Outputs: Express routes, controllers, services

Database
├── Dependencies: None (can start immediately)
└── Outputs: Schema, migrations, seed data

Integration Layer
├── Dependencies: Frontend, Backend, Database
└── Outputs: API endpoint configuration, Docker Compose
```

### Execution Waves

**Wave 1: Parallel Development (3 workers)**

Worker 1: Frontend Development
```javascript
// TodoList.tsx
import React, { useState, useEffect } from 'react';
import { TodoItem } from './TodoItem';
import { api } from './api/client';

export function TodoList() {
  const [todos, setTodos] = useState([]);

  useEffect(() => {
    api.getTodos().then(setTodos);
  }, []);

  const addTodo = (text) => {
    api.createTodo({ text, completed: false })
      .then(newTodo => setTodos([...todos, newTodo]));
  };

  return (
    <div className="todo-list">
      <h1>Todo List</h1>
      {todos.map(todo => (
        <TodoItem key={todo.id} todo={todo} />
      ))}
      <AddTodoForm onAdd={addTodo} />
    </div>
  );
}
```

Worker 2: Backend Development
```javascript
// routes/todos.js
const express = require('express');
const router = express.Router();
const todosController = require('../controllers/todos');

router.get('/todos', todosController.getAll);
router.post('/todos', todosController.create);
router.put('/todos/:id', todosController.update);
router.delete('/todos/:id', todosController.delete);

module.exports = router;

// controllers/todos.js
const todosService = require('../services/todos');

exports.getAll = async (req, res) => {
  const todos = await todosService.getAll();
  res.json(todos);
};

exports.create = async (req, res) => {
  const todo = await todosService.create(req.body);
  res.status(201).json(todo);
};
```

Worker 3: Database Development
```sql
-- migrations/001_create_todos.sql
CREATE TABLE todos (
  id SERIAL PRIMARY KEY,
  text VARCHAR(255) NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_todos_completed ON todos(completed);

-- seed.sql
INSERT INTO todos (text, completed) VALUES
  ('Buy groceries', false),
  ('Write documentation', false),
  ('Deploy to production', false);
```

**Sync Point: Wait for all workers to complete**

**Wave 2: Integration (1 worker)**

```javascript
// Integration: API endpoint configuration
// frontend/.env
REACT_APP_API_URL=http://localhost:3001/api

// backend/config/database.js
module.exports = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: 'todos',
  user: 'postgres',
  password: process.env.DB_PASSWORD
};

// docker-compose.yml
version: '3.8'
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - backend

  backend:
    build: ./backend
    ports:
      - "3001:3001"
    depends_on:
      - database

  database:
    image: postgres:14
    environment:
      POSTGRES_DB: todos
      POSTGRES_PASSWORD: password
    volumes:
      - ./database/migrations:/docker-entrypoint-initdb.d
```

## Execution Results

### Performance Metrics

```json
{
  "execution_summary": {
    "total_subtasks": 3,
    "parallel_executions": 3,
    "execution_time": "15.2 min",
    "sequential_estimate": "45 min",
    "speedup_factor": 2.96,
    "workers_used": 3,
    "sync_points": 2
  },
  "results": {
    "completed_sections": [
      {
        "name": "frontend",
        "status": "success",
        "output": "./frontend",
        "execution_time": "12.5 min",
        "files_created": 8
      },
      {
        "name": "backend",
        "status": "success",
        "output": "./backend",
        "execution_time": "14.3 min",
        "files_created": 12
      },
      {
        "name": "database",
        "status": "success",
        "output": "./database",
        "execution_time": "8.7 min",
        "files_created": 4
      }
    ],
    "merged_output": "./fullstack-todo-app",
    "conflicts_resolved": 2,
    "manual_review_required": []
  }
}
```

### Conflicts Resolved

1. **Import Conflict**: Both frontend and backend defined `Todo` type
   - Resolution: Created shared `types/` directory with common definitions

2. **Port Conflict**: Frontend and backend initially both used port 3000
   - Resolution: Backend moved to port 3001

## Integration Tests

```javascript
// tests/integration/todo-flow.test.js
describe('Todo Application Flow', () => {
  it('should create, read, update, and delete todos', async () => {
    // Create
    const created = await api.createTodo({ text: 'Test todo', completed: false });
    expect(created.id).toBeDefined();

    // Read
    const todos = await api.getTodos();
    expect(todos).toContainEqual(created);

    // Update
    const updated = await api.updateTodo(created.id, { completed: true });
    expect(updated.completed).toBe(true);

    // Delete
    await api.deleteTodo(created.id);
    const afterDelete = await api.getTodos();
    expect(afterDelete).not.toContainEqual(created);
  });
});
```

## Key Takeaways

1. **3x Speedup**: Parallel execution reduced development time from 45 minutes to 15 minutes
2. **Clean Separation**: Independent development allowed each component to be built without blocking
3. **Minimal Conflicts**: Only 2 minor conflicts that were automatically resolved
4. **Easy Integration**: Clear interfaces between components made integration straightforward

## Running the Application

```bash
# Install dependencies
cd frontend && npm install
cd ../backend && npm install

# Start with Docker Compose
docker-compose up

# Or start individually
# Terminal 1: Database
docker run -p 5432:5432 -e POSTGRES_DB=todos -e POSTGRES_PASSWORD=password postgres:14

# Terminal 2: Backend
cd backend && npm start

# Terminal 3: Frontend
cd frontend && npm start
```

The application will be available at http://localhost:3000

## Conclusion

This example demonstrates the effectiveness of parallel task execution for full-stack development. By decomposing the work into independent sections and executing them in parallel, we achieved significant time savings while maintaining code quality and reducing integration issues.
