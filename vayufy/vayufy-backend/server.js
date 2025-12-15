import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import dotenv from "dotenv";

import searchRoutes from "./routes/searchHistory.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// REGISTER ROUTES HERE
app.use("/api/search", searchRoutes);

// MongoDB
mongoose.connect(process.env.MONGO_URL)
  .then(() => console.log("MongoDB Connected"))
  .catch(err => console.log("DB ERROR:", err));

app.get("/", (req, res) => res.send("Vayufy backend running"));

app.listen(5000, () => console.log("Server running on port 5000"));
