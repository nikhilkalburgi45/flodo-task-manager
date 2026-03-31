# Flodo Task Manager

A full-stack Task Management application built for the **Flodo AI Take-Home Assignment**.

- **Track:** A — Full-Stack Builder
- **Backend:** Node.js + Express + MongoDB
- **Frontend:** Flutter (Dart)

---

## Repository Structure

```
flodo-task-manager/
├── backend/               # Node.js REST API
│   ├── src/
│   │   ├── app.js         # Entry point
│   │   ├── models/        # Mongoose schema + DB indexes
│   │   ├── routes/        # Route definitions
│   │   ├── controllers/   # CRUD business logic
│   │   └── middleware/    # Rate limiting, validation, error handler
│   ├── .env.example
│   ├── package.json
│   └── README.md
│
└── frontend/              # Flutter App
    ├── lib/
    │   ├── main.dart       # App entry point
    │   ├── models/         # Task data model
    │   ├── services/       # HTTP calls to backend
    │   ├── providers/      # State management
    │   ├── screens/        # UI screens
    │   └── widgets/        # Reusable UI components
    ├── pubspec.yaml
    └── README.md
```

---

## Features

### Core (Assignment Requirements)

| Feature                                                 | Status |
| ------------------------------------------------------- | ------ |
| Create, Read, Update, Delete tasks                      | ✅     |
| Task fields: Title, Description, Due Date, Status       | ✅     |
| Blocked By — task dependency (one task blocks another)  | ✅     |
| Blocked task UI — greyed out card with 🔒 Blocked badge | ✅     |
| Search tasks by title                                   | ✅     |
| Filter tasks by status                                  | ✅     |
| Draft persistence — typed text survives swipe-back      | ✅     |
| 2-second simulated delay on Create/Update               | ✅     |
| Loading state during delay + double-tap prevention      | ✅     |

### Production Engineering (Beyond Requirements)

| Feature                    | Implementation                                         |
| -------------------------- | ------------------------------------------------------ |
| DB Indexing                | 4 indexes including compound index for covered queries |
| Rate Limiting              | Two-tier: 100 req/15min global, 30 req/15min on writes |
| Input Validation           | `express-validator` — validates + sanitizes all fields |
| Security Headers           | `helmet.js` — 15 HTTP security headers                 |
| Centralized Error Handling | Global Express error middleware                        |
| Request Size Limit         | 10KB cap to prevent memory attacks                     |
| Cascade Delete             | Deleting a task auto-unblocks dependent tasks          |

---

## Quick Start

### Prerequisites

- Node.js v18+
- MongoDB (local or Atlas)
- Flutter SDK 3.x
- Android Emulator or physical device

---

### 1. Clone the repo

```bash
git clone https://github.com/nikhilkalburgi45/flodo-task-manager.git
cd flodo-task-manager
```

---

### 2. Start the Backend

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env
# Edit .env if using MongoDB Atlas

# Start development server
npm run dev
```

Backend runs at: **http://localhost:5000**

You should see:

```
Indexes will be created automatically by Mongoose
Server running on http://localhost:5000
Helmet security headers active
Rate limiting active (100 req/15min global, 30 req/15min writes)
```

---

### 3. Run the Flutter App

```bash
cd frontend

# Install Flutter packages
flutter pub get

# Check emulator is running
flutter devices

# Run the app
flutter run
```

> **Important:** Make sure the backend is running before launching the app.

---

## API Reference

Base URL: `http://localhost:5000/api`

| Method | Endpoint                 | Description              | Rate Limit   |
| ------ | ------------------------ | ------------------------ | ------------ |
| GET    | `/tasks`                 | Get all tasks            | 100/15min    |
| GET    | `/tasks?search=<text>`   | Search by title          | 100/15min    |
| GET    | `/tasks?status=<status>` | Filter by status         | 100/15min    |
| GET    | `/tasks/:id`             | Get single task          | 100/15min    |
| POST   | `/tasks`                 | Create task _(2s delay)_ | **30/15min** |
| PUT    | `/tasks/:id`             | Update task _(2s delay)_ | **30/15min** |
| DELETE | `/tasks/:id`             | Delete task              | 100/15min    |

