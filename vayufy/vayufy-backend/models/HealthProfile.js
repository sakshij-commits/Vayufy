import mongoose from "mongoose";

const HealthProfileSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },

  ageGroup: String,
  skinType: String,
  conditions: [String],
  airSensitivity: String,
  alertThreshold: Number,

  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
});

export default mongoose.model("HealthProfile", HealthProfileSchema);
