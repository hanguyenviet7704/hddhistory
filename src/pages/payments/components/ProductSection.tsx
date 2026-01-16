import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  CheckCircleIcon,
  CreditCardIcon,
  ExclamationTriangleIcon,
  PlusIcon,
  QueueListIcon,
  StarIcon,
} from "@heroicons/react/24/outline";
import ProductModal from "../../../components/payments/ProductModal";
import { productService } from "../../../services/payments/productService";
import {
  IProduct,
  ProductListQuery,
} from "../../../types/interface/payments/product.interface";
import { PaymentPlatform, ProductType } from "../../../types/enum/payment.enum";
import PaymentStatCard from "./PaymentStatCard";
import {
  platformIconTone,
  platformIcons,
  platformLabels,
  priceLabel,
  typeLabels,
} from "../paymentShared";

type ProductRecord = IProduct & { _id?: string };

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
  const [page, setPage] = useState(1);
  const take = 20;
  const [lastCount, setLastCount] = useState(0);

  const fetchProducts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const query = new ProductListQuery({
        search: search.trim(),
        take,
        page,
      });
      if (platformFilter) query.platform = platformFilter as PaymentPlatform;
      if (typeFilter) query.type = typeFilter as ProductType;
      if (statusFilter === "all") {
        query.isAll = true;
      } else {
        query.isActive = statusFilter === "active";
      }

      const res = await productService.getList(query);
      const normalized = normalizeProducts(res);
      setProducts(normalized);
      setLastCount(normalized.length);
    } catch (err: any) {
      console.error("Failed to fetch products", err);
      setError(
        err?.response?.data?.message || "Không thể tải danh sách sản phẩm"
      );
      setProducts([]);
      setLastCount(0);
    } finally {
      setLoading(false);
    }
  }, [page, platformFilter, search, statusFilter, typeFilter, take]);

  useEffect(() => {
    const handle = setTimeout(() => {
      fetchProducts();
    }, 250);
    return () => clearTimeout(handle);
  }, [fetchProducts]);

  useEffect(() => {
    setPage(1);
  }, [platformFilter, search, statusFilter, typeFilter]);

  const stats = useMemo(() => {
    const total = products.length;
    const active = products.filter((p) => p.isActive).length;
    const ios = products.filter(
      (p) => p.platform === PaymentPlatform.APPLE
    ).length;
    const android = products.filter(
      (p) => p.platform === PaymentPlatform.GOOGLE
    ).length;
    const subs = products.filter((p) =>
      [
        ProductType.SUBSCRIPTION_AUTO_RENEW,
        ProductType.SUBSCRIPTION_NON_RENEW,
      ].includes(p.type)
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

  const handleToggleBestDeal = async (product: ProductRecord) => {
    const id = getProductId(product);
    if (!id) return;
    setMutatingId(id);
    try {
      await productService.update(id, { bestDeal: !product.bestDeal });
      setProducts((prev) =>
        prev.map((item) =>
          getProductId(item) === id
            ? { ...item, bestDeal: !product.bestDeal }
            : item
        )
      );
    } catch (err: any) {
      console.error("Toggle best deal failed", err);
      setError(err?.response?.data?.message || "Không thể cập nhật best deal");
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

  const filteredProducts = useMemo(
    () =>
      [...products].sort((a, b) => {
        // Best deal lên đầu, sau đó subs auto-renew, subs non-renew, còn lại
        const bestDealScore =
          Number(b.bestDeal ?? false) - Number(a.bestDeal ?? false);
        if (bestDealScore !== 0) return bestDealScore;

        const typePriority = (type: ProductType) => {
          switch (type) {
            case ProductType.SUBSCRIPTION_AUTO_RENEW:
              return 3;
            case ProductType.SUBSCRIPTION_NON_RENEW:
              return 2;
            case ProductType.NON_CONSUMABLE:
              return 1;
            case ProductType.CONSUMABLE:
            default:
              return 0;
          }
        };
        return typePriority(b.type) - typePriority(a.type);
      }),
    [products]
  );

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <PaymentStatCard
          label="Tổng sản phẩm"
          value={stats.total}
          icon={QueueListIcon}
        />
        <PaymentStatCard
          label="Đang bật"
          value={stats.active}
          icon={CheckCircleIcon}
          accent="from-emerald-500 to-teal-500"
        />
        <PaymentStatCard
          label="Apple"
          value={stats.ios}
          icon={platformIcons[PaymentPlatform.APPLE]}
          accent="from-amber-400 to-orange-500"
        />
        <PaymentStatCard
          label="Google"
          value={stats.android}
          icon={platformIcons[PaymentPlatform.GOOGLE]}
          accent="from-sky-500 to-blue-500"
        />
        <PaymentStatCard
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
              <option value={ProductType.SUBSCRIPTION_AUTO_RENEW}>
                Subscription (Auto-renew)
              </option>
              <option value={ProductType.SUBSCRIPTION_NON_RENEW}>
                Subscription (Non-renew)
              </option>
              <option value={ProductType.NON_CONSUMABLE}>Non-consumable</option>
              <option value={ProductType.CONSUMABLE}>Consumable</option>
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
                  const basePrice = product.rawPrice ?? product.price;
                  const hasSale =
                    product.salePrice !== undefined &&
                    product.salePrice !== null;
                  const PlatformIcon = platformIcons[product.platform];
                  const platformTone = platformIconTone[product.platform];
                  return (
                    <tr key={id} className="hover:bg-slate-50/70">
                      <td className="px-4 py-3">
                        <div className="space-y-1">
                          <p className="font-semibold text-slate-900">
                            {product.title}
                          </p>
                          {product.bestDeal && (
                            <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-100">
                              <StarIcon className="h-4 w-4" />
                              Best deal
                            </span>
                          )}
                          {product.description && (
                            <p className="text-xs text-slate-500 line-clamp-2">
                              {product.description}
                            </p>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <span className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-slate-100 text-xs font-medium text-slate-700">
                          <PlatformIcon className={`h-4 w-4 ${platformTone}`} />
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
                        {hasSale ? (
                          <div className="space-y-0.5">
                            <p className="text-xs text-slate-400 line-through">
                              {priceLabel(basePrice, product.currency)}
                            </p>
                            <p className="font-semibold text-emerald-600">
                              {priceLabel(product.salePrice, product.currency)}
                            </p>
                          </div>
                        ) : (
                          <p className="font-semibold text-slate-800">
                            {priceLabel(basePrice, product.currency)}
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
                            onClick={() => handleToggleBestDeal(product)}
                            disabled={mutatingId === id}
                            className={`px-3 py-1.5 rounded-lg border text-sm inline-flex items-center gap-1.5 ${
                              product.bestDeal
                                ? "border-amber-200 bg-amber-50 text-amber-700"
                                : "border-slate-200 text-slate-700 hover:bg-slate-50"
                            } ${mutatingId === id ? "opacity-70" : ""}`}
                          >
                            <StarIcon className="h-4 w-4" />
                            {product.bestDeal ? "Best deal" : "Đặt best deal"}
                          </button>
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

      <div className="flex items-center justify-between text-sm text-slate-700">
        <div>
          Trang {page} · Hiển thị tối đa {take} mục/trang
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1 || loading}
            className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 disabled:opacity-60"
          >
            Trang trước
          </button>
          <button
            onClick={() => setPage((p) => p + 1)}
            disabled={loading || lastCount < take}
            className="px-3 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 disabled:opacity-60"
          >
            Trang sau
          </button>
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

export default ProductSection;
