import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  CheckCircleIcon,
  CreditCardIcon,
  ExclamationTriangleIcon,
  PlusIcon,
  QueueListIcon,
  ShoppingBagIcon,
  SparklesIcon,
} from "@heroicons/react/24/outline";
import { productService } from "../../services/payments/productService";
import {
  IProduct,
  ProductListQuery,
} from "../../types/interface/payments/product.interface";
import {
  PaymentCurrency,
  PaymentPlatform,
  ProductType,
} from "../../types/enum/payment.enum";
import ProductModal from "../../components/payments/ProductModal";

type ProductRecord = IProduct & { _id?: string };
type TabKey = "products" | "purchases" | "subscriptions";

const getProductId = (product: ProductRecord) =>
  product.id || product._id || "";

const normalizeProducts = (payload: any): ProductRecord[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const platformLabels: Record<PaymentPlatform, string> = {
  [PaymentPlatform.APPLE]: "Apple",
  [PaymentPlatform.GOOGLE]: "Google",
};

const typeLabels: Record<ProductType, string> = {
  [ProductType.IN_APP]: "In-App",
  [ProductType.SUBSCRIPTION]: "Subscription",
  [ProductType.NON_RENEWABLE]: "Non-renewable",
};

const priceLabel = (value?: number, currency?: PaymentCurrency) => {
  if (value === undefined || value === null || Number.isNaN(value)) return "-";
  const formatter = new Intl.NumberFormat("en-US", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  });
  return `${currency || ""} ${formatter.format(value)}`;
};

const StatCard: React.FC<{
  label: string;
  value: string | number;
  icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
  accent?: string;
}> = ({
  label,
  value,
  icon: Icon,
  accent = "from-teal-500 to-emerald-500",
}) => (
  <div className="rounded-2xl border border-slate-100 bg-white shadow-sm p-4 flex items-center gap-3">
    <div
      className={`h-12 w-12 rounded-xl bg-gradient-to-br ${accent} text-white flex items-center justify-center shadow`}
    >
      <Icon className="h-6 w-6" />
    </div>
    <div className="space-y-1">
      <p className="text-xs uppercase tracking-wide text-slate-500">{label}</p>
      <p className="text-xl font-semibold text-slate-900">{value}</p>
    </div>
  </div>
);

const ComingSoon: React.FC<{
  title: string;
  description: string;
  icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
}> = ({ title, description, icon: Icon }) => (
  <div className="rounded-2xl border border-dashed border-slate-200 bg-white p-10 text-center space-y-4 shadow-sm">
    <div className="mx-auto h-14 w-14 rounded-full bg-slate-100 text-teal-600 flex items-center justify-center">
      <Icon className="h-7 w-7" />
    </div>
    <div className="space-y-2">
      <p className="text-lg font-semibold text-slate-900">{title}</p>
      <p className="text-sm text-slate-600 max-w-xl mx-auto">{description}</p>
    </div>
    <div className="inline-flex items-center gap-2 rounded-full bg-teal-50 px-3 py-1 text-sm text-teal-700 border border-teal-100">
      <SparklesIcon className="h-4 w-4" />
      Coming soon
    </div>
  </div>
);

