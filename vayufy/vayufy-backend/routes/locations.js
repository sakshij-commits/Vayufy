import express from "express";
import SavedLocation from "../models/SavedLocation.js";

const router = express.Router();

// Add location
router.post("/add", async (req, res) => {
  try {
    const { userId, city, lat, lon } = req.body;
    if (!userId || !city) return res.status(400).json({ error: "Missing" });

    const doc = new SavedLocation({ userId, city, lat, lon });
    await doc.save();
    res.json(doc);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get user's saved locations
router.get("/user/:uid", async (req, res) => {
  try {
    const list = await SavedLocation.find({ userId: req.params.uid }).sort({ addedAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete
router.delete("/:id", async (req, res) => {
  try {
    await SavedLocation.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
