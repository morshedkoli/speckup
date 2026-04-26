// Optional Cloud Functions. Not required for MVP.
// Use for: daily passage seeding, moderation of reported word meanings.
import { onRequest } from "firebase-functions/v2/https";

export const health = onRequest((_req, res) => {
  res.status(200).send("ok");
});
