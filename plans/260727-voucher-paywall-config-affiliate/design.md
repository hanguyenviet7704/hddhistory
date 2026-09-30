# Voucher + paywall config in admin + affiliate orders API

Spans **hddhistory-api**, **hddhistory-admin**, **hddhistory-flutter**. Five independently
shippable parts. Written 2026-07-27.

## Hard invariants (do not break)

1. **The store owns price.** Apple/Google decide what a user is charged. HDDhistory
   never sets a price — it only chooses *which SKU to sell*. A discount is
   always "show a cheaper SKU", never "charge less for the same SKU".
2. **A missing SKU must never blank the paywall.** `getProducts` currently
   throws `StateError('Configured store product is missing')` when any
   configured id is absent from the store, and `_loadSelectedRemoteProducts`
   throws `'Configured BE product is missing'` when absent from the API
   (`hddhistory-flutter/lib/src/monetization/data/repositories/monetization_repository.dart:50,89`).
   Every new code path that changes the SKU set must degrade to the base SKUs,
   not propagate the throw.
3. **The client never chooses which SKU it gets.** The server resolves a
   voucher to a SKU set. Otherwise anyone can force the deepest discount.
4. **Remote Config stays the delivery channel.** Admin replaces the Firebase
   Console *editing* UI only. The app is not changed and needs no release.

## Verified facts this design rests on

| Fact | Evidence |
| --- | --- |
| Displayed price comes from the store, not the API | `iap_product_model.dart:97-102` overwrites `price`/`rawPrice`/`currency*` with `ProductDetails` values |
| `salePercent` is a cosmetic badge; `salePrice` is dead | `paywall_plan_option.dart:73`; `salePrice` is absent from the Flutter model |
| No voucher/coupon/promo concept exists in any of the 3 repos | grep across all three |
| dev and prod share ONE Remote Config template | same Firebase project `meup-bf64f`; `paywall_config` has no conditions |
| ASC API can read per-territory prices | verified: 175 territory rows for `meup_sub_1y_30off` (e.g. `AUS 22.99 AUD`, `AUT 14.99 EUR`) |
| Play API price read is **unverified** | `google-service.json` in the repo is an empty placeholder; the real key exists only on the server |
| Recorded purchase prices are already wrong on prod | a paid `meup_sub_1m_70off` is stored as `VND 2.99` for a $2.99 product |

## Out of scope (v1)

Deferred deep link (install attribution) · web checkout (PayPal/momo/transfer) ·
native store offer codes · manually typed regional prices.

---

## Part 1 — Fix the purchase price snapshot *(≈0.5 day, do first)*

`buildPriceSnapshot` (`src/modules/payment/helpers/store-utils.ts:47-49`)
resolves amount and currency **independently**:

```ts
const rawPrice = override?.rawPrice ?? product.salePrice ?? product.rawPrice;
const currency = (override?.currency as any) ?? product.currency;
```

When the store payload carries a currency but no amount — the normal Apple case,
because the helper reads `tx.rawPrice`, a field Apple does not send — the row
gets the store's currency with the local USD amount. Hence `VND 2.99`.

**Changes (hddhistory-api)**
1. Make `(rawPrice, currency)` atomic: if the store supplied an amount, take the
   amount *and* the currency from the store; otherwise take both from the
   product row. Never mix sources.
2. Fix the Apple branch of `purchase.helper.ts` to read the real payload fields
   (`price` in milli-units → divide by 1000, and `currency`).
3. Migrate `iap_purchases.currency` from `enum('USD','VND')` to `varchar(3)`
   (ISO-4217). Without this the first JPY/KRW/THB purchase fails to persist —
   Play is live in 174 countries.
4. Backfill the incorrect prod rows (only 5 purchases exist today).

**Tests** — unit-test `buildPriceSnapshot` for: store supplies both; store
supplies neither; store supplies currency only (the regression case).

---

## Part 2 — Regional price sync *(≈1.5–2 days)*

Admin currently shows `Price = —` because `iap_products.rawPrice/price` are
mostly null and not editable. Pull the real numbers from the stores instead of
typing them, so admin can never drift from what users are charged.

**Backend (hddhistory-api)**
- New table `iap_product_prices`:
  `product_id, platform, territory, currency, customer_price, source, synced_at`
  (unique on `product_id + platform + territory`).
- Sync service, one adapter per store:
  - **Apple** — ASC API `GET /v1/subscriptions/{id}/prices?include=subscriptionPricePoint,territory`.
    Requires resolving `productId` → ASC internal subscription id first
    (`/v1/apps?filter[bundleId]` → `subscriptionGroups` → `subscriptions`).
    Reuse the ES256 JWT signing already used for App Store Server API.
  - **Google** — Play Developer API `monetization.subscriptions.get`, reading
    `basePlans[].regionalConfigs[].price`.
- Trigger: scheduled daily + a manual "Sync now" endpoint.

**Admin (hddhistory-admin)**
- A "Regional Prices" table under Product management, columns = territory,
  rows = product, showing `customer_price + currency` and `synced_at`.
- Read-only. These values are for staff visibility; they are never sent to the
  app as the price to display.

