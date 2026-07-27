import React, { useEffect, useState } from "react";
import { XMarkIcon } from "@heroicons/react/24/outline";
import { IVoucher, IVoucherPayload } from "../../types/interface/payments/voucher.interface";
import VoucherMappingsEditor from "./VoucherMappingsEditor";
import VoucherSharedFields, {
  emptyVoucherSharedFields,
  VoucherSharedFieldsValue,
} from "./VoucherSharedFields";
import {
  fromInputDateTime,
  numberOrUndefined,
  parseCountries,
  toInputDateTime,
  countriesToInput,
} from "./voucherFormUtils";
import { IVoucherMappingInput } from "../../types/interface/payments/voucher.interface";

interface VoucherModalProps {
  isOpen: boolean;
  initial?: IVoucher | null;
  onClose: () => void;
  onSubmit: (payload: IVoucherPayload, id?: string) => Promise<void>;
  loading?: boolean;
  error?: string | null;
}

const VoucherModal: React.FC<VoucherModalProps> = ({
  isOpen,
  initial = null,
  onClose,
  onSubmit,
  loading = false,
  error = null,
}) => {
  const [code, setCode] = useState("");
  const [shared, setShared] = useState<VoucherSharedFieldsValue>(
    emptyVoucherSharedFields
  );
  const [mappings, setMappings] = useState<IVoucherMappingInput[]>([]);
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;

    if (initial) {
      setCode(initial.code || "");
      setShared({
        owner: initial.owner || "",
        discountPercent:
          initial.discountPercent !== undefined &&
          initial.discountPercent !== null
            ? String(initial.discountPercent)
            : "",
        validFrom: toInputDateTime(initial.validFrom),
        validTo: toInputDateTime(initial.validTo),
        maxUses:
          initial.maxUses !== undefined && initial.maxUses !== null
            ? String(initial.maxUses)
            : "",
        perUserLimit:
          initial.perUserLimit !== undefined && initial.perUserLimit !== null
            ? String(initial.perUserLimit)
            : "",
        countries: countriesToInput(initial.countries),
        isActive: initial.isActive ?? true,
      });
      setMappings(
        (initial.mappings || []).map((mapping) => ({
          platform: mapping.platform,
          baseProductId: mapping.baseProductId,
          targetProductId: mapping.targetProductId,
        }))
      );
    } else {
      setCode("");
      setShared(emptyVoucherSharedFields);
      setMappings([]);
    }
    setFormError(null);
  }, [initial, isOpen]);

  if (!isOpen) return null;

  const isEditing = Boolean(initial?.id);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!code.trim()) {
      setFormError("Code là bắt buộc");
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
    const payload: IVoucherPayload = {
      code: code.trim(),
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

    await onSubmit(payload, initial?.id);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-3 py-6 overflow-y-auto">
      <div className="w-full max-w-3xl bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden my-auto">
        <div className="flex items-center justify-between px-6 py-4 bg-gradient-to-r from-teal-600 to-emerald-500 text-white">
          <div>
            <p className="text-sm uppercase tracking-wide opacity-90">
              {isEditing ? "Chỉnh sửa voucher" : "Tạo voucher"}
            </p>
            <h2 className="text-xl font-semibold">
              {isEditing ? initial?.code : "Voucher management"}
            </h2>
            {isEditing && (
              <p className="text-xs text-white/80 mt-1">
                Đã dùng {initial?.usedCount ?? 0}
                {initial?.maxUses != null ? ` / ${initial.maxUses}` : " / không giới hạn"}
              </p>
            )}
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-full bg-white/10 hover:bg-white/20 transition"
            aria-label="Đóng"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4 max-h-[75vh] overflow-y-auto">
          {(formError || error) && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
              {formError || error}
            </div>
          )}

          <label className="flex flex-col gap-1 text-sm text-slate-700 md:w-64">
            <span className="font-medium">Code</span>
            <input
              value={code}
              onChange={(e) => setCode(e.target.value)}
              placeholder="SUMMER50"
              className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 uppercase"
              required
            />
            <span className="text-xs text-slate-400">
              Sẽ được lưu dạng viết hoa, không khoảng trắng thừa.
            </span>
          </label>

          <VoucherSharedFields
            value={shared}
            onChange={(patch) => setShared((prev) => ({ ...prev, ...patch }))}
          />

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
              className="px-4 py-2 rounded-lg bg-gradient-to-r from-teal-600 to-emerald-500 text-white hover:from-teal-700 hover:to-emerald-600 shadow-md disabled:opacity-70 flex items-center gap-2 min-w-[140px] justify-center"
            >
              {loading && (
                <span className="h-4 w-4 border-2 border-white/60 border-t-transparent rounded-full animate-spin" />
              )}
              {isEditing ? "Lưu thay đổi" : "Tạo voucher"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default VoucherModal;
