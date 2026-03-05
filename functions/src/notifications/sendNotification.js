const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

async function sendNotification(userId, title, body, type, data = {}) {
  const db = admin.firestore();
  const userDoc = await db.collection("users").doc(userId).get();

  if (!userDoc.exists) return;
  const user = userDoc.data();
  const tokens = user.fcmTokens || [];

  // Save in-app notification
  await db.collection("notifications").add({
    recipientId: userId,
    recipientRole: user.role,
    title,
    body,
    type,
    data,
    channels: ["push", "in_app"],
    isRead: false,
    isSent: tokens.length > 0,
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    ),
  });

  if (tokens.length === 0) return;

  const message = {
    notification: { title, body },
    data: {
      type,
      ...Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    const invalidTokens = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const code = resp.error?.code;
        if (code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token") {
          invalidTokens.push(tokens[idx]);
        }
      }
    });
    if (invalidTokens.length > 0) {
      const valid = tokens.filter(t => !invalidTokens.includes(t));
      await db.collection("users").doc(userId).update({ fcmTokens: valid });
    }
  } catch (err) {
    console.error("FCM error:", err);
  }
}

module.exports = { sendNotification };