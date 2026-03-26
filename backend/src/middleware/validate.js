const { body, validationResult } = require("express-validator");

// ─── Reusable validation error handler
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({
      success: false,
      message: "Validation failed",
      errors: errors.array().map((e) => ({
        field: e.path,
        message: e.msg,
      })),
    });
  }
  next();
};

// ─── Task creation validation rules
const validateCreateTask = [
  body("title")
    .trim()
    .notEmpty()
    .withMessage("Title is required")
    .isLength({ max: 200 })
    .withMessage("Title must be under 200 characters")
    .escape(),

  body("description")
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage("Description must be under 2000 characters")
    .escape(),

  body("dueDate")
    .notEmpty()
    .withMessage("Due date is required")
    .isISO8601()
    .withMessage("Due date must be a valid ISO 8601 date (e.g. 2025-07-15)")
    .toDate(),

  body("status")
    .optional()
    .isIn(["To-Do", "In Progress", "Done"])
    .withMessage("Status must be one of: To-Do, In Progress, Done"),

  body("blockedBy")
    .optional({ nullable: true })
    .isMongoId()
    .withMessage("blockedBy must be a valid task ID"),

  handleValidationErrors,
];

// ─── Task update validation rules
const validateUpdateTask = [
  body("title")
    .optional()
    .trim()
    .notEmpty()
    .withMessage("Title cannot be empty if provided")
    .isLength({ max: 200 })
    .withMessage("Title must be under 200 characters")
    .escape(),

  body("description")
    .optional()
    .trim()
    .isLength({ max: 2000 })
    .withMessage("Description must be under 2000 characters")
    .escape(),

  body("dueDate")
    .optional()
    .isISO8601()
    .withMessage("Due date must be a valid ISO 8601 date")
    .toDate(),

  body("status")
    .optional()
    .isIn(["To-Do", "In Progress", "Done"])
    .withMessage("Status must be one of: To-Do, In Progress, Done"),

  body("blockedBy")
    .optional({ nullable: true })
    .isMongoId()
    .withMessage("blockedBy must be a valid task ID"),

  body().custom((_, { req }) => {
    const allowed = ["title", "description", "dueDate", "status", "blockedBy"];
    const hasAtLeastOne = allowed.some(
      (field) => req.body[field] !== undefined,
    );
    if (!hasAtLeastOne) {
      throw new Error("Request body must contain at least one field to update");
    }
    return true;
  }),

  handleValidationErrors,
];

module.exports = { validateCreateTask, validateUpdateTask };
