-- SUPERSEDED — kept as documentation only. Do not run this by hand.
--
-- All of the DDL below now lives in
--   src/migrations/1785110400000-AddVoucherAndPurchaseColumns.ts
-- and is applied automatically at application boot (`migrationsRun: true` in
-- src/base/database/mysql/mysql.module.ts). The migration checks
-- information_schema before each ALTER, so it is safe against a database where
-- part of this file was already applied manually.
--
-- This file remains as the human-readable record of what the schema change is.
--
-- ---------------------------------------------------------------------------
--
-- Voucher tables for the paywall promo-code feature.
--
-- This repo has NO TypeORM migration system and MySQL runs with
-- `synchronize: false` (src/base/database/mysql/mysql.module.ts), so every
-- table here is provisioned out-of-band — the same way iap_products,
-- iap_purchases, iap_subscriptions and iap_webhook_events were.
-- Apply this against each environment's MySQL before the voucher endpoints
-- are called; until then POST /api/v1/payment/vouchers/validate will error.
--
-- Column names mirror the entities exactly. Note the mixed casing: fields on
-- AbstractEntity (id, createdBy, updatedBy, createdAt, updatedAt) keep
-- camelCase because no namingStrategy is configured, while the voucher
-- columns are snake_case via explicit `name:` on each @Column.