const ProductSection: React.FC = () => {
  const [products, setProducts] = useState<ProductRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [platformFilter, setPlatformFilter] = useState<string>("");
  const [typeFilter, setTypeFilter] = useState<string>("");
  const [statusFilter, setStatusFilter] = useState<
    "all" | "active" | "inactive"
  >("all");
  const [modalOpen, setModalOpen] = useState(false);
  const [selected, setSelected] = useState<ProductRecord | null>(null);
  const [modalLoading, setModalLoading] = useState(false);
  const [modalError, setModalError] = useState<string | null>(null);
  const [mutatingId, setMutatingId] = useState<string | null>(null);
  const [confirmId, setConfirmId] = useState<string | null>(null);

  const fetchProducts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const query = new ProductListQuery({
        search: search.trim(),
        take: 50,
      });
      if (platformFilter) query.platform = platformFilter as PaymentPlatform;
      if (typeFilter) query.type = typeFilter as ProductType;
      if (statusFilter !== "all") query.isActive = statusFilter === "active";

      const res = await productService.getList(query);
      const normalized = normalizeProducts(res);
      setProducts(normalized);
    } catch (err: any) {
      console.error("Failed to fetch products", err);
      setError(
        err?.response?.data?.message || "Không thể tải danh sách sản phẩm"
      );
      setProducts([]);
    } finally {
      setLoading(false);
    }
  }, [platformFilter, search, statusFilter, typeFilter]);

  useEffect(() => {
    const handle = setTimeout(() => {
      fetchProducts();
    }, 250);
    return () => clearTimeout(handle);
  }, [fetchProducts]);

  const stats = useMemo(() => {
    const total = products.length;
    const active = products.filter((p) => p.isActive).length;
    const ios = products.filter(
      (p) => p.platform === PaymentPlatform.APPLE
    ).length;
    const android = products.filter(
      (p) => p.platform === PaymentPlatform.GOOGLE
    ).length;
    const subs = products.filter(
      (p) => p.type === ProductType.SUBSCRIPTION
    ).length;
    return { total, active, ios, android, subs };
  }, [products]);

  const handleSave = async (payload: Partial<IProduct>, id?: string) => {
    setModalLoading(true);
    setModalError(null);
    try {
      if (id) {
        await productService.update(id, payload);
      } else {
        await productService.create(payload);
      }
      setModalOpen(false);
      setSelected(null);
      await fetchProducts();
    } catch (err: any) {
      console.error("Save product failed", err);
      setModalError(err?.response?.data?.message || "Không thể lưu sản phẩm");
    } finally {
      setModalLoading(false);
    }
  };

  const handleToggleActive = async (product: ProductRecord) => {
    const id = getProductId(product);
    if (!id) return;
    setMutatingId(id);
    try {
      await productService.update(id, { isActive: !product.isActive });
      setProducts((prev) =>
        prev.map((item) =>
          getProductId(item) === id
            ? { ...item, isActive: !product.isActive }
            : item
        )
      );
    } catch (err: any) {
      console.error("Toggle active failed", err);
      setError(err?.response?.data?.message || "Không thể cập nhật trạng thái");
    } finally {
      setMutatingId(null);
    }
  };

  const handleDelete = async () => {
    if (!confirmId) return;
    setMutatingId(confirmId);
    try {
      await productService.remove(confirmId);
      setProducts((prev) =>
        prev.filter((item) => getProductId(item) !== confirmId)
      );
    } catch (err: any) {
      console.error("Delete product failed", err);
      setError(err?.response?.data?.message || "Không thể xoá sản phẩm");
    } finally {
      setMutatingId(null);
      setConfirmId(null);
    }
  };

  const filteredProducts = useMemo(() => products, [products]);

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <StatCard
          label="Tổng sản phẩm"
          value={stats.total}
          icon={QueueListIcon}
        />
        <StatCard
          label="Đang bật"
          value={stats.active}
          icon={CheckCircleIcon}
          accent="from-emerald-500 to-teal-500"
        />
        <StatCard
          label="Apple"
          value={stats.ios}
          icon={SparklesIcon}
          accent="from-amber-400 to-orange-500"
        />
        <StatCard
          label="Google"
          value={stats.android}
          icon={ShoppingBagIcon}
          accent="from-sky-500 to-blue-500"
        />
        <StatCard
          label="Subscription"
          value={stats.subs}
          icon={CreditCardIcon}
          accent="from-fuchsia-500 to-purple-500"
        />
      </div>

      <div className="rounded-2xl border border-slate-100 bg-white shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3 p-4 border-b border-slate-100">
          <div className="flex flex-wrap gap-3">
            <div className="relative">
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Tìm theo title hoặc productId..."
                className="pl-10 pr-3 py-2 rounded-xl border border-slate-200 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 bg-slate-50/50"
              />
              <svg
                className="h-5 w-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
            </div>

            <select
              value={platformFilter}
              onChange={(e) => setPlatformFilter(e.target.value)}
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value="">Tất cả platform</option>
              <option value={PaymentPlatform.APPLE}>Apple</option>
              <option value={PaymentPlatform.GOOGLE}>Google</option>
            </select>

            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value="">Tất cả loại</option>
              <option value={ProductType.IN_APP}>In-App</option>
              <option value={ProductType.SUBSCRIPTION}>Subscription</option>
              <option value={ProductType.NON_RENEWABLE}>Non-renewable</option>
            </select>

            <select
              value={statusFilter}
              onChange={(e) =>
                setStatusFilter(e.target.value as "all" | "active" | "inactive")
              }
              className="px-3 py-2 rounded-xl border border-slate-200 bg-white focus:ring-2 focus:ring-teal-500"
            >
              <option value="all">Trạng thái</option>
              <option value="active">Đang bật</option>
              <option value="inactive">Đang tắt</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => fetchProducts()}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition"
            >
              <ArrowPathIcon className="h-5 w-5" />
              Làm mới
            </button>
            <button
              onClick={() => {
                setSelected(null);
                setModalError(null);
                setModalOpen(true);
              }}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl bg-gradient-to-r from-teal-600 to-emerald-500 text-white shadow hover:from-teal-700 hover:to-emerald-600"
            >
              <PlusIcon className="h-5 w-5" />
              Thêm sản phẩm
            </button>
          </div>
        </div>

        {error && (
          <div className="mx-4 mt-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 flex items-center gap-2">
            <ExclamationTriangleIcon className="h-5 w-5" />
            {error}
          </div>
        )}

        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-100">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Title
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Platform
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Product ID
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Type
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Price
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Status
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-slate-600">
                  Hành động
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-10">
                    <div className="flex flex-col items-center justify-center text-slate-500 gap-3">
                      <span className="h-8 w-8 border-2 border-teal-500 border-t-transparent rounded-full animate-spin" />
                      Đang tải sản phẩm...
                    </div>
                  </td>
                </tr>
              ) : filteredProducts.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-10">
                    <div className="flex flex-col items-center justify-center text-slate-500 gap-2">
                      <CreditCardIcon className="h-10 w-10 text-slate-300" />
                      <p className="font-medium text-slate-700">
                        Chưa có sản phẩm nào
                      </p>
                      <p className="text-sm text-slate-500">
                        Hãy tạo sản phẩm mới để quản lý thanh toán.
                      </p>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredProducts.map((product) => {
                  const id = getProductId(product);
                  return (
                    <tr key={id} className="hover:bg-slate-50/70">
                      <td className="px-4 py-3">
                        <div className="space-y-1">
                          <p className="font-semibold text-slate-900">
                            {product.title}
                          </p>
                          {product.description && (
                            <p className="text-xs text-slate-500 line-clamp-2">
                              {product.description}
                            </p>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <span className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-slate-100 text-xs font-medium text-slate-700">
                          <SparklesIcon className="h-4 w-4 text-amber-500" />
                          {platformLabels[product.platform]}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <code className="text-xs bg-slate-100 px-2 py-1 rounded-lg text-slate-700">
                          {product.productId}
                        </code>
                      </td>
                      <td className="px-4 py-3">
                        <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-indigo-50 text-indigo-700">
                          {typeLabels[product.type]}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        {product.salePrice ? (
                          <div className="space-y-0.5">
                            <p className="font-semibold text-emerald-600">
                              {priceLabel(product.salePrice, product.currency)}
                            </p>
                            <p className="text-xs text-slate-400 line-through">
                              {priceLabel(product.price, product.currency)}
                            </p>
                          </div>
                        ) : (
                          <p className="font-semibold text-slate-800">
                            {priceLabel(product.price, product.currency)}
                          </p>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        <button
                          onClick={() => handleToggleActive(product)}
                          disabled={mutatingId === id}
                          className={`px-3 py-1.5 rounded-full text-xs font-medium border transition ${
                            product.isActive
                              ? "bg-emerald-50 text-emerald-700 border-emerald-100"
                              : "bg-slate-100 text-slate-600 border-slate-200"
                          } ${mutatingId === id ? "opacity-70" : ""}`}
                        >
                          {product.isActive ? "Active" : "Inactive"}
                        </button>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => {
                              setSelected(product);
                              setModalError(null);
                              setModalOpen(true);
                            }}
                            className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 text-sm"
                          >
                            Sửa
                          </button>
                          <button
                            onClick={() => setConfirmId(id)}
                            disabled={mutatingId === id}
                            className="px-3 py-1.5 rounded-lg border border-red-200 text-red-700 hover:bg-red-50 text-sm"
                          >
                            Xóa
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {confirmId && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/30 px-3">
          <div className="bg-white rounded-2xl shadow-xl border border-slate-100 max-w-sm w-full p-6 space-y-4">
            <div className="flex items-center gap-3">
              <ExclamationTriangleIcon className="h-8 w-8 text-amber-500" />
              <div>
                <p className="font-semibold text-slate-900">
                  Xóa sản phẩm này?
                </p>
                <p className="text-sm text-slate-600">
                  Hành động này không thể hoàn tác.
                </p>
              </div>
            </div>
            <div className="flex justify-end gap-2">
              <button
                onClick={() => setConfirmId(null)}
                className="px-4 py-2 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50"
              >
                Hủy
              </button>
              <button
                onClick={handleDelete}
                disabled={mutatingId === confirmId}
                className="px-4 py-2 rounded-lg bg-red-600 text-white hover:bg-red-700 disabled:opacity-70"
              >
                Xóa
              </button>
            </div>
          </div>
        </div>
      )}

      <ProductModal
        isOpen={modalOpen}
        initial={selected}
        onClose={() => {
          setModalOpen(false);
          setSelected(null);
        }}
        onSubmit={handleSave}
        loading={modalLoading}
        error={modalError}
      />
    </div>
  );
};

const PaymentDashboard: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabKey>("products");

  const tabs: { key: TabKey; label: string; description: string }[] = [
    {
      key: "products",
      label: "Product management",
      description: "Quản lý SKU, giá và trạng thái hiển thị.",
    },
    {
      key: "purchases",
      label: "Purchases",
      description: "Lịch sử giao dịch in-app (sẽ bổ sung).",
    },
    {
      key: "subscriptions",
      label: "Subscriptions",
      description: "Theo dõi gia hạn và chu kỳ (sẽ bổ sung).",
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100 p-6">
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="rounded-3xl bg-gradient-to-r from-teal-700 via-emerald-600 to-teal-500 text-white shadow-xl p-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div className="space-y-1">
            <p className="text-sm uppercase tracking-wide text-white/80">
              Payment Control
            </p>
            <h1 className="text-2xl font-semibold">
              Thanh toán & Monetization
            </h1>
            <p className="text-white/80 text-sm max-w-2xl">
              Truy cập nhanh đến quản lý sản phẩm, purchase và subscription để
              kiểm soát dòng tiền của ứng dụng.
            </p>
          </div>
          <div className="flex items-center gap-3">
            <div className="px-3 py-2 rounded-xl bg-white/15 backdrop-blur text-sm">
              <span className="font-semibold">Payment</span> workspace
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
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
                  {tab.key === "products" && (
                    <CreditCardIcon className="h-5 w-5" />
                  )}
                  {tab.key === "purchases" && (
                    <ShoppingBagIcon className="h-5 w-5" />
                  )}
                  {tab.key === "subscriptions" && (
                    <SparklesIcon className="h-5 w-5" />
                  )}
                </div>
              </div>
            </button>
          ))}
        </div>

        {activeTab === "products" ? (
          <ProductSection />
        ) : activeTab === "purchases" ? (
          <ComingSoon
            title="Purchases dashboard"
            description="Sẽ hiển thị lịch sử giao dịch, trạng thái thanh toán và chi tiết hóa đơn."
            icon={ShoppingBagIcon}
          />
        ) : (
          <ComingSoon
            title="Subscription tracker"
            description="Sẽ quản lý chu kỳ, trial và trạng thái auto-renew cho từng user."
            icon={SparklesIcon}
          />
        )}
      </div>
    </div>
  );
};

export default PaymentDashboard;