### Task Object

```json
{
  "_id": "664f1a...",
  "title": "Build login API",
  "description": "Implement JWT auth endpoint",
  "dueDate": "2025-07-15T00:00:00.000Z",
  "status": "To-Do",
  "blockedBy": {
    "_id": "664f1b...",
    "title": "Design DB schema",
    "status": "In Progress"
  },
  "createdAt": "2025-06-20T10:00:00.000Z",
  "updatedAt": "2025-06-20T10:00:00.000Z"
}
```

**Valid status values:** `"To-Do"` | `"In Progress"` | `"Done"`

---

## Environment Variables

| Variable    | Default                                 | Description                       |
| ----------- | --------------------------------------- | --------------------------------- |
| `PORT`      | `5000`                                  | Server port                       |
| `MONGO_URI` | `mongodb://localhost:27017/taskmanager` | MongoDB URI                       |
| `NODE_ENV`  | `development`                           | Hides error details in production |

---

## API URL Config (Flutter)

Open `frontend/lib/services/api_service.dart`:

```dart
static const String _baseUrl = 'http://10.0.2.2:5000/api';
```

| Setup               | URL                                |
| ------------------- | ---------------------------------- |
| Android Emulator    | `http://10.0.2.2:5000/api`         |
| iOS Simulator       | `http://localhost:5000/api`        |
| Real Android device | `http://YOUR_PC_LOCAL_IP:5000/api` |

---

## Engineering Decisions

### Why Node.js instead of Python?

Python (FastAPI/Flask) was the originally specified backend. Node.js was used instead with prior approval from the Flodo team — this allowed focus on clean architecture, API design, and system robustness rather than ramping up on a new stack within the time constraint.

### Why not Redis?

Redis was deliberately excluded. In a task manager with simple CRUD, there is no meaningful caching problem to solve. Adding Redis would add complexity without solving any real problem — the right engineering decision is to add infrastructure only when it addresses a clear bottleneck.

### DB Indexes

Four indexes on the Task collection:

| Index                          | Type         | Purpose                                        |
| ------------------------------ | ------------ | ---------------------------------------------- |
| `{ status: 1 }`                | Single field | Status filter queries                          |
| `{ createdAt: -1 }`            | Single field | Default sort on list view                      |
| `{ title: "text" }`            | Text index   | Full-text title search                         |
| `{ status: 1, createdAt: -1 }` | Compound     | Covered query — filter + sort from index alone |

### Two-tier Rate Limiting

- **Global (100/15min):** Applied to all routes. Protects reads.
- **Write limiter (30/15min):** Applied to POST and PUT only. Writes are expensive (DB write + 2s delay) and the most likely target for abuse.

### Draft Persistence

Uses `SharedPreferences` to save title and description on every keystroke in the Create screen. When the user swipes back and returns, the draft is automatically restored. Draft is cleared only after a successful save.

---

## Commit History

```
docs: add root README covering full stack setup and architecture
docs: add full API reference, engineering decisions, and AI usage report
feat: add rate limiting, input validation, Helmet security headers, and global error handler
feat: implement full CRUD REST API for tasks with search and status filter
feat: add Task model with status enum, blockedBy reference, and DB indexes
chore: initialize Node.js project with Express, Mongoose, and dev dependencies
```

---

## AI Usage Report

- Used Claude to scaffold the initial backend structure (model, controller, routes)
- Used Claude to generate the Flutter screens and provider pattern
- Reviewed and adjusted all generated code — modified compound index strategy, two-tier rate limiter design, and the `isBlocked` getter logic in the Task model
- Caught one AI mistake: initial code used `$regex` for all searches; updated to prefer MongoDB `$text` index with `$regex` as fallback for better performance
- All architectural decisions (no Redis, two-tier rate limiting, index selection) were made independently based on the specific requirements of this app

---

## Author

**Nikhil Kalburgi**  
B.Tech — Electronics & Computer Engineering, Walchand Institute of Technology  
GitHub: [@nikhilkalburgi45](https://github.com/nikhilkalburgi45)
