import mongoose from "mongoose";

const PreferenceSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },

  preferredCity: String,
  lat: Number,
  lon: Number,

  citySelected: { type: Boolean, default: false },

  profileCompleted: { type: Boolean, default: false },

}, { timestamps: true });

export default mongoose.model("Preference", PreferenceSchema);
