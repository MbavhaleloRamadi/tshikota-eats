const {firestore} = require("firebase-functions/v2");
const admin = require("firebase-admin");
const {sendNotification} = require("../notifications/sendNotification");

module.exports = firestore.onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status === after.status) return;

  const orderId = event.params.orderId;
  const db = admin.firestore();

  switch (after.status) {
    case "accepted":
      await sendNotification(
        after.buyerId,
        "Order Accepted",
        after.businessName + " has accepted your order!",
        "order_accepted",
        {orderId, businessId: after.businessId},
      );
      break;

    case "rejected":
      await sendNotification(
        after.buyerId,
        "Order Declined",
        after.businessName + " was unable to fulfill your order.",
        "order_rejected",
        {orderId},
      );
      break;

    case "preparing":
      await sendNotification(
        after.buyerId,
        "Being Prepared",
        after.businessName + " is preparing your order!",
        "order_preparing",
        {orderId},
      );
      break;

    case "ready": {
      const msg = after.fulfillmentType === "pickup"
        ? "Your order from " + after.businessName + " is ready for pickup!"
        : "Your order from " + after.businessName + " is on its way!";
      await sendNotification(
        after.buyerId,
        "Order Ready!",
        msg,
        "order_ready",
        {orderId},
      );
      break;
    }

    case "completed":
      await sendNotification(
        after.buyerId,
        "Order Complete",
        "Enjoy your order from " + after.businessName + "!",
        "order_completed",
        {orderId},
      );
      break;

    case "cancelled": {
      if (after.cancelledBy === "company") {
        await sendNotification(
          after.buyerId,
          "Order Cancelled",
          after.businessName + " cancelled your order. Reason: " + after.cancelReason,
          "order_cancelled",
          {orderId},
        );
      } else if (after.cancelledBy === "buyer") {
        const bizDoc = await db.collection("businesses").doc(after.businessId).get();
        await sendNotification(
          bizDoc.data().ownerId,
          "Order Cancelled by Customer",
          after.buyerName + " cancelled order " + after.orderNumber + ".",
          "order_cancelled",
          {orderId},
        );
      }
      break;
    }

    default:
      break;
  }
});