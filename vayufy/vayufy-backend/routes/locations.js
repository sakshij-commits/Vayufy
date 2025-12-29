import express from "express";
import SavedLocation from "../models/SavedLocation.js";

const router = express.Router();

// SAVE / UPDATE location
router.post("/", async (req, res) => {
  const { userId, city, lat, lon } = req.body;

  if (!userId || !city || lat == null || lon == null) {
    return res.status(400).json({ error: "Missing fields" });
  }

  await SavedLocation.findOneAndUpdate(
    { userId },
    { city, lat, lon, updatedAt: new Date() },
    { upsert: true, new: true }
  );

  console.log("📍 Location saved:", userId, city);
  res.json({ success: true });
});

// GET location
router.get("/:userId", async (req, res) => {
  const location = await SavedLocation.findOne({
    userId: req.params.userId,
  });

  res.json(location);
});

export default router;