**Risk — Play permissions.** The service account's `androidpublisher` scope is
correct for purchases, but reading *monetization* is a separate Play Console
permission that could not be verified from this machine. Build the Apple adapter
first; if the Play permission is missing, the Android section must render
"not configured" rather than failing the whole feature. Someone with Play
Console access must confirm the permission before Part 2 is considered done.

---

## Part 3 — paywall_config editor in admin *(≈2–3 days)*

Today `paywall_config` is a large hand-edited JSON blob in the Firebase Console.
A typo there takes down the production paywall, and **dev and prod share the
same template**.

**Backend (hddhistory-api)**
- `GET /paywall-config` and `PUT /paywall-config` — read/write the Remote Config
  template through the Firebase Admin SDK. The app is untouched.
- **Validation on write — the point of the whole part.** Reject the save if any
  referenced `appleProductId`/`googleProductId` is missing or inactive in
  `iap_products` for that platform. This is exactly the failure that blanked the
  dev paywall (`meup_sub_1y_30off` referenced but not registered).
- Write through Remote Config **conditions** so dev and prod get separate
  values. Until this exists, every config change hits production.

**Admin (hddhistory-admin)**
- Form mirroring the schema: `defaultUser`, `newUser` (with `impressionRules`),
  `saleEvent`; per-locale content for all 5 locales; product pickers backed by
  the `iap_products` list rather than free-text.
- Surface Remote Config's native version history (who changed what, rollback).

---

## Part 4 — Voucher *(≈3–4 days)*

HDDhistory owns vouchers outright; no dependency on the affiliate team. Marketing
creates the code on `affiliate.eupgroup.net` for commission tracking and mirrors
it into HDDhistory admin for the discount. Bulk paste keeps that cheap.

**Backend (hddhistory-api)**
- `vouchers`: `code (unique), owner, discount_percent, valid_from, valid_to,
  max_uses, used_count, per_user_limit, countries, is_active`.
  - `discount_percent` is **for display and affiliate reporting only**. The real
    discount is whatever the target SKU costs in the user's territory — the two
    can legitimately differ, since store price tiers do not land on exact
    percentages in every currency. Never compute a charge from this field.
  - `countries` is an allow-list of ISO country codes the code may be redeemed
    in; empty means all countries.
- `voucher_product_mappings`: `voucher_id, platform, base_product_id,
  target_product_id`. Free-form on purpose — the discount ladder is asymmetric
  (monthly 50/70, yearly 20/30) and the yearly tiers will be revisited later.
- `POST /vouchers/validate { code }` → `{ valid, discount, products[] }`.
  The server resolves the SKU set; the client only renders it.
- `VerifyPurchaseDto` gains `voucherCode`; the verify flow persists `code` and
  `discount` on the purchase row and increments `used_count`. Re-validate at
  verify time — do not trust that the code was valid when the sheet opened.

**Admin (hddhistory-admin)**
- Voucher CRUD, bulk import (paste a list of codes), and a mapping picker
  restricted to existing active products.

**Flutter (hddhistory-flutter)**
- "Have a discount code?" link on the paywall → bottom sheet with a text field
  (the monetization feature has no text input today).
- On success, swap **only the plans that have a mapping**; leave the rest as the
  active strategy resolved them.
- Re-enable the struck-through original price
  (`paywall_plan_option.dart:168` currently hardcodes `_showOriginalPrice => false`)
  and compute it from the **base SKU's real store price**, not by back-deriving
  from `salePercent`.
- On any resolution failure: keep the base SKUs, show "code unavailable". Never
  an empty paywall.
- slang keys for all 5 locales.

---

## Part 5 — Affiliate orders API *(≈1 day, needs Part 4)*

`POST /purchase/affiliateOrder`, `@Public()` plus a `key_project` guard reading a
shared secret from env (matching how `OUTPUT_PRACTICE_AI_SECRET_TOKEN` is
configured today). Body: `key_project, start_time, end_time, limit, skip`.

Field mapping:

| Spec field | Source |
| --- | --- |
| `code`, `discount` | new purchase columns from Part 4 |
| `order_id` | `iap_purchases.order_id` — **see fix below** |
| `user_id`, `email`, `user_name` | existing denormalised columns |
| `price`, `currency` | existing columns, correct only after Part 1 |
| `status` | `paid` → 1, everything else → 0 |
| `order_date_ms` | `purchase_time` → epoch ms |
| `package_key`, `package` | `product_id`, joined `iap_products.title` |
| `user_platform` | derived from `platform` (apple→ios, google→android) |
| `country`, `language` | **new** — capture at verify time |
| `payment_platform` | only `google`/`apple` exist; `paypal`/`momo`/`transfer` have no code path |

**Also fix:** iOS `order_id` currently stores `originalTransactionId`
(`purchase.helper.ts:418-419,448`), so every renewal of a subscription shares one
id. The spec requires a per-order unique id, so renewals would collapse into a
single order. Store the per-transaction `transactionId` in `order_id` and keep
`originalTransactionId` in its own column.

---

## Suggested order

Part 1 → Part 2 / Part 3 (independent, can run in parallel) → Part 4 → Part 5.

Part 1 is urgent independently of everything else: every new purchase records
wrong revenue until it lands.
