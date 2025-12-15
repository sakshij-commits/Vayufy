import express from "express";
import AQILog from "../models/AQILog.js";
import admin from "../firebase.js";
import UserDevice from "../models/UserDevice.js";

const router = express.Router();

// ADD AQI LOG
router.post("/add", async (req, res) => {
  try {
    const log = await AQILog.create(req.body);

    // 🚨 AQI ALERT LOGIC
    if (log.aqi >= 150) {
      const devices = await UserDevice.find({ userId: log.userId });

      for (const d of devices) {
        await admin.messaging().send({
          token: d.fcmToken,
          notification: {
            title: "⚠️ Poor Air Quality Alert",
            body: `AQI in ${log.city} is ${log.aqi}. Limit outdoor activity.`,
          },
          android: {
            priority: "high",
          },
        });
      }

      console.log("🔔 AQI ALERT SENT");
    }

    res.json(log);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "AQI save failed" });
  }
});

// GET USER LOGS
router.get("/user/:uid", async (req, res) => {
  const logs = await AQILog
    .find({ userId: req.params.uid })
    .sort({ timestamp: -1 });

  res.json(logs);
});

export default router;
