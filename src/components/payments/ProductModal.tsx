import React, { useEffect, useState } from "react";
import { XMarkIcon } from "@heroicons/react/24/outline";
import {
  PaymentCurrency,
  PaymentPlatform,
  ProductType,
} from "../../types/enum/payment.enum";
import { IProduct } from "../../types/interface/payments/product.interface";

type ProductRecord = IProduct & { _id?: string };

interface ProductModalProps {
  isOpen: boolean;
  initial?: ProductRecord | null;
  onClose: () => void;
  onSubmit: (payload: Partial<IProduct>, id?: string) => Promise<void>;
  loading?: boolean;
  error?: string | null;
}

const getProductId = (product?: ProductRecord | null) =>
  product?.id || product?._id || "";

const numberOrUndefined = (value: string) => {
  if (!value.trim()) return undefined;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
};

const ProductModal: React.FC<ProductModalProps> = ({
  isOpen,
  initial = null,
  onClose,
  onSubmit,
  loading = false,
  error = null,
}) => {
  const [title, setTitle] = useState("");
  const [productId, setProductId] = useState("");
  const [description, setDescription] = useState("");
  const [platform, setPlatform] = useState<PaymentPlatform>(
    PaymentPlatform.APPLE
  );
  const [type, setType] = useState<ProductType>(ProductType.IN_APP);
  const [currency, setCurrency] = useState<PaymentCurrency>(
    PaymentCurrency.USD
  );
  const [price, setPrice] = useState("");
  const [salePrice, setSalePrice] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;

    if (initial) {
      setTitle(initial.title || "");
      setProductId(initial.productId || "");
      setDescription(initial.description || "");
      setPlatform(initial.platform || PaymentPlatform.APPLE);
      setType(initial.type || ProductType.IN_APP);
      setCurrency(initial.currency || PaymentCurrency.USD);
      setPrice(
        initial.price !== undefined && initial.price !== null
          ? String(initial.price)
          : ""
      );
      setSalePrice(
        initial.salePrice !== undefined && initial.salePrice !== null
          ? String(initial.salePrice)
          : ""
      );
      setIsActive(initial.isActive ?? true);
    } else {
      setTitle("");
      setProductId("");
      setDescription("");
      setPlatform(PaymentPlatform.APPLE);
      setType(ProductType.IN_APP);
      setCurrency(PaymentCurrency.USD);
      setPrice("");
      setSalePrice("");
      setIsActive(true);
    }
    setFormError(null);
  }, [initial, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !productId.trim()) {
      setFormError("Title và Product ID là bắt buộc");
      return;
    }

    setFormError(null);
    const payload: Partial<IProduct> = {
      title: title.trim(),
      productId: productId.trim(),
      description: description.trim() || undefined,
      platform,
      type,
      currency,
      price: numberOrUndefined(price),
      salePrice: numberOrUndefined(salePrice),
      isActive,
    };

    await onSubmit(payload, getProductId(initial));
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-3">
      <div className="w-full max-w-2xl bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 bg-gradient-to-r from-teal-600 to-emerald-500 text-white">
          <div>
            <p className="text-sm uppercase tracking-wide opacity-90">
              {getProductId(initial) ? "Chỉnh sửa sản phẩm" : "Tạo sản phẩm"}
            </p>
            <h2 className="text-xl font-semibold">
              {getProductId(initial) ? initial?.title : "Product Management"}
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-full bg-white/10 hover:bg-white/20 transition"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {(formError || error) && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
              {formError || error}
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <label className="flex flex-col gap-1 text-sm text-slate-700">
              <span className="font-medium">Title</span>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Pro yearly"
                className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                required
              />
            </label>

            <label className="flex flex-col gap-1 text-sm text-slate-700">
              <span className="font-medium">Product ID</span>
              <input
                value={productId}
                onChange={(e) => setProductId(e.target.value)}
                placeholder="com.app.pro.yearly"
                className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
                required
              />
            </label>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <label className="flex flex-col gap-1 text-sm text-slate-700">
              <span className="font-medium">Platform</span>
              <select
                value={platform}
                onChange={(e) => setPlatform(e.target.value as PaymentPlatform)}
                className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
              >
                <option value={PaymentPlatform.APPLE}>Apple</option>
                <option value={PaymentPlatform.GOOGLE}>Google</option>
              </select>
            </label>

            <label className="flex flex-col gap-1 text-sm text-slate-700">
              <span className="font-medium">Type</span>
              <select
                value={type}
                onChange={(e) => setType(e.target.value as ProductType)}
                className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
              >
                <option value={ProductType.IN_APP}>In-App</option>
                <option value={ProductType.SUBSCRIPTION}>Subscription</option>
                <option value={ProductType.NON_RENEWABLE}>Non-renewable</option>
              </select>
            </label>

            <label className="flex flex-col gap-1 text-sm text-slate-700">
              <span className="font-medium">Currency</span>
              <select
                value={currency}
                onChange={(e) =>
                  setCurrency(e.target.value as PaymentCurrency)
                }
                className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
              >
                <option value={PaymentCurrency.USD}>USD</option>
                <option value={PaymentCurrency.VND}>VND</option>
              </select>
            </label>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <label className="flex flex-col gap-1 text-sm text-slate-700">
              <span className="font-medium">Price</span>
              <input
                type="number"
                min="0"
                step="0.01"
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                placeholder="9.99"
                className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
              />
            </label>

            <label className="flex flex-col gap-1 text-sm text-slate-700">
              <span className="font-medium">Sale price (optional)</span>
              <input
                type="number"
                min="0"
                step="0.01"
                value={salePrice}
                onChange={(e) => setSalePrice(e.target.value)}
                placeholder="7.99"
                className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
              />
            </label>
          </div>

          <label className="flex flex-col gap-1 text-sm text-slate-700">
            <span className="font-medium">Description</span>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
              placeholder="Notes about this product, billing cadence..."
              className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
            />
          </label>

          <div className="flex items-center justify-between pt-2">
            <label className="flex items-center gap-2 text-sm text-slate-700">
              <input
                type="checkbox"
                checked={isActive}
                onChange={(e) => setIsActive(e.target.checked)}
                className="h-4 w-4 rounded border-slate-300 text-teal-600 focus:ring-teal-500"
              />
              <span>Kích hoạt sản phẩm</span>
            </label>

            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 transition"
              >
                Hủy
              </button>
              <button
                type="submit"
                disabled={loading}
                className="px-4 py-2 rounded-lg bg-gradient-to-r from-teal-600 to-emerald-500 text-white hover:from-teal-700 hover:to-emerald-600 shadow-md disabled:opacity-70 flex items-center gap-2"
              >
                {loading && (
                  <span className="h-4 w-4 border-2 border-white/60 border-t-transparent rounded-full animate-spin" />
                )}
                {getProductId(initial) ? "Lưu thay đổi" : "Tạo sản phẩm"}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ProductModal;
