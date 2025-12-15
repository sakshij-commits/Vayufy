import mongoose from "mongoose";

const SearchHistorySchema = new mongoose.Schema({
  userId: { type: String, required: true },
  query: { type: String, required: true },
  timestamp: { type: Date, default: Date.now }
});

export default mongoose.model("SearchHistory", SearchHistorySchema);
