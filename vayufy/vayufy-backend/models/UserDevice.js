import mongoose from "mongoose";

const UserDeviceSchema = new mongoose.Schema({
  userId: String,
  fcmToken: String,
  platform: String,
  updatedAt: { type: Date, default: Date.now }
});

export default mongoose.model("UserDevice", UserDeviceSchema);
