const { https } = require("firebase-functions/v2");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

module.exports = https.onCall(async (request) => {
  if (request.auth?.token?.role !== "developer") {
    throw new https.HttpsError("permission-denied", "Only the developer can create businesses.");
  }

  const { name, slug, description, category, contactPhone, contactEmail, address, fulfillmentModes } = request.data;

  if (!name || !slug || !category || !contactPhone || !contactEmail) {
    throw new https.HttpsError("invalid-argument", "Missing required fields.");
  }

  const db = getFirestore();

  // Check slug uniqueness
  const slugCheck = await db.collection("businesses").where("slug", "==", slug).get();
  if (!slugCheck.empty) {
    throw new https.HttpsError("already-exists", "This slug is already taken.");
  }

  const bizRef = db.collection("businesses").doc();
  const businessId = bizRef.id;

  await bizRef.set({
    businessId,
    ownerId: null, // Assigned when a user gets company role
    name,
    slug,
    description: description || "",
    category,
    tags: [],
    logoURL: "",
    bannerURL: null,
    contactPhone,
    contactEmail,
    address: address || {},
    operatingHours: {},
    isOpen: false,
    isActive: true,
    isVerified: false,
    fulfillmentModes: fulfillmentModes || ["pickup"],
    deliveryRadius: null,
    deliveryFee: null,
    averageRating: 0,
    totalReviews: 0,
    totalOrders: 0,
    stripeAccountId: null,
    stripeOnboardingComplete: false,
    storeLink: `https://tshikotaeats.co.za/store/${slug}`,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Create empty menu document
  await db.collection("menus").doc(businessId).set({
    businessId,
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Update platform analytics
  await db.collection("analytics").doc("platform").set({
    totalBusinesses: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  return { success: true, businessId };
});