import React, { useState } from "react";
import {
  CreditCardIcon,
  ChartPieIcon,
  GlobeAltIcon,
  SparklesIcon,
  Square3Stack3DIcon,
  TicketIcon,
} from "@heroicons/react/24/outline";
import RevenueDashboard from "./components/RevenueDashboard";
import SubscriptionSection from "./components/SubscriptionSection";
import ProductSection from "./components/ProductSection";
import RegionalPriceSection from "./components/RegionalPriceSection";
import VoucherSection from "./components/VoucherSection";
import DiscountTierSection from "./components/DiscountTierSection";

type TabKey =
  | "dashboard"
  | "subscriptions"
  | "products"
  | "regionalPrices"
  | "vouchers"
  | "discountTiers";

const PaymentDashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabKey>("dashboard");

  const tabs: { key: TabKey; label: string; description: string }[] = [
    {
      key: "dashboard",
      label: "Dashboard",
      description: "Tổng quan doanh thu.",
    },
    {
      key: "subscriptions",
      label: "Subscriptions",
      description: "Theo dõi gia hạn và chu kỳ premium.",
    },
    {
      key: "products",
      label: "Product management",
      description: "Quản lý SKU, giá và trạng thái hiển thị.",
    },
    {
      key: "regionalPrices",
      label: "Regional prices",
      description: "Giá theo khu vực, đồng bộ từ App Store / Google Play.",
    },
    {
      key: "vouchers",
      label: "Vouchers",
      description: "Tra lịch sử mã khuyến mãi (chỉ đọc).",
    },
    {
      key: "discountTiers",
      label: "Bậc giảm giá",
      description: "Quy đổi % giảm giá của affiliate sang cặp SKU đổi giá.",
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="rounded-3xl bg-gradient-to-r from-teal-700 via-emerald-600 to-teal-500 text-white shadow-xl p-4 md:p-5 flex flex-col md:flex-row md:items-center md:justify-between gap-3 md:gap-4">
          <div className="space-y-1">
            <p className="text-xs uppercase tracking-wide text-white/80">
              Payment Control
            </p>
            <h1 className="text-xl md:text-2xl font-semibold">
              Thanh toán & Monetization
            </h1>
            <p className="text-white/80 text-xs md:text-sm max-w-2xl">
              Truy cập nhanh đến quản lý sản phẩm, purchase và subscription để
              kiểm soát dòng tiền của ứng dụng.
            </p>
          </div>
          <div className="flex items-center gap-3">
            <div className="px-3 py-1.5 rounded-xl bg-white/15 backdrop-blur text-xs md:text-sm">
              <span className="font-semibold">Payment</span> workspace
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-6 gap-3">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={`text-left rounded-2xl border transition shadow-sm p-4 ${
                activeTab === tab.key
                  ? "border-teal-200 bg-white"
                  : "border-slate-100 bg-white/80 hover:bg-white"
              }`}
            >
              <div className="flex items-center justify-between gap-2">
                <div>
                  <p className="text-sm font-semibold text-slate-900">
                    {tab.label}
                  </p>
                  <p className="text-xs text-slate-500 mt-1">
                    {tab.description}
                  </p>
                </div>
                <div
                  className={`h-8 w-8 rounded-lg flex items-center justify-center ${
                    activeTab === tab.key
                      ? "bg-teal-100 text-teal-700"
                      : "bg-slate-100 text-slate-500"
                  }`}
                >
                  {tab.key === "dashboard" && (
                    <ChartPieIcon className="h-5 w-5" />
                  )}
                  {tab.key === "products" && (
                    <CreditCardIcon className="h-5 w-5" />
                  )}
                  {tab.key === "subscriptions" && (
                    <SparklesIcon className="h-5 w-5" />
                  )}
                  {tab.key === "regionalPrices" && (
                    <GlobeAltIcon className="h-5 w-5" />
                  )}
                  {tab.key === "vouchers" && (
                    <TicketIcon className="h-5 w-5" />
                  )}
                  {tab.key === "discountTiers" && (
                    <Square3Stack3DIcon className="h-5 w-5" />
                  )}
                </div>
              </div>
            </button>
          ))}
        </div>

        {activeTab === "dashboard" ? (
          <RevenueDashboard />
        ) : activeTab === "subscriptions" ? (
          <SubscriptionSection />
        ) : activeTab === "products" ? (
          <ProductSection />
        ) : activeTab === "regionalPrices" ? (
          <RegionalPriceSection />
        ) : activeTab === "vouchers" ? (
          <VoucherSection />
        ) : (
          <DiscountTierSection />
        )}
      </div>
    </div>
  );
};

export default PaymentDashboard;
