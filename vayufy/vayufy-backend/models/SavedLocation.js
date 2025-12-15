import mongoose from "mongoose";

const SavedLocationSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  city: { type: String, required: true },
  lat: { type: Number, required: true },
  lon: { type: Number, required: true },
  addedAt: { type: Date, default: Date.now }
});

export default mongoose.model("SavedLocation", SavedLocationSchema);
