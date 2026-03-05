const { https } = require("firebase-functions/v2");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const PLATFORM_FEE = 500; // R5.00 in cents

module.exports = https.onCall(async (request) => {
  if (!request.auth) {
    throw new https.HttpsError("unauthenticated", "Must be logged in.");
  }

  const {
    businessId, items, fulfillmentType,
    deliveryAddress, paymentMethod, specialInstructions,
  } = request.data;

  // ── VALIDATION ──
  if (!businessId || !items?.length || !fulfillmentType || !paymentMethod) {
    throw new https.HttpsError("invalid-argument", "Missing required fields.");
  }
  if (!["pickup", "vendor_delivery"].includes(fulfillmentType)) {
    throw new https.HttpsError("invalid-argument", "Invalid fulfillment type.");
  }
  if (fulfillmentType === "vendor_delivery" && !deliveryAddress) {
    throw new https.HttpsError("invalid-argument", "Delivery address required for delivery.");
  }
  if (!["online", "cash"].includes(paymentMethod)) {
    throw new https.HttpsError("invalid-argument", "Invalid payment method.");
  }
  if (paymentMethod === "cash" && fulfillmentType !== "pickup") {
    throw new https.HttpsError("invalid-argument", "Cash is only for pickup orders.");
  }
  if (items.length > 50) {
    throw new https.HttpsError("invalid-argument", "Max 50 items per order.");
  }

  const db = getFirestore();

  const order = await db.runTransaction(async (tx) => {
    // Fetch business
    const bizDoc = await tx.get(db.collection("businesses").doc(businessId));
    if (!bizDoc.exists || !bizDoc.data().isActive) {
      throw new https.HttpsError("not-found", "Business not found or inactive.");
    }
    const biz = bizDoc.data();

    if (!biz.isOpen) {
      throw new https.HttpsError("failed-precondition", "Business is currently closed.");
    }
    if (paymentMethod === "online" && !biz.stripeOnboardingComplete) {
      throw new https.HttpsError("failed-precondition", "Vendor cannot accept online payments yet.");
    }

    // Fetch buyer
    const userDoc = await tx.get(db.collection("users").doc(request.auth.uid));
    const user = userDoc.data();

    // Validate items against menu — USE SERVER PRICES
    let subtotal = 0;
    const validatedItems = [];

    for (const item of items) {
      const menuRef = db.collection("menus").doc(businessId)
        .collection("items").doc(item.menuItemId);
      const menuDoc = await tx.get(menuRef);

      if (!menuDoc.exists || !menuDoc.data().isAvailable || !menuDoc.data().isActive) {
        throw new https.HttpsError("failed-precondition", `Item "${item.menuItemId}" is unavailable.`);
      }

      const menuItem = menuDoc.data();
      let itemPrice = menuItem.price; // SERVER PRICE — ignore client price
      let optionsTotal = 0;

      if (item.selectedOptions?.length) {
        for (const opt of item.selectedOptions) {
          const menuOpt = menuItem.options?.find(o => o.name === opt.name);
          const choice = menuOpt?.choices?.find(c => c.label === opt.choiceLabel);
          if (choice) optionsTotal += choice.priceModifier;
        }
      }

      const lineTotal = (itemPrice + optionsTotal) * item.quantity;
      subtotal += lineTotal;

      validatedItems.push({
        menuItemId: item.menuItemId,
        name: menuItem.name,
        price: itemPrice,
        quantity: item.quantity,
        options: item.selectedOptions || null,
        itemTotal: lineTotal,
        imageURL: menuItem.imageURL || null,
      });
    }

    const deliveryFee = fulfillmentType === "vendor_delivery" ? (biz.deliveryFee || 0) : 0;
    const total = subtotal + deliveryFee;

    // Generate order number
    const dateStr = new Date().toISOString().split("T")[0].replace(/-/g, "");
    const rand = Math.random().toString(36).substring(2, 5).toUpperCase();
    const orderNumber = `TE-${dateStr}-${rand}`;

    const orderRef = db.collection("orders").doc();

    const orderData = {
      orderId: orderRef.id,
      orderNumber,
      buyerId: request.auth.uid,
      buyerName: user.displayName || "Customer",
      buyerPhone: user.phoneNumber || "",
      buyerEmail: user.email || "",
      businessId,
      businessName: biz.name,
      businessPhone: biz.contactPhone,
      status: "pending",
      fulfillmentType,
      deliveryAddress: fulfillmentType === "vendor_delivery" ? deliveryAddress : null,
      items: validatedItems,
      subtotal,
      deliveryFee,
      platformFee: PLATFORM_FEE,
      total,
      paymentMethod,
      paymentStatus: paymentMethod === "cash" ? "pending_cash" : "pending",
      stripePaymentIntentId: null,
      cashConfirmedAt: null,
      cashConfirmedBy: null,
      specialInstructions: specialInstructions || null,
      estimatedReadyTime: null,
      actualReadyTime: null,
      cancelReason: null,
      cancelledBy: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      statusHistory: [{
        status: "pending",
        timestamp: new Date().toISOString(),
        updatedBy: request.auth.uid,
      }],
    };

    tx.set(orderRef, orderData);
    tx.update(bizDoc.ref, { totalOrders: FieldValue.increment(1) });

    return { orderId: orderRef.id, orderNumber, total };
  });

  return order;
});