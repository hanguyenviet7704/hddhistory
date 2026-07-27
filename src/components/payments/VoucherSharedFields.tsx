import React from "react";
import { ExclamationTriangleIcon } from "@heroicons/react/24/outline";

export interface VoucherSharedFieldsValue {
  owner: string;
  discountPercent: string;
  validFrom: string;
  validTo: string;
  maxUses: string;
  perUserLimit: string;
  countries: string;
  isActive: boolean;
}

export const emptyVoucherSharedFields: VoucherSharedFieldsValue = {
  owner: "",
  discountPercent: "",
  validFrom: "",
  validTo: "",
  maxUses: "",
  perUserLimit: "",
  countries: "",
  isActive: true,
};

interface VoucherSharedFieldsProps {
  value: VoucherSharedFieldsValue;
  onChange: (patch: Partial<VoucherSharedFieldsValue>) => void;
  disabled?: boolean;
}

const VoucherSharedFields: React.FC<VoucherSharedFieldsProps> = ({
  value,
  onChange,
  disabled = false,
}) => {
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <label className="flex flex-col gap-1 text-sm text-slate-700">
          <span className="font-medium">Owner</span>
          <input
            value={value.owner}
            onChange={(e) => onChange({ owner: e.target.value })}
            placeholder="affiliate-eup-01"
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          />
          <span className="text-xs text-slate-400">
            Đối tác/affiliate sở hữu mã này, chỉ để báo cáo.
          </span>
        </label>

        <label className="flex flex-col gap-1 text-sm text-slate-700">
          <span className="font-medium">Giảm giá % (discountPercent)</span>
          <div className="relative w-32">
            <input
              type="number"
              min="0"
              max="100"
              step="1"
              value={value.discountPercent}
              onChange={(e) => onChange({ discountPercent: e.target.value })}
              placeholder="50"
              disabled={disabled}
              className="w-full rounded-lg border border-slate-200 px-3 py-2 pr-8 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
            />
            <span className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 text-sm pointer-events-none">
              %
            </span>
          </div>
          <span className="text-xs text-slate-400">
            Chỉ hiển thị/báo cáo - mức giảm thực tế là giá của SKU khuyến mãi
            (targetProductId) trên store. Không dùng số này để tính tiền.
          </span>
        </label>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <label className="flex flex-col gap-1 text-sm text-slate-700">
          <span className="font-medium">Valid from</span>
          <input
            type="datetime-local"
            value={value.validFrom}
            onChange={(e) => onChange({ validFrom: e.target.value })}
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          />
          <span className="text-xs text-slate-400">
            Để trống nếu không giới hạn thời điểm bắt đầu.
          </span>
        </label>

        <label className="flex flex-col gap-1 text-sm text-slate-700">
          <span className="font-medium">Valid to</span>
          <input
            type="datetime-local"
            value={value.validTo}
            onChange={(e) => onChange({ validTo: e.target.value })}
            disabled={disabled}
            className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
          />
          <span className="text-xs text-slate-400">
            Để trống nếu không giới hạn thời điểm kết thúc.
          </span>
        </label>
      </div>

      <label className="flex flex-col gap-1 text-sm text-slate-700 md:w-48">
        <span className="font-medium">Max uses</span>
        <input
          type="number"
          min="0"
          step="1"
          value={value.maxUses}
          onChange={(e) => onChange({ maxUses: e.target.value })}
          placeholder="100"
          disabled={disabled}
          className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
        />
        <span className="text-xs text-slate-400">
          Tổng số lượt đổi tối đa. Để trống nếu không giới hạn.
        </span>
      </label>

      <div className="rounded-lg border border-slate-200 p-3 space-y-3 bg-slate-50/60">
        <p className="text-xs font-medium text-amber-700 flex items-center gap-1.5">
          <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
          Chưa được backend áp dụng - dữ liệu bên dưới chỉ được lưu lại, chưa
          giới hạn thực tế lượt đổi.
        </p>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <label className="flex flex-col gap-1 text-sm text-slate-700">
            <span className="font-medium">Per-user limit</span>
            <input
              type="number"
              min="0"
              step="1"
              value={value.perUserLimit}
              onChange={(e) => onChange({ perUserLimit: e.target.value })}
              placeholder="1"
              disabled={disabled}
              className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-white"
            />
          </label>

          <label className="flex flex-col gap-1 text-sm text-slate-700">
            <span className="font-medium">Countries (ISO, phân cách dấu phẩy)</span>
            <input
              value={value.countries}
              onChange={(e) => onChange({ countries: e.target.value })}
              placeholder="VN, US"
              disabled={disabled}
              className="rounded-lg border border-slate-200 px-3 py-2 focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-white"
            />
          </label>
        </div>
      </div>

      <label className="flex items-center gap-2 text-sm text-slate-700">
        <input
          type="checkbox"
          checked={value.isActive}
          onChange={(e) => onChange({ isActive: e.target.checked })}
          disabled={disabled}
          className="h-4 w-4 rounded border-slate-300 text-teal-600 focus:ring-teal-500"
        />
        <span>Kích hoạt voucher</span>
      </label>
    </div>
  );
};

export default VoucherSharedFields;
