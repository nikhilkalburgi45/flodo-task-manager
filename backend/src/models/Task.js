const mongoose = require("mongoose");

const VALID_STATUSES = ["To-Do", "In Progress", "Done"];

const taskSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, "Title is required"],
      trim: true,
    },
    description: {
      type: String,
      trim: true,
      default: "",
    },
    dueDate: {
      type: Date,
      required: [true, "Due date is required"],
    },
    status: {
      type: String,
      enum: {
        values: VALID_STATUSES,
        message: "Status must be one of: To-Do, In Progress, Done",
      },
      default: "To-Do",
    },
    blockedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Task",
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

// ─── DB Indexes
taskSchema.index({ status: 1 });

taskSchema.index({ createdAt: -1 });

taskSchema.index({ title: "text" }, { weights: { title: 10 } });

taskSchema.index({ status: 1, createdAt: -1 });

taskSchema.pre(/^find/, function (next) {
  this.populate({
    path: "blockedBy",
    select: "title status",
  });
  next();
});

module.exports = mongoose.model("Task", taskSchema);
