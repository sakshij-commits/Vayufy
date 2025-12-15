import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import dotenv from "dotenv";

import searchRoutes from "./routes/searchHistory.js";
import aqiLogRoutes from "./routes/aqiLogs.js";
import preferenceRoutes from "./routes/preferences.js";
import deviceRoutes from "./routes/devices.js";
import "./firebase.js";
import healthProfileRoutes from "./routes/healthProfile.js";


dotenv.config();

const app = express();

// MIDDLEWARE
app.use(cors());
app.use(express.json());

// 🔥 LOG EVERY REQUEST
app.use((req, res, next) => {
  console.log(`➡️ ${req.method} ${req.url}`);
  next();
});

// ROUTES
app.use("/api/search", searchRoutes);
app.use("/api/aqi", aqiLogRoutes);
app.use("/api/prefs", preferenceRoutes);
app.use("/api/devices", deviceRoutes);
app.use("/api/health", healthProfileRoutes);

// ROOT TEST
app.get("/", (req, res) => {
  res.send("Vayufy backend running 🚀");
});

// DB
mongoose
  .connect(process.env.MONGO_URL)
  .then(() => console.log("MongoDB Connected ✔️"))
  .catch((err) => console.error("DB ERROR:", err));

app.listen(5000, () =>
  console.log("Server running at http://localhost:5000")
);
