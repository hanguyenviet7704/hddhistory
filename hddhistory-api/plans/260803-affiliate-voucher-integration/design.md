# Affiliate voucher integration — voucher.eup.ai as the sole code source

Follow-on to `plans/260727-voucher-paywall-config-affiliate/design.md`, which
built HDDhistory's own voucher table (Part 4) and the outbound orders export (Part 5).
This replaces Part 4's *source of truth*: promo codes now come from the
affiliate team's service instead of `iap_vouchers`.

## The problem the design has to solve

Their `/voucher/get` answers with a **percentage** per package key. What HDDhistory
actually gets back, for code `HDDHISTORYTES`:

```json
{"vouchers":[{"package_key":"meup_sub_1y_50off","discount":50},
             {"package_key":"meup_sub_1y_30off","discount":30}]}
```

A percentage is not chargeable. Apple and Google only ever bill what a
registered SKU costs, so an arbitrary percent cannot be applied to an IAP
transaction. Everything below exists to bridge that gap.

## Decisions

**Percentage → SKU derived from `iap_products`, no separate table.** Their
`package_key` IS a HDDhistory product id, and the base half of the swap is already in
the catalogue as `compare_at_product_id` (admin surfaces it as "Giá gốc so sánh
(SKU)"). So `validate` resolves everything out of `iap_products`: look up the
named SKU, take its `salePercent` as the depth, and build the set of SKUs it may
replace from its plan family.

An earlier draft of this design used a dedicated `iap_voucher_discount_tiers`
table for the same job, on the assumption — taken from the spec sheet's
`pre1months` / `pre12months` examples — that `package_key` was an abstract key
needing translation. The live service disproved it. The table only ever restated
what the catalogue already knew, by hand, giving a second place to get wrong;
`DropVoucherDiscountTiers1785805200000` removes it.

**Price ordering comes from the catalogue, never from their percentage.** Both
numbers are display values, but only `iap_products.salePercent` is in the same
frame of reference as the SKU the user is looking at. Trusting theirs would let a
mismatched number swap a discounted SKU for a dearer one and charge *more* than
before the code — so a target with no catalogue `salePercent` is refused outright
and logged as a config fault, and a disagreement between the two numbers is
logged while the catalogue wins.

**A swap is offered from every SKU in the plan family.** `compareAtProductId`
names the *full-price* reference, not the SKU on screen — which shifts by cohort
and impression (`defaultUser` sees `meup_sub_1y_30off`; `newUser` impression 2
sees apple `20off` but google `30off`). The client swaps by exact product id, so
covering one base would leave the code silently doing nothing for every other
cohort. The family is the root plus every active sibling pointing at it, and each
base keeps only the deepest target — a repeated base would let the client's
`base → target` Map silently pick the shallower one.

**The affiliate service is the sole source.** Expiry, usage caps, per-user
limits and country rules all moved to their side; HDDhistory asks and trusts. Two
judgements stay local because they depend on a store catalogue the affiliate
cannot see: which SKU a percentage lands on, and whether it beats the sale
already running.

Accepted trade-offs: HDDhistory can no longer issue its own codes, and voucher.eup.ai
becomes a single point of failure for discounting. Blast radius is bounded on
purpose — the paywall itself never calls them, only the promo-code sheet does,
so an outage means *codes stop working*, not *nobody can buy*.

**`/voucher/get` on apply, `/voucher/use` after payment.** Reporting at apply
time would spend a usage slot on every abandoned checkout. Commission is
unaffected either way: it settles from `POST /purchase/affiliateOrder`, which
reads the persisted `iap_purchases.voucher_code`.

**All calls server-side.** Flutter keeps calling
`POST /api/v1/payment/vouchers/validate` and gets the same response shape, so
the plumbing ships with **no app release**. The tier table also needs to be
admin-editable, and the `% vs running sale` rule needs `iap_products.
salePercent`, both of which already live server-side.

**Base URL and product id hardcoded** in `affiliate/affiliate-voucher.constant.ts`
rather than env-driven: one company-internal host shared by every environment,
and the product id identifies the HDDhistory *app*, not a deployment. Cost: rotating
either is a code change plus a deploy.

## Flow

Apply:

```
PaywallPromoCodeSheet
 -> POST /api/v1/payment/vouchers/validate {code, platform}   [shape unchanged]
    -> AffiliateVoucherClient.get()  -> POST voucher.eup.ai/voucher/get
    -> resolve each package_key as an ACTIVE iap_products row (drops other
       EUP apps' keys, and SKUs HDDhistory has not created)
    -> build each target's plan family via compareAtProductId
    -> refuse targets with no catalogue salePercent   (ERROR: config fault)
    -> drop family members the target does not beat   -> reason `not_better`
    -> keep the deepest target per base
    <- {valid, reason?, code, discountPercent, products[{base,target}]}
```

Purchase:

```
POST /api/v1/payment/purchases/verify {..., voucherCode}      [shape unchanged]
 -> verify with store, commit purchase row carrying voucher_code
 -> AFTER commit: VoucherService.reportRedemption()
    -> package_key IS the charged SKU (their key space is HDDhistory product ids)
    -> POST voucher.eup.ai/voucher/use     [logged and swallowed on failure]
```

## Their API, as actually observed

Probed directly rather than taken from the doc:

- Backend is FastAPI. `422` returns a structured
  `{"detail":[{"loc":["body","code"],...}]}`.
- **`404` is ambiguous.** An unknown *code* and an unknown *product_id* return
  the identical body (`"The requested endpoint does not exist"` — misleading;
  the endpoint exists). A misconfigured product id is therefore
  indistinguishable from every user typo. The tell is the ratio: occasional
  404s are normal, 404 on *every* request means the product id is wrong.
- **No auth of any kind.** A call with no token returned another EUP app's full
  discount ladder using the product id published in the shared spec sheet.
  Anyone holding a product id can read tiers and probe codes. Raised with the
  affiliate team; `/voucher/get` and `/voucher/use` should carry `key_project`
  like `/purchase/affiliateOrder` does.
- A lookup for a non-existent code on a live product **hung past 12s**. Hence
  the 3s client ceiling — a product decision, not a network one.
- `package_key` is a **shared namespace**: one product id answered with `pre*`
  keys alongside `jlct*` ones. Keys with no tier row are ignored, which is how
  HDDhistory filters it without a separate allow-list.

## New reasons on the wire

`not_better` (code real, running sale is as good or better — deliberately not
applied per their spec) and `unavailable` (their service failed; never reads as
"bad code").

The Flutter enum declares `@JsonKey(unknownEnumValue: unknown)`, so builds
predating these degrade to the generic promo-code error rather than failing to
parse. Server ships first; a later app release adds the specific copy in all
five locales.

## What is built

| Piece | Location |
|---|---|
| HTTP client, never throws | `vouchers/affiliate/affiliate-voucher.client.ts` |
| Hardcoded host / product id / timeout | `vouchers/affiliate/affiliate-voucher.constant.ts` |
| `validate` rewrite + `reportRedemption` | `vouchers/voucher.service.ts` |
| Catalogue lookups (by id, and by `compareAtProductId`) | `products/repositories/product.repository.ts` |
| Redemption reporting hook | `purchases/purchase.service.ts` (replaces `incrementUsedCount`) |
| 14 specs | `vouchers/voucher.service.spec.ts` |
| Tier table created then dropped | `migrations/1785801600000-AddVoucherDiscountTiers.ts`, `migrations/1785805200000-DropVoucherDiscountTiers.ts` |

hddhistory-admin (`tsc --noEmit` + eslint clean):

| Piece | Location |
|---|---|
| Vouchers tab → read-only, points at `affiliate.eupgroup.net` | `pages/payments/components/VoucherSection.tsx` |
| Removed the false "not enforced by the backend" banner | `components/payments/VoucherSharedFields.tsx`, `types/interface/payments/voucher.interface.ts` |

There is deliberately **no** new admin screen. A "Bậc giảm giá" tab with full CRUD was built
and then deleted along with the tier table: the data it managed already lives on the product
itself, so the place to change a discount is the existing Product editor's "Giảm giá %" and
"Giá gốc so sánh (SKU)" fields.

hddhistory-flutter (`flutter analyze`: 0 issues in the changed files):

| Piece | Location |
|---|---|
| `not_better` + `unavailable` reasons | `monetization/data/models/voucher_validation_model.dart` |
| `attributedVoucherCode` (attribution split) | `monetization/presentation/cubits/iap_state.dart` |
| Attribution logic + verify now sends it | `monetization/presentation/cubits/iap_cubit.dart` |
| Two new messages | `paywall/paywall_promo_code_sheet.dart` + 5 locale YAMLs |

`attributedVoucherCode` is deliberately separate from `appliedVoucherCode`: the latter drives
the SKU swap and the "applied" chip, so reusing it for a code that changed no price would show
a success chip directly contradicting the message the sheet just displayed. Removing the code
by hand clears both; a failed SKU reload clears only the applied one, since the code itself
stayed valid.

`iap_vouchers` and `iap_voucher_product_mappings` are **kept**: they hold the
redemption history `iap_purchases.voucher_code` refers to. They simply stop
being read by `validate`. `VouchersModule` no longer registers `Purchase` /
`PurchaseRepository` — per-user limits moved to the affiliate side, so nothing
here reads purchases. The import edge must still stay one-directional
(PurchasesModule imports VouchersModule).

## Open items

1. **BLOCKER — `meup_sub_1y_50off` may not exist on HDDhistory's side.** The affiliate
   offers it for code `HDDHISTORYTES`, but that SKU appears nowhere in this repo, in
   `/paywall-config/mobile`, or in any product DTO example — only `meup_sub_1y`,
   `_20off`, `_30off` and `meup_sub_1m_50off` do. Until it exists as an **active**
   `iap_products` row on both platforms *and* is registered in App Store Connect
   and Play Console, `validate` answers `not_applicable` and logs why. No code
   change can work around it: a SKU the store does not sell cannot be charged,
   and that store-side work is manual and Apple-reviewed. This is the real limit
   on "affiliate mints codes freely".

   Once it exists the row also needs `Giảm giá %` set — a target with no
   `salePercent` is refused, because there is then no catalogue evidence it is
   cheaper than what the user already sees — and `Giá gốc so sánh (SKU)` pointing
   at `meup_sub_1y` so it joins the yearly family.
2. **`reportRedemption` is only reachable when `voucherConsumed` is true** —
   i.e. a new, non-renewal purchase. Renewals of a subscription originally bought
   with a code are never reported to `/voucher/use`. Whether the affiliate should
   earn recurring commission is a business question, not a code one; worth
   settling with them.
3. **No rate limit** on `POST /payment/vouchers/validate`, which now proxies to
   a third party on every keystroke-submit. Code enumeration is cheap and there
   is no `ThrottlerModule` in `app.module.ts`.
4. **Still no role guard** on the voucher controller — any authenticated app user
   can create or delete the legacy vouchers. `RoleGuard` and `@Roles()` exist but
   are unused repo-wide; wiring them is a behaviour change that needs roles
   provisioned first, or it locks the admin panel out.
5. **`VoucherModal` / `VoucherBulkImportModal` / `VoucherMappingsEditor` are now
   dead** — nothing renders them since the Vouchers tab went read-only. Left in
   place rather than deleted in case legacy rows ever need editing again; delete
   them once that is ruled out.

## Verification status

| Gate | Result |
|---|---|
| `hddhistory-api` `npx tsc --noEmit` | 0 errors in `src/` |
| `hddhistory-api` `voucher.service.spec.ts` | 14/14 pass |
| `hddhistory-api` eslint (changed files) | clean |
| `hddhistory-admin` `npx tsc --noEmit` | clean |
| `hddhistory-flutter` `flutter analyze` | 0 issues in changed files (109 pre-existing elsewhere, 82 of them orphan tests of the deleted onboard_branching flow) |

Verified against the live service by hand: `POST voucher.eup.ai/voucher/get` with
HDDhistory's product id and code `HDDHISTORYTES` returns 200 and the two-package payload
quoted above. **Not** verified: the full app→API→affiliate→store path, because the
SKU they offer does not yet exist on HDDhistory's side (open item 1). Every claim about
`validate`'s behaviour rests on specs, not on a real redemption.
