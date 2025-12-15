import express from "express";
import HealthProfile from "../models/HealthProfile.js";

const router = express.Router();

// CREATE / UPDATE PROFILE
router.post("/set", async (req, res) => {
  console.log("🔥 /api/health/set HIT");
  console.log("📦 BODY:", req.body);

  try {
    const { userId, ...data } = req.body;

    if (!userId) {
      console.log("❌ userId missing");
      return res.status(400).json({ error: "userId missing" });
    }

    const profile = await HealthProfile.findOneAndUpdate(
      { userId },
      {
        userId,
        ...data,
        updatedAt: new Date(),
      },
      { upsert: true, new: true }
    );

    console.log("✅ PROFILE SAVED:", profile);
    res.json(profile);

  } catch (e) {
    console.error("❌ SAVE ERROR:", e);
    res.status(500).json({ error: e.message });
  }
});

// GET PROFILE
router.get("/user/:uid", async (req, res) => {
  console.log("➡️ GET PROFILE", req.params.uid);

  try {
    const profile = await HealthProfile.findOne({
      userId: req.params.uid,
    });

    res.json(profile);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Fetch failed" });
  }
});

export default router;
