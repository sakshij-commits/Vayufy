import express from "express";
import SearchHistory from "../models/SearchHistory.js";

const router = express.Router();

router.post("/add", async (req, res) => {
  console.log("🔥 /api/search/add HIT");
  console.log("BODY:", req.body);

  try {
    const { userId, query } = req.body;

    if (!userId || !query) {
      return res.status(400).json({ error: "Missing fields" });
    }

    const search = new SearchHistory({ userId, query });
    await search.save();

    console.log("✅ Search saved");

    res.status(200).json(search);
  } catch (err) {
    console.error("❌ Search save error:", err);
    res.status(500).json({ error: "Server error" });
  }
});

router.get("/user/:uid", async (req, res) => {
  console.log("📥 Fetch history for:", req.params.uid);

  const searches = await SearchHistory
    .find({ userId: req.params.uid })
    .sort({ timestamp: -1 });

  res.json(searches);
});

export default router;