CREATE TABLE IF NOT EXISTS `iap_vouchers` (
  `id`               VARCHAR(36)      NOT NULL,
  `createdBy`        VARCHAR(36)      NULL,
  `updatedBy`        VARCHAR(36)      NULL,
  `createdAt`        TIMESTAMP(6)     NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updatedAt`        TIMESTAMP(6)     NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                       ON UPDATE CURRENT_TIMESTAMP(6),
  `code`             VARCHAR(64)      NOT NULL
                       COMMENT 'Always stored trimmed + uppercased',
  `owner`            VARCHAR(255)     NULL
                       COMMENT 'Affiliate owner, for reporting only',
  `discount_percent` TINYINT UNSIGNED NULL
                       COMMENT 'DISPLAY/REPORTING ONLY. The real discount is whatever the target SKU costs in the user territory; never compute a charge from this field.',
  `valid_from`       DATETIME         NULL,
  `valid_to`         DATETIME         NULL,
  `max_uses`         INT              NULL COMMENT 'Null = unlimited',
  `used_count`       INT              NOT NULL DEFAULT 0,
  `per_user_limit`   INT              NULL COMMENT 'Null = unlimited',
  `countries`        TEXT             NULL
                       COMMENT 'simple-array: comma-joined ISO codes. Null/empty = all countries',
  `is_active`        TINYINT(1)       NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UQ_iap_vouchers_code` (`code`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `iap_voucher_product_mappings` (
  `id`                VARCHAR(36)  NOT NULL,
  `createdBy`         VARCHAR(36)  NULL,
  `updatedBy`         VARCHAR(36)  NULL,
  `createdAt`         TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updatedAt`         TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
                        ON UPDATE CURRENT_TIMESTAMP(6),
  `voucher_id`        VARCHAR(36)  NOT NULL,
  `platform`          ENUM('google','apple') NOT NULL,
  `base_product_id`   VARCHAR(255) NOT NULL COMMENT 'SKU shown normally',
  `target_product_id` VARCHAR(255) NOT NULL COMMENT 'Discounted SKU to show instead',
  PRIMARY KEY (`id`),
  KEY `IDX_iap_voucher_mappings_voucher` (`voucher_id`),
  UNIQUE KEY `UQ_iap_voucher_mappings_voucher_platform_base`
    (`voucher_id`, `platform`, `base_product_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Sanity check after applying:
--   SHOW COLUMNS FROM iap_vouchers;
--   SHOW COLUMNS FROM iap_voucher_product_mappings;
-- Then confirm the endpoint answers instead of 500-ing:
--   POST /api/v1/payment/vouchers/validate  {"code":"ANYTHING","platform":"apple"}
--   → expected {"valid":false,"reason":"not_found"}


-- ---------------------------------------------------------------------------
-- Widen iap_purchases.currency: live money-data bug fix (mismatched
-- currency/amount pairs on Apple purchases -- see
-- src/modules/payment/helpers/store-utils.ts and purchases/purchase.helper.ts)
-- ---------------------------------------------------------------------------
--
-- `iap_purchases.currency` was `enum('USD','VND')` (PaymentCurrency), but it
-- snapshots whatever ISO-4217 currency the STORE actually charged the buyer
-- in, not one of our catalog currencies. Google Play alone is live in 174
-- countries, so the first JPY/KRW/THB (etc.) purchase can't be persisted with
-- the enum column. Widen it to a plain ISO-4217 varchar; the application-side
-- Purchase entity (`purchases/entities/purchase.entity.ts`) has already been
-- updated to match (`currency?: string`, `type: 'varchar', length: 3`).
--
-- `iap_products.currency` (PaymentCurrency) is intentionally left as the enum
-- -- it's an admin-curated catalog value (which base currencies we sell in),
-- not a store-charged snapshot, so it does not need widening. See the agent
-- report for the full reasoning.
--
-- No migration system in this repo (synchronize: false) -- apply by hand
-- against each environment's MySQL, same as the tables above.

ALTER TABLE `iap_purchases`
  MODIFY COLUMN `currency` VARCHAR(3) NULL
    COMMENT 'ISO-4217 currency code snapshotted from the store at purchase time (NOT restricted to PaymentCurrency -- Google Play alone is live in 174 countries/currencies)';

-- Sanity check after applying:
--   SHOW COLUMNS FROM iap_purchases LIKE 'currency';
--   -- expect: Type = varchar(3), Null = YES


-- ---------------------------------------------------------------------------
-- Manual backfill for the known-bad rows (mismatched currency/amount pair
-- produced by the bug above). DO NOT run blind -- confirm each row's actual
-- charged currency/amount against the store receipt (App Store Connect /
-- Play Console order lookup) before writing it. Below is the one confirmed
-- example from the bug report; repeat the same shape for the other ~4 rows
-- once each is individually confirmed against its store receipt.
-- ---------------------------------------------------------------------------
--
-- Example (confirmed): meup_sub_1m_70off row incorrectly stored as
-- currency=VND, rawPrice=2.99 (product catalog USD amount + store VND
-- currency). The buyer actually paid ~75,000 VND for a $2.99 product.
--
-- UPDATE `iap_purchases`
-- SET `currency` = 'VND',
--     `raw_price` = 75000,           -- replace with the exact receipt amount
--     `price` = 'VND 75000'
-- WHERE `id` = '<row-id-from-production>';
--
-- Repeat per affected row after confirming the real store amount; do not
-- guess a conversion rate.


-- ---------------------------------------------------------------------------
-- Part 4/5: voucher redemption + affiliate-order columns on iap_purchases
--
-- Adds:
--   - voucher_code / voucher_discount_percent: snapshotted at verify() time
--     when a voucherCode is supplied and re-validates server-side (see
--     purchases/purchase.service.ts verify() and vouchers/voucher.service.ts
--     validate()). Both stay NULL when no voucher was used OR the code no
--     longer validates at verify time -- a stale code must never fail a real
--     purchase.
--   - original_transaction_id: Apple's originalTransactionId (the renewal
--     anchor). `order_id` used to double as this anchor id, which meant every
--     renewal of an Apple subscription shared one order_id. `order_id` now
--     stores the per-transaction id (unique per renewal, required by the
--     affiliate order_id contract); `original_transaction_id` keeps the
--     anchor value so the existing subscription-anchor logic is unaffected --
--     see purchases/purchase.helper.ts verifyApple().
--   - country / language: snapshot of the purchasing user's Mongo profile
--     (User.country / User.language) at verify() time. Never populated
--     retroactively for historical rows.
--
-- No migration system in this repo (synchronize: false) -- apply by hand
-- against each environment's MySQL, same as everything else in this file.
-- ---------------------------------------------------------------------------

ALTER TABLE `iap_purchases`
  ADD COLUMN `original_transaction_id` VARCHAR(255) NULL
    COMMENT 'Apple originalTransactionId (subscription/renewal anchor). See order_id for the per-transaction id.'
    AFTER `order_id`,
  ADD COLUMN `voucher_code` VARCHAR(64) NULL
    COMMENT 'Voucher code applied at verify() time, re-validated server-side. NULL when no voucher was used or the code no longer validated (never blocks the purchase).'
    AFTER `idempotency_key`,
  ADD COLUMN `voucher_discount_percent` TINYINT UNSIGNED NULL
    COMMENT 'Snapshot of iap_vouchers.discount_percent at redemption time -- display/reporting only, matches the voucher_code above.'
    AFTER `voucher_code`,
  ADD COLUMN `country` VARCHAR(64) NULL
    COMMENT 'Snapshot of the purchasing user Mongo profile (User.country) at verify() time.'
    AFTER `voucher_discount_percent`,
  ADD COLUMN `language` VARCHAR(32) NULL
    COMMENT 'Snapshot of the purchasing user Mongo profile (User.language) at verify() time.'
    AFTER `country`;

ALTER TABLE `iap_purchases`
  ADD INDEX `IDX_iap_purchases_voucher_code` (`voucher_code`);

-- Sanity check after applying:
--   SHOW COLUMNS FROM iap_purchases
--     LIKE 'original_transaction_id';           -- expect: varchar(255), NULL
--   SHOW COLUMNS FROM iap_purchases LIKE 'voucher_code';       -- varchar(64)
--   SHOW COLUMNS FROM iap_purchases LIKE 'voucher_discount_percent'; -- tinyint unsigned
--   SHOW COLUMNS FROM iap_purchases LIKE 'country';             -- varchar(64)
--   SHOW COLUMNS FROM iap_purchases LIKE 'language';            -- varchar(32)
--   SHOW INDEX FROM iap_purchases WHERE Key_name = 'IDX_iap_purchases_voucher_code';
-- Then confirm a verify() call with a voucherCode persists both voucher
-- columns and increments iap_vouchers.used_count by exactly 1 for a genuinely
-- new (non-renewal) purchase row, and that renewals/dedupe-updates leave
-- used_count untouched.
