import express from "express";
import UserDevice from "../models/UserDevice.js";

const router = express.Router();

router.post("/register", async (req, res) => {
  const { userId, token } = req.body;

  if (!userId || !token) {
    return res.status(400).json({ error: "Missing fields" });
  }

  await UserDevice.findOneAndUpdate(
    { userId },
    { fcmToken: token, platform: "android" },
    { upsert: true, new: true }
  );

  console.log("📲 Device registered:", userId);
  res.json({ success: true });
});

export default router;
