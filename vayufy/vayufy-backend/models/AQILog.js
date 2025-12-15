import mongoose from "mongoose";

const AQILogSchema = new mongoose.Schema({
  userId: { type: String, required: true },

  city: String,
  lat: Number,
  lon: Number,

  aqi: Number,
  pm2_5: Number,
  pm10: Number,
  co: Number,
  no2: Number,
  so2: Number,
  o3: Number,

  timestamp: { type: Date, default: Date.now }
});

export default mongoose.model("AQILog", AQILogSchema);
