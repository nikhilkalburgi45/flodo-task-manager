# Task Manager Backend

REST API built with **Node.js + Express + MongoDB (Mongoose)** for the Flodo AI take-home assignment.

**Track:** A — Full-Stack Builder  
**Backend:** Node.js (Express) — approved in place of Python  
**Database:** MongoDB with Mongoose ODM

---

## Project Structure

```
src/
├── app.js                        # Entry point — Express setup, DB connection
├── models/
│   └── Task.js                   # Mongoose schema + DB indexes
├── routes/
│   └── tasks.js                  # Route definitions + middleware chain per route
├── controllers/
│   └── taskController.js         # All CRUD business logic
└── middleware/
    ├── simulateDelay.js           # 2-second artificial delay (assignment requirement)
    ├── rateLimiter.js             # express-rate-limit: global + write-specific limits
    ├── validate.js                # express-validator: input validation & sanitization
    └── errorHandler.js            # Centralized error handler (global catch-all)
```

---

## Setup & Running

```bash
# 1. Install dependencies
npm install

# 2. Make sure MongoDB is running locally
# macOS:    brew services start mongodb-community
# Ubuntu:   sudo systemctl start mongod

# 3. Start the server
npm run dev     # development — auto-restarts on file changes (nodemon)
npm start       # production
```

Server runs at: **http://localhost:5000**

---

## API Reference

### Base URL

```
http://localhost:5000/api
```

### Endpoints

| Method | Endpoint                               | Description                    | Rate Limit   |
| ------ | -------------------------------------- | ------------------------------ | ------------ |
| GET    | `/tasks`                               | Get all tasks                  | 100/15min    |
| GET    | `/tasks?search=<text>`                 | Search tasks by title          | 100/15min    |
| GET    | `/tasks?status=<status>`               | Filter tasks by status         | 100/15min    |
| GET    | `/tasks?search=<text>&status=<status>` | Combined search + filter       | 100/15min    |
| GET    | `/tasks/:id`                           | Get a single task by ID        | 100/15min    |
| POST   | `/tasks`                               | Create a new task _(2s delay)_ | **30/15min** |
| PUT    | `/tasks/:id`                           | Update a task _(2s delay)_     | **30/15min** |
| DELETE | `/tasks/:id`                           | Delete a task                  | 100/15min    |

---

### Task Object Schema

```json
{
  "_id": "664f1a...",
  "title": "Design login screen",
  "description": "Create wireframes for auth flow",
  "dueDate": "2025-07-01T00:00:00.000Z",
  "status": "To-Do",
  "blockedBy": null,
  "createdAt": "2025-06-20T10:00:00.000Z",
  "updatedAt": "2025-06-20T10:00:00.000Z"
}
```

When a task is blocked by another, `blockedBy` is populated automatically:

```json
{
  "blockedBy": {
    "_id": "664f1b...",
    "title": "Complete API testing",
    "status": "In Progress"
  }
}
```

**Valid status values:** `"To-Do"` | `"In Progress"` | `"Done"`

---

### Request Examples

#### Create a Task

```json
POST /api/tasks
Content-Type: application/json

{
  "title": "Build Zomato order API",
  "description": "Implement the order placement endpoint",
  "dueDate": "2025-07-15",
  "status": "To-Do"
}
```

#### Create a Blocked Task

```json
POST /api/tasks
Content-Type: application/json

{
  "title": "Deploy to production",
  "description": "Deploy only after testing is complete",
  "dueDate": "2025-07-20",
  "status": "To-Do",
  "blockedBy": "664f1a2b3c4d5e6f7a8b9c0d"
}
```

#### Update Task Status

```json
PUT /api/tasks/664f1a2b3c4d5e6f7a8b9c0d
Content-Type: application/json

{
  "status": "Done"
}
```

#### Search + Filter

```
GET /api/tasks?search=login&status=In Progress
```

---

### Validation Rules

| Field         | Rules                                       |
| ------------- | ------------------------------------------- |
| `title`       | Required, max 200 chars, HTML-escaped       |
| `description` | Optional, max 2000 chars, HTML-escaped      |
| `dueDate`     | Required, must be valid ISO 8601 date       |
| `status`      | Optional, must be one of the 3 valid values |
| `blockedBy`   | Optional, must be a valid MongoDB ObjectId  |

Validation errors return **HTTP 422** with this shape:

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "field": "dueDate", "message": "Due date must be a valid ISO 8601 date" }
  ]
}
```

---
