import express from "express";
import Preference from "../models/Preference.js";

const router = express.Router();

// ✅ SET / UPDATE PREFS
router.post("/set", async (req, res) => {
  try {
    console.log("📥 PREF SET BODY:", req.body);

    const { userId, ...prefs } = req.body;

    if (!userId) {
      return res.status(400).json({ error: "userId missing" });
    }

    const updated = await Preference.findOneAndUpdate(
      { userId },
      { $set: prefs },
      { upsert: true, new: true }
    );

    console.log("✅ PREF SAVED:", updated);
    res.json(updated);

  } catch (e) {
    console.error("❌ PREF SAVE ERROR:", e);
    res.status(500).json({ error: "Failed to save preferences" });
  }
});

// ✅ GET PREFS
router.get("/user/:uid", async (req, res) => {
  try {
    const pref = await Preference.findOne({ userId: req.params.uid });
    if (!pref) return res.status(404).json(null);
    res.json(pref);
  } catch (e) {
    res.status(500).json({ error: "Failed to fetch prefs" });
  }
});

export default router;
