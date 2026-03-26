const express = require("express");
const router = express.Router();

const simulateDelay = require("../middleware/simulateDelay");
const { writeLimiter } = require("../middleware/rateLimiter");
const { validateCreateTask, validateUpdateTask } = require("../middleware/validate");
const {
  getAllTasks,
  getTaskById,
  createTask,
  updateTask,
  deleteTask,
} = require("../controllers/taskController");

// GET  /api/tasks    → fetch all tasks (supports ?search= and ?status=)
// POST /api/tasks    → create task (rate limited + validated + 2s delay)
router
  .route("/")
  .get(getAllTasks)
  .post(writeLimiter, validateCreateTask, simulateDelay, createTask);

// GET    /api/tasks/:id  → fetch one task
// PUT    /api/tasks/:id  → update task (rate limited + validated + 2s delay)
// DELETE /api/tasks/:id  → delete task
router
  .route("/:id")
  .get(getTaskById)
  .put(writeLimiter, validateUpdateTask, simulateDelay, updateTask)
  .delete(deleteTask);

module.exports = router;
