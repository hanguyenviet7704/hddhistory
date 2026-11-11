import React, { useEffect, useMemo, useState } from "react";
import { XMarkIcon } from "@heroicons/react/24/outline";
import {
  IVoucherBulkCreatePayload,
  IVoucherMappingInput,
} from "../../types/interface/payments/voucher.interface";
import VoucherMappingsEditor from "./VoucherMappingsEditor";
import VoucherSharedFields, {
  emptyVoucherSharedFields,
  VoucherSharedFieldsValue,
} from "./VoucherSharedFields";
import {
  fromInputDateTime,
  numberOrUndefined,
  parseCodes,
  parseCountries,
} from "./voucherFormUtils";

interface VoucherBulkImportModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (payload: IVoucherBulkCreatePayload) => Promise<void>;
  loading?: boolean;
  error?: string | null;
}

const VoucherBulkImportModal: React.FC<VoucherBulkImportModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  loading = false,
  error = null,
}) => {
  const [codesText, setCodesText] = useState("");
  const [shared, setShared] = useState<VoucherSharedFieldsValue>(
    emptyVoucherSharedFields
  );
  const [mappings, setMappings] = useState<IVoucherMappingInput[]>([]);
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    setCodesText("");
    setShared(emptyVoucherSharedFields);
    setMappings([]);
    setFormError(null);
  }, [isOpen]);

  const codes = useMemo(() => parseCodes(codesText), [codesText]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (codes.length === 0) {
      setFormError(
        "Dán ít nhất 1 mã voucher (mỗi dòng một mã, hoặc phân cách bằng dấu phẩy)."
      );
      return;
    }

    const incompleteRow = mappings.some(
      (row) => !row.baseProductId || !row.targetProductId
    );
    if (incompleteRow) {
      setFormError(
        "Mỗi ánh xạ SKU cần chọn đủ SKU gốc và SKU khuyến mãi - xóa dòng còn thiếu hoặc hoàn thành nó."
      );
      return;
    }

    setFormError(null);
    const payload: IVoucherBulkCreatePayload = {
      codes,
      owner: shared.owner.trim() || undefined,
      discountPercent: numberOrUndefined(shared.discountPercent),
      validFrom: fromInputDateTime(shared.validFrom),
      validTo: fromInputDateTime(shared.validTo),
      maxUses: numberOrUndefined(shared.maxUses),
      perUserLimit: numberOrUndefined(shared.perUserLimit),
      countries: parseCountries(shared.countries),
      isActive: shared.isActive,
      mappings,
    };

    await onSubmit(payload);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-3 py-6 overflow-y-auto">
      <div className="w-full max-w-3xl bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden my-auto">
        <div className="flex items-center justify-between px-6 py-4 bg-gradient-to-r from-bronze-600 to-purple-500 text-white">
          <div>
            <p className="text-sm uppercase tracking-wide opacity-90">
              Bulk import
            </p>
            <h2 className="text-xl font-semibold">Tạo nhiều voucher cùng lúc</h2>
            <p className="text-xs text-white/80 mt-1">
              Các mã trùng với voucher đã tồn tại sẽ bị bỏ qua, không ghi đè.
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-full bg-white/10 hover:bg-white/20 transition"
            aria-label="Đóng"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        <form
          onSubmit={handleSubmit}
          className="p-6 space-y-4 max-h-[75vh] overflow-y-auto"
        >
          {(formError || error) && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
              {formError || error}
            </div>
          )}

          <label className="flex flex-col gap-1 text-sm text-slate-700">
            <span className="font-medium">Danh sách mã (codes)</span>
            <textarea
              value={codesText}
              onChange={(e) => setCodesText(e.target.value)}
              rows={6}
              placeholder={"SUMMER50-001\nSUMMER50-002\nSUMMER50-003"}
              className="rounded-lg border border-slate-200 px-3 py-2 font-mono text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
            />
            <span className="text-xs text-slate-400">
              Mỗi dòng một mã, hoặc phân cách bằng dấu phẩy.{" "}
              {codes.length > 0 && (
                <span className="font-medium text-slate-600">
                  Đã nhận diện {codes.length} mã.
                </span>
              )}
            </span>
          </label>

          <div className="border-t border-slate-100 pt-4">
            <p className="text-sm font-medium text-slate-700 mb-3">
              Cấu hình dùng chung cho tất cả mã ở trên
            </p>
            <VoucherSharedFields
              value={shared}
              onChange={(patch) => setShared((prev) => ({ ...prev, ...patch }))}
            />
          </div>

          <VoucherMappingsEditor value={mappings} onChange={setMappings} />

          <div className="flex items-center justify-end gap-3 pt-2 border-t border-slate-100 mt-4">
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
              className="px-4 py-2 rounded-lg bg-gradient-to-r from-bronze-600 to-purple-500 text-white hover:from-bronze-700 hover:to-purple-600 shadow-md disabled:opacity-70 flex items-center gap-2 min-w-[160px] justify-center"
            >
              {loading && (
                <span className="h-4 w-4 border-2 border-white/60 border-t-transparent rounded-full animate-spin" />
              )}
              Tạo {codes.length > 0 ? codes.length : ""} voucher
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default VoucherBulkImportModal;
