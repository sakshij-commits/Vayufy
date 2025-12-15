import express from "express";
import User from "../models/User.js";

const router = express.Router();

// Create or update user (upsert)
router.post("/upsert", async (req, res) => {
  try {
    const { uid, email, name } = req.body;
    if (!uid) return res.status(400).json({ error: "uid required" });

    const updated = await User.findByIdAndUpdate(uid, {
      _id: uid, email, name, joinedAt: Date.now()
    }, { upsert: true, new: true });

    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/:uid", async (req, res) => {
  try {
    const user = await User.findById(req.params.uid);
    if (!user) return res.status(404).json({ error: "not found" });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
