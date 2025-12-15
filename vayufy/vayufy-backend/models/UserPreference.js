import mongoose from "mongoose";

const UserPreferenceSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  preferredCity: { type: String },
  aqiAlertLevel: { type: Number, default: 150 },
  notificationsEnabled: { type: Boolean, default: true },
  updatedAt: { type: Date, default: Date.now }
});

export default mongoose.model("UserPreference", UserPreferenceSchema);
