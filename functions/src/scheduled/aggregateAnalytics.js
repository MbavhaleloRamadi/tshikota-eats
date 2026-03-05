const {scheduler} = require("firebase-functions/v2");
const admin = require("firebase-admin");

module.exports = scheduler.onSchedule(
  {schedule: "0 * * * *", timeZone: "Africa/Johannesburg"},
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const today = now.toISOString().split("T")[0];
    const startOfDay = new Date(today + "T00:00:00+02:00");

    const ordersSnapshot = await db.collection("orders")
      .where("createdAt", ">=", startOfDay)
      .where("status", "==", "completed")
      .get();

    let totalRevenue = 0;
    let onlinePayments = 0;
    let cashPayments = 0;

    ordersSnapshot.docs.forEach((doc) => {
      const order = doc.data();
      totalRevenue += order.total;
      if (order.paymentMethod === "online") onlinePayments++;
      else cashPayments++;
    });

    const platformFees = ordersSnapshot.size * 500;

    await db.collection("analytics").doc("daily").collection("days").doc(today).set({
      date: admin.firestore.Timestamp.fromDate(startOfDay),
      newOrders: ordersSnapshot.size,
      revenue: totalRevenue,
      platformFees: platformFees,
      onlinePayments,
      cashPayments,
      averageOrderValue: ordersSnapshot.size > 0 ? Math.round(totalRevenue / ordersSnapshot.size) : 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    console.log("Analytics aggregated for " + today);
  },
);