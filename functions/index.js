const admin = require("firebase-admin");
admin.initializeApp();

// Auth triggers
exports.onUserCreated = require("./src/auth/onUserCreated");

// Callable functions
exports.assignCompanyRole = require("./src/auth/assignCompanyRole");
exports.createBusiness = require("./src/businesses/createBusiness");
exports.createOrder = require("./src/orders/createOrder");
exports.updateOrderStatus = require("./src/orders/updateOrderStatus");
exports.createPaymentIntent = require("./src/payments/createPaymentIntent");
exports.createStripeOnboardingLink = require("./src/payments/createStripeOnboardingLink");
exports.processRefund = require("./src/payments/processRefund");
exports.registerFcmToken = require("./src/notifications/registerFcmToken");

// Firestore triggers
exports.onOrderStatusChange = require("./src/orders/onOrderStatusChange");

// HTTP endpoints
exports.stripeWebhook = require("./src/payments/stripeWebhook");

// Scheduled functions
exports.cleanupExpiredDocs = require("./src/scheduled/cleanupExpiredDocs");
exports.aggregateAnalytics = require("./src/scheduled/aggregateAnalytics");