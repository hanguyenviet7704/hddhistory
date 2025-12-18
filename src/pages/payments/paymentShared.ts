import {
  PaymentCurrency,
  PaymentPlatform,
  ProductType,
  PurchaseEventType,
  PurchaseStatus,
  SubscriptionStatus,
} from "../../types/enum/payment.enum";

export const platformLabels: Record<PaymentPlatform, string> = {
  [PaymentPlatform.APPLE]: "Apple",
  [PaymentPlatform.GOOGLE]: "Google",
};

export const typeLabels: Record<ProductType, string> = {
  [ProductType.SUBSCRIPTION_AUTO_RENEW]: "Subscription (Auto-renew)",
  [ProductType.SUBSCRIPTION_NON_RENEW]: "Subscription (Non-renew)",
  [ProductType.NON_CONSUMABLE]: "Non-consumable",
  [ProductType.CONSUMABLE]: "Consumable",
};

export const purchaseStatusLabel: Record<PurchaseStatus, string> = {
  [PurchaseStatus.PENDING]: "Pending",
  [PurchaseStatus.PAID]: "Paid",
  [PurchaseStatus.FAILED]: "Failed",
  [PurchaseStatus.CANCELED]: "Canceled",
  [PurchaseStatus.REFUNDED]: "Refunded",
};

export const purchaseStatusTone: Record<PurchaseStatus, string> = {
  [PurchaseStatus.PENDING]: "bg-amber-50 text-amber-700 border-amber-100",
  [PurchaseStatus.PAID]: "bg-emerald-50 text-emerald-700 border-emerald-100",
  [PurchaseStatus.FAILED]: "bg-red-50 text-red-700 border-red-200",
  [PurchaseStatus.CANCELED]: "bg-slate-100 text-slate-700 border-slate-200",
  [PurchaseStatus.REFUNDED]: "bg-purple-50 text-purple-700 border-purple-100",
};

export const eventTypeLabel: Record<PurchaseEventType, string> = {
  [PurchaseEventType.INITIAL]: "Initial",
  [PurchaseEventType.RENEWAL]: "Renewal",
  [PurchaseEventType.CANCEL]: "Cancel",
  [PurchaseEventType.REFUND]: "Refund",
};

export const eventTypeTone: Record<PurchaseEventType, string> = {
  [PurchaseEventType.INITIAL]: "bg-sky-50 text-sky-700 border-sky-100",
  [PurchaseEventType.RENEWAL]: "bg-emerald-50 text-emerald-700 border-emerald-100",
  [PurchaseEventType.CANCEL]: "bg-amber-50 text-amber-800 border-amber-200",
  [PurchaseEventType.REFUND]: "bg-purple-50 text-purple-700 border-purple-100",
};

export const subscriptionStatusLabel: Record<SubscriptionStatus, string> = {
  [SubscriptionStatus.ACTIVE]: "Active",
  [SubscriptionStatus.EXPIRED]: "Expired",
  [SubscriptionStatus.GRACE]: "Grace",
  [SubscriptionStatus.ON_HOLD]: "On hold",
  [SubscriptionStatus.CANCELED]: "Canceled",
};

export const subscriptionStatusTone: Record<SubscriptionStatus, string> = {
  [SubscriptionStatus.ACTIVE]:
    "bg-emerald-50 text-emerald-700 border-emerald-100",
  [SubscriptionStatus.EXPIRED]:
    "bg-slate-100 text-slate-700 border-slate-200",
  [SubscriptionStatus.GRACE]: "bg-amber-50 text-amber-700 border-amber-100",
  [SubscriptionStatus.ON_HOLD]: "bg-orange-50 text-orange-700 border-orange-100",
  [SubscriptionStatus.CANCELED]:
    "bg-red-50 text-red-700 border-red-200",
};

export const priceLabel = (
  value?: number | string,
  currency?: PaymentCurrency
) => {
  if (value === undefined || value === null) return "-";
  if (typeof value === "string") {
    const trimmed = value.trim();
    if (!trimmed) return "-";
    const numeric = Number(trimmed);
    if (Number.isFinite(numeric)) {
      const formatter = new Intl.NumberFormat("en-US", {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
      });
      return `${currency ? `${currency} ` : ""}${formatter.format(numeric)}`;
    }
    return trimmed;
  }
  if (Number.isNaN(value)) return "-";
  const formatter = new Intl.NumberFormat("en-US", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  });
  return `${currency ? `${currency} ` : ""}${formatter.format(value)}`;
};

export const formatDateTime = (value?: string | Date) => {
  if (!value) return "-";
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN", { hour12: false });
};
