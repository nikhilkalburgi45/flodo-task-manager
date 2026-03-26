require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const helmet = require("helmet");

const taskRoutes = require("./routes/tasks");
const { apiLimiter } = require("./middleware/rateLimiter");
const errorHandler = require("./middleware/errorHandler");

const app = express();

app.use(helmet());

app.use(cors());
app.use(express.json({ limit: "10kb" }));

// ── Global Rate Limiter
// Applied to ALL /api/* routes: max 100 requests per 15 minutes per IP.
// A tighter writeLimiter (30 req/15min) is additionally applied on POST/PUT.
app.use("/api", apiLimiter);

// ── Routes
app.use("/api/tasks", taskRoutes);

// Health check endpoint
app.get("/", (req, res) => {
  res.json({
    message: "Task Manager API is running",
    version: "1.0.0",
    environment: process.env.NODE_ENV || "development",
  });
});

// ── 404 Handler
app.use((req, res) => {
  res
    .status(404)
    .json({ success: false, message: `Route ${req.originalUrl} not found` });
});

// ── Global Error Handler
app.use(errorHandler);

// ── MongoDB Connection + Server Start
const PORT = process.env.PORT || 5000;
const MONGO_URI =
  process.env.MONGO_URI || "mongodb://localhost:27017/taskmanager";

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log("MongoDB connected");
    console.log("Indexes will be created automatically by Mongoose");
    app.listen(PORT, () => {
      console.log(`Server running on http://localhost:${PORT}`);
      console.log(`Helmet security headers active`);
      console.log(
        `Rate limiting active (100 req/15min global, 30 req/15min writes)`,
      );
    });
  })
  .catch((err) => {
    console.error("MongoDB connection failed:", err.message);
    process.exit(1);
  });
