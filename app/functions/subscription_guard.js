'use strict';

// Pending and delinquent subscriptions still belong to the customer and must
// be resolved before another Checkout session can be created.
function hasExistingVillagePlusSubscription(subscriptions, priceId) {
  return subscriptions.some(subscription =>
    ['active','trialing','past_due','unpaid','incomplete'].includes(subscription.status) &&
    subscription.items?.data?.some(item => item.price?.id === priceId));
}

module.exports = {hasExistingVillagePlusSubscription};
