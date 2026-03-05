const { https } = require("firebase-functions/v2");
const { getFirestore } = require("firebase-admin/firestore");

module.exports = https.onCall(async (request) => {
  if (!request.auth) {
    throw new https.HttpsError("unauthenticated", "Must be logged in.");
  }

  const { token } = request.data;
  if (!token || typeof token !== "string") {
    throw new https.HttpsError("invalid-argument", "Valid token required.");
  }

  const db = getFirestore();
  const userRef = db.collection("users").doc(request.auth.uid);

  await db.runTransaction(async (tx) => {
    const doc = await tx.get(userRef);
    let tokens = doc.data()?.fcmTokens || [];
    tokens = tokens.filter(t => t !== token); // Remove duplicates
    tokens.push(token);
    if (tokens.length > 10) tokens = tokens.slice(-10); // FIFO cap
    tx.update(userRef, { fcmTokens: tokens });
  });

  return { success: true };
});