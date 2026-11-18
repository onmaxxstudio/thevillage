# Village Plus payments — development only

No payment endpoints have been deployed by this commit. Never commit Stripe keys or webhook signing secrets.

1. Confirm Firebase Blaze and billing budget alerts.
2. The Onmaxx LLC sandbox already has a recurring USD 4.99/month price: `price_1UdERrBS765EDoWJqr4PSRnn` (verify its product and account before configuring it). Never use a live-mode price.
3. Create a separate Firebase project with Blaze enabled, then explicitly select its project ID with `--project` on every Firebase command. Set `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` with `firebase functions:secrets:set` on that test project only. Configure `VILLAGE_PLUS_PRICE_ID` to the sandbox price and `VILLAGE_PLUS_RETURN_URL` to a separate HTTPS test site. Never store credentials in the repository, shell history, or `.env` committed to Git. The functions refuse to run when the project is missing or is `the-village-d7af4`, and reject the production return hostname.
4. Install packages under `app/functions` with `npm install`, then deploy only the three payment functions to the test project with an explicit `--project TEST_PROJECT_ID`. The webhook URL is provided by Firebase deployment; register it in the Stripe sandbox webhook destinations for `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`. Store its unique signing secret in the test project's Secret Manager and redeploy the webhook function.
5. Use two test-project Firebase users. Test successful checkout and membership claim refresh, canceled checkout, renewal, failed payment, cancellation at period end, webhook retries, and access denied to the unpaid user. Do not use production users or data.
6. Premium Firestore rules must enforce `request.auth.token.villagePlus == true` for each premium collection before live checkout is enabled. Hiding a UI card is not access control.
7. Ensure Stripe customer portal configuration is active and refresh Firebase ID tokens after webhook membership changes.
8. For native iOS/Android apps, review Apple/Google digital-subscription in-app purchase rules before exposing this web checkout inside store-distributed apps.

The membership UI remains disabled until the backend, security rules and test payment flow are verified.
