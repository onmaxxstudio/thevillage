'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {hasExistingVillagePlusSubscription} = require('./subscription_guard');

const subscription = (status, price) => ({status,items:{data:[{price:{id:price}}]}});

test('prevents repeat checkout for active and unresolved subscriptions', () => {
  for(const status of ['active','trialing','past_due','unpaid','incomplete'])
    assert.equal(hasExistingVillagePlusSubscription([subscription(status,'village')],'village'),true);
});

test('allows expired subscriptions and ignores unrelated products', () => {
  for(const status of ['canceled','incomplete_expired'])
    assert.equal(hasExistingVillagePlusSubscription([subscription(status,'village')],'village'),false);
  assert.equal(hasExistingVillagePlusSubscription([subscription('active','other')],'village'),false);
});
