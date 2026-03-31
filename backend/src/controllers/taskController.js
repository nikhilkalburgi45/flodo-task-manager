const Task = require("../models/Task");

// ─── GET /api/tasks

const getAllTasks = async (req, res, next) => {
  try {
    const { search, status } = req.query;
    const filter = {};

    // ✅ CORRECT — just use regex
    if (search) {
      filter.title = { $regex: search, $options: "i" };
    }

    if (status) {
      filter.status = status;
    }

    const tasks = await Task.find(filter).sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: tasks.length,
      data: tasks,
    });
  } catch (error) {
    next(error);
  }
};

// ─── GET /api/tasks/:id
const getTaskById = async (req, res, next) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) {
      return res
        .status(404)
        .json({ success: false, message: "Task not found" });
    }
    res.status(200).json({ success: true, data: task });
  } catch (error) {
    next(error);
  }
};

// ─── POST /api/tasks
const createTask = async (req, res, next) => {
  try {
    const { title, description, dueDate, status, blockedBy } = req.body;

    if (blockedBy) {
      const blocker = await Task.findById(blockedBy);
      if (!blocker) {
        return res.status(400).json({
          success: false,
          message: "The task specified in 'blockedBy' does not exist",
        });
      }
    }

    const task = await Task.create({
      title,
      description,
      dueDate,
      status,
      blockedBy,
    });
    res.status(201).json({ success: true, data: task });
  } catch (error) {
    next(error);
  }
};

// ─── PUT /api/tasks/:id
const updateTask = async (req, res, next) => {
  try {
    const { title, description, dueDate, status, blockedBy } = req.body;

    if (blockedBy && blockedBy === req.params.id) {
      return res.status(400).json({
        success: false,
        message: "A task cannot block itself",
      });
    }

    if (blockedBy) {
      const blocker = await Task.findById(blockedBy);
      if (!blocker) {
        return res.status(400).json({
          success: false,
          message: "The task specified in 'blockedBy' does not exist",
        });
      }
    }

    const task = await Task.findByIdAndUpdate(
      req.params.id,
      { title, description, dueDate, status, blockedBy: blockedBy ?? null },
      { new: true, runValidators: true },
    );

    if (!task) {
      return res
        .status(404)
        .json({ success: false, message: "Task not found" });
    }

    res.status(200).json({ success: true, data: task });
  } catch (error) {
    next(error);
  }
};

// ─── DELETE /api/tasks/:id
const deleteTask = async (req, res, next) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) {
      return res
        .status(404)
        .json({ success: false, message: "Task not found" });
    }

    await Task.updateMany(
      { blockedBy: req.params.id },
      { $set: { blockedBy: null } },
    );
    await task.deleteOne();

    res
      .status(200)
      .json({ success: true, message: "Task deleted successfully" });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAllTasks,
  getTaskById,
  createTask,
  updateTask,
  deleteTask,
};
