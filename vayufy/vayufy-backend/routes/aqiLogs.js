import express from "express";
import AQILog from "../models/AQILog.js";
import admin from "../firebase.js";
import UserDevice from "../models/UserDevice.js";
import HealthProfile from "../models/HealthProfile.js";
import { buildAQIRecommendation } from "../utils/recommendations.js";

const router = express.Router();

// ADD AQI LOG + SEND PERSONALIZED NOTIFICATION
router.post("/add", async (req, res) => {
  try {
    console.log("📥 AQI LOG REQUEST:", req.body);

    const log = await AQILog.create(req.body);

    // 🧠 Fetch health profile
    const profile = await HealthProfile.findOne({
      userId: log.userId,
    });

    const threshold = profile?.alertThreshold ?? 150;

    if (log.aqi >= threshold) {
      console.log("🚨 AQI crossed threshold");

      const devices = await UserDevice.find({
        userId: log.userId,
      });

      const notification = buildAQIRecommendation({
        aqi: log.aqi,
        profile,
        city: log.city,
      });

      for (const d of devices) {
        await admin.messaging().send({
          token: d.fcmToken,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          android: {
            priority: "high",
          },
        });
      }

      console.log("🔔 Personalized AQI notification sent");
    }

    res.json(log);
  } catch (e) {
    console.error("❌ AQI ERROR:", e);
    res.status(500).json({ error: "AQI save failed" });
  }
});

// GET USER LOGS
router.get("/user/:uid", async (req, res) => {
  const logs = await AQILog.find({
    userId: req.params.uid,
  }).sort({ timestamp: -1 });

  res.json(logs);
});

export default router;
