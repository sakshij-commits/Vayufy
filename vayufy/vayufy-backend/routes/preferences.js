import express from "express";
import UserPreference from "../models/UserPreference.js";

const router = express.Router();

// 🔹 GET preferences
router.get("/user/:uid", async (req, res) => {
  const pref = await UserPreference.findOne({ userId: req.params.uid });
  res.json(pref);
});

// 🔹 SET / UPDATE preferences
router.post("/health", async (req, res) => {
  const { userId, ...data } = req.body;

  const prefs = await Preferences.findOneAndUpdate(
    { userId },
    data,
    { upsert: true, new: true }
  );

  res.json(prefs);
});


export default router;
