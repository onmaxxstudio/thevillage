# Village Plus payments — development only

No payment endpoints have been deployed by this commit. Never commit Stripe keys or webhook signing secrets.

1. Confirm Firebase Blaze and billing budget alerts.
2. Create **test-mode** recurring Stripe price USD 4.99/month for Village Plus in the correct Onmaxx LLC Stripe account.
3. In `app/`, run `firebase functions:secrets:set STRIPE_SECRET_KEY` and `firebase functions:secrets:set STRIPE_WEBHOOK_SECRET` using **test** secrets initially. Set `VILLAGE_PLUS_PRICE_ID` using Firebase parameter configuration for the matching test price.
4. Install packages under `app/functions` with `npm install`, then deploy functions to a controlled test project, not production. The webhook URL is provided by Firebase deployment; register it in Stripe test-mode webhook destinations for `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`.
5. Test successful checkout, canceled checkout, renewal, failed payments, cancellation at period end, and webhook retries with two different Firebase users.
6. Premium Firestore rules must enforce `request.auth.token.villagePlus == true` for each premium collection before live checkout is enabled. Hiding a UI card is not access control.
7. Ensure Stripe customer portal configuration is active and refresh Firebase ID tokens after webhook membership changes.
8. For native iOS/Android apps, review Apple/Google digital-subscription in-app purchase rules before exposing this web checkout inside store-distributed apps.

The membership UI remains disabled until the backend, security rules and test payment flow are verified.
