import { useCallback, useEffect, useState } from "react";
import { productService } from "../../services/payments/productService";
import {
  IProduct,
  ProductListQuery,
} from "../../types/interface/payments/product.interface";
import { PaymentPlatform } from "../../types/enum/payment.enum";
import { ProductOption, ProductsByPlatform } from "../../pages/paywall-config/paywallConfigDraft";

// Every SKU a paywall strategy references MUST point at a product that
// actually exists (and is active) in `iap_products` -- a free-text SKU here
// is exactly what makes the mobile paywall render blank. This hook is the
// single fetch shared by every product picker on the page (defaultUser,
// each impression rule, saleEvent) so they never drift out of sync and the
// catalog is only fetched once per page load / manual refresh.

type ProductRecord = IProduct & { _id?: string };

const normalizeProducts = (payload: any): ProductRecord[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data?.items)) return payload.data.items;
  if (Array.isArray(payload.data)) return payload.data;
  return [];
};

const toOption = (product: ProductRecord): ProductOption => ({
  id: product.id || product._id || product.productId,
  productId: product.productId,
  title: product.title,
});

export const useActivePaywallProducts = () => {
  const [productsByPlatform, setProductsByPlatform] = useState<ProductsByPlatform | null>(
    null
  );
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchProducts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const query = new ProductListQuery({ page: 1, take: 200, isActive: true });
      const res = await productService.getList(query);
      const records = normalizeProducts(res);
      setProductsByPlatform({
        apple: records
          .filter((p) => p.platform === PaymentPlatform.APPLE)
          .map(toOption),
        google: records
          .filter((p) => p.platform === PaymentPlatform.GOOGLE)
          .map(toOption),
      });
    } catch (err: any) {
      console.error("Failed to fetch active products", err);
      setError(
        err?.response?.data?.message ||
          "Không thể tải danh sách sản phẩm đang active"
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  return { productsByPlatform, loading, error, refetch: fetchProducts };
};
