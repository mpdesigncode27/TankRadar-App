# FuelNow Plus — Subscriptions & Free Trial

This document describes how FuelNow Plus is wired through StoreKit 2,
including the **3-day Free Trial Introductory Offer** introduced with
[Linear TAN-81](https://linear.app/tankradar-app/issue/TAN-81/plus-3-tage-kostenloser-probezeitraum-free-trial-introductory-offer).

## Product configuration

- Subscription Group: **FuelNow Plus** (`B17E94D2`)
- Auto-renewable subscription product:
  - **Product ID:** `com.vibecoding.fuelnow.subscription.year`
  - **Period:** 1 year (`P1Y`)
  - **Display price (DEU):** € 6.00 (placeholder — overridden by ASC pricing tier)
  - **Family shareable:** false
- Introductory offer (Free Trial):
  - **Payment mode:** Free Trial
  - **Period:** 3 days (`P3D`)
  - **Eligibility:** Apple-managed — first-time purchasers per Subscription Group / Family.

## Local development (`FuelNowPlus.storekit`)

`FuelNowPlus.storekit` is the source of truth for **local Previews,
Simulator runs, and Swift Testing** (`SKTestSession`). It mirrors the
production ASC offer:

```json
"introductoryOffer" : {
  "displayPrice" : "0.00",
  "internalID" : "7A1B9C3D",
  "numberOfPeriods" : 1,
  "paymentMode" : "free",
  "subscriptionPeriod" : "P3D"
}
```

Notes:

- StoreKit Configuration JSON uses `"paymentMode": "free"` for free trials —
  the runtime API exposes the same offer as
  `Product.SubscriptionOffer.PaymentMode.freeTrial`.
- The file is added to the **FuelNowTests** Resources build phase so
  `EntitlementManagerStoreKitTests` can boot a deterministic
  `SKTestSession`.
- A simulator run can be configured with this `.storekit` file via the
  scheme's *Run → Options → StoreKit Configuration*.

## App Store Connect (Production)

Apple's **minimum free-trial duration is 3 days** — 48 h is not selectable
in App Store Connect. The owner decided on Variant A in the TAN-81
discussion (3-day Free Trial via the standard StoreKit Introductory Offer).

Steps to configure once per app:

1. Open **App Store Connect → Apps → FuelNow → Subscriptions** (left
   sidebar).
2. Open the **FuelNow Plus** group, then the
   `com.vibecoding.fuelnow.subscription.year` product.
3. Open the **Subscription Pricing** section.
4. Click **Set Up Introductory Offer**.
5. Configure:
   - **Type:** Free Trial
   - **Eligibility:** *New Subscribers* (Apple's default — only first-time
     purchasers in this Subscription Group)
   - **Duration:** 3 Days
   - **Countries / Regions:** All (default)
   - **Start / End:** No end date (or roll a date-bounded campaign)
6. **Save** and propagate. Allow ~15 minutes for the offer to surface in
   `Product.subscription.introductoryOffer`.

> The offer flips on for users who have **never** subscribed to a product
> in the *FuelNow Plus* Subscription Group on the same Family. Apple
> serves at most **one** Introductory Offer per group per Family. See:
> [Implementing introductory offers in your app](https://developer.apple.com/documentation/storekit/implementing-introductory-offers-in-your-app).

## Eligibility check

The app **never** hardcodes the trial duration or eligibility flag. At
runtime, `PlusPurchaseController.refreshTrialOffer(for:)` reads:

- `Product.subscription?.introductoryOffer` — duration, payment mode,
  number of periods.
- `Product.SubscriptionInfo.isEligibleForIntroOffer` (async) — whether
  the current Apple ID can still redeem the trial.

The result is exposed as `PlusPurchaseController.trialOffer` and consumed
by `PlusPaywallCopy.audience(...)`, which produces one of three deterministic
audiences:

| Audience | Trigger | UI Effect |
| --- | --- | --- |
| `activeSubscriber` | `EntitlementManager.isPlusSubscriber == true` | Status block, no trial copy |
| `eligibleForTrial` | not subscribed + Apple eligibility = true | Trial headline + trial CTA + trial badge |
| `ineligibleForTrial` | not subscribed + Apple eligibility = false | Standard subscribe CTA, standard footer |

`PlusPaywallCopy.formattedTrialDuration(...)` renders the period via
`DateComponentsFormatter` so the string is locale-correct (`3 Tage` /
`3 days`).

## Testing

- **Unit (deterministic):** `PlusPaywallCopyTests` and the extended
  `PlusPurchaseControllerTests` cover audience selection, period
  formatting, and copy output. They run with no `SKTestSession`.
- **StoreKit session:** `EntitlementManagerStoreKitTests` boots
  `SKTestSession` against `FuelNowPlus.storekit`. The suite is
  auto-disabled on iOS 26.3 / 26.4 due to the Apple-confirmed bug
  (release-noted as fixed in iOS 26.5 RC) — see TAN-62.
- **Simulator smoke:** `./scripts/build-and-run-simulator.sh` then open
  *Settings → FuelNow Plus* and the *„FuelNow Plus ansehen"* sheet to see
  the trial badge / headline.

## Sources

- Apple — [Set up introductory offers for auto-renewable subscriptions](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions)
- Apple — [Implementing introductory offers in your app](https://developer.apple.com/documentation/storekit/implementing-introductory-offers-in-your-app)
- Apple — [`Product.SubscriptionInfo.isEligibleForIntroOffer`](https://developer.apple.com/documentation/storekit/product/subscriptioninfo/iseligibleforintrooffer)
- Apple — [`Product.SubscriptionOffer`](https://developer.apple.com/documentation/storekit/product/subscriptionoffer)
- Apple HIG — [In-App Purchase guidelines](https://developer.apple.com/design/human-interface-guidelines/in-app-purchase)
