import mongoose from "mongoose";

const UserSchema = new mongoose.Schema({
  _id: { type: String, required: true }, // Firebase UID
  email: { type: String },
  name: { type: String },
  joinedAt: { type: Date, default: Date.now }
});

export default mongoose.model("User", UserSchema);
