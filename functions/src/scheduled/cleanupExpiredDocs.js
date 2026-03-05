const {scheduler} = require("firebase-functions/v2");
const admin = require("firebase-admin");

module.exports = scheduler.onSchedule(
  {schedule: "0 2 * * *", timeZone: "Africa/Johannesburg"},
  async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const expiredNotifs = await db.collection("notifications")
      .where("expiresAt", "<=", now)
      .limit(500)
      .get();

    const batch1 = db.batch();
    expiredNotifs.docs.forEach((doc) => batch1.delete(doc.ref));
    if (expiredNotifs.size > 0) await batch1.commit();

    const expiredLogs = await db.collection("logs")
      .where("expiresAt", "<=", now)
      .limit(500)
      .get();

    const batch2 = db.batch();
    expiredLogs.docs.forEach((doc) => batch2.delete(doc.ref));
    if (expiredLogs.size > 0) await batch2.commit();

    console.log("Cleaned " + expiredNotifs.size + " notifications and " + expiredLogs.size + " logs");
  },
);