import React, { useEffect, useState } from "react";
import {
  ArrowDownIcon,
  ArrowUpIcon,
  ChevronDownIcon,
  ChevronUpIcon,
  ExclamationTriangleIcon,
  TrashIcon,
} from "@heroicons/react/24/outline";
import ReviewContentEditor from "../../../components/paywall-config/ReviewContentEditor";
import { ReviewDraft } from "../paywallConfigDraft";

interface ReviewCardProps {
  index: number;
  count: number;
  value: ReviewDraft;
  onChange: (next: ReviewDraft) => void;
  onRemove: () => void;
  onMoveUp: () => void;
  onMoveDown: () => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
}

const RATING_OPTIONS = [1, 2, 3, 4, 5];

const ReviewCard: React.FC<ReviewCardProps> = ({
  index,
  count,
  value,
  onChange,
  onRemove,
  onMoveUp,
  onMoveDown,
  disabled = false,
  fieldErrors,
}) => {
  const prefix = `reviews[${index}]`;
  const rowErrors = Object.keys(fieldErrors).filter((f) => f.startsWith(prefix));
  const [expanded, setExpanded] = useState(true);
  const [avatarBroken, setAvatarBroken] = useState(false);

  // Never let a collapsed card hide a validation error from view.
  useEffect(() => {
    if (rowErrors.length > 0) setExpanded(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [rowErrors.length]);

  // A new URL deserves a fresh chance to load before we hide the preview again.
  useEffect(() => {
    setAvatarBroken(false);
  }, [value.avatarUrl]);

  const avatarUrl = value.avatarUrl.trim();

  return (
    <div className="rounded-xl border border-slate-200 bg-white">
      <div className="flex items-center justify-between gap-2 p-3 hover:bg-slate-50/60 rounded-xl transition-colors">
        <button
          type="button"
          onClick={() => setExpanded((prev) => !prev)}
          className="flex flex-1 items-center gap-2 text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 focus-visible:ring-offset-1 rounded min-w-0"
          aria-expanded={expanded}
        >
          {expanded ? (
            <ChevronUpIcon className="h-4 w-4 text-slate-500 flex-shrink-0" />
          ) : (
            <ChevronDownIcon className="h-4 w-4 text-slate-500 flex-shrink-0" />
          )}
          <span className="text-sm font-medium text-slate-800 truncate">
            {value.name.trim() || `Review ${index + 1}`}
          </span>
          <span className="text-xs text-slate-500 flex-shrink-0">
            {value.rating || "5"}★
          </span>
          {rowErrors.length > 0 && (
            <span className="inline-flex items-center gap-1 text-xs text-red-600 flex-shrink-0">
              <ExclamationTriangleIcon className="h-3.5 w-3.5" />
              {rowErrors.length} lỗi
            </span>
          )}
        </button>
        <div className="flex items-center gap-1 flex-shrink-0">
          <button
            type="button"
            onClick={onMoveUp}
            disabled={disabled || index === 0}
            aria-label={`Đưa review ${index + 1} lên trên`}
            title="Đưa lên"
            className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-slate-200 text-slate-500 hover:bg-slate-50 disabled:opacity-40"
          >
            <ArrowUpIcon className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={onMoveDown}
            disabled={disabled || index === count - 1}
            aria-label={`Đưa review ${index + 1} xuống dưới`}
            title="Đưa xuống"
            className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-slate-200 text-slate-500 hover:bg-slate-50 disabled:opacity-40"
          >
            <ArrowDownIcon className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={onRemove}
            disabled={disabled}
            aria-label={`Xóa review ${index + 1}`}
            title="Xóa review"
            className="inline-flex h-8 w-8 items-center justify-center rounded-lg border border-red-200 text-red-600 hover:bg-red-50 disabled:opacity-50"
          >
            <TrashIcon className="h-4 w-4" />
          </button>
        </div>
      </div>

      {expanded && (
        <div className="border-t border-slate-100 p-3 space-y-3">
          <div className="grid grid-cols-1 md:grid-cols-[1fr_2fr_100px] gap-3">
            <label className="flex flex-col gap-1 text-xs text-slate-700">
              <span className="font-medium">
                Tên người đánh giá
                <span className="text-red-500 ml-0.5">*</span>
              </span>
              <input
                value={value.name}
                onChange={(e) => onChange({ ...value, name: e.target.value })}
                placeholder="Bete Noir"
                disabled={disabled}
                className={`rounded-lg border px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50 ${
                  fieldErrors[`${prefix}.name`] ? "border-red-300" : "border-slate-200"
                }`}
              />
              {fieldErrors[`${prefix}.name`] && (
                <span className="text-[11px] text-red-600">
                  {fieldErrors[`${prefix}.name`]}
                </span>
              )}
            </label>

            <label className="flex flex-col gap-1 text-xs text-slate-700">
              <span className="font-medium">URL ảnh đại diện</span>
              <div className="flex items-center gap-2">
                {avatarUrl && !avatarBroken && (
                  <img
                    src={avatarUrl}
                    alt=""
                    onError={() => setAvatarBroken(true)}
                    className="h-10 w-10 flex-shrink-0 rounded-full object-cover border border-slate-200"
                  />
                )}
                <input
                  value={value.avatarUrl}
                  onChange={(e) => onChange({ ...value, avatarUrl: e.target.value })}
                  placeholder="https://cdn.../avatar.png"
                  disabled={disabled}
                  className="flex-1 rounded-lg border border-slate-200 px-3 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
                />
              </div>
              <span className="text-[11px] text-slate-500">
                Để trống thì app tự render đĩa chữ cái đầu của tên.
              </span>
            </label>

            <label className="flex flex-col gap-1 text-xs text-slate-700">
              <span className="font-medium">Sao</span>
              <select
                value={value.rating || "5"}
                onChange={(e) => onChange({ ...value, rating: e.target.value })}
                disabled={disabled}
                className="rounded-lg border border-slate-200 px-2 py-2 text-sm focus:ring-2 focus:ring-teal-500 focus:border-teal-500 disabled:bg-slate-50"
              >
                {RATING_OPTIONS.map((star) => (
                  <option key={star} value={star}>
                    {star}★
                  </option>
                ))}
              </select>
            </label>
          </div>

          <ReviewContentEditor
            idPrefix={`review-${index}`}
            value={value.content}
            onChange={(content) => onChange({ ...value, content })}
            disabled={disabled}
            requiredError={fieldErrors[`${prefix}.content.en`]}
          />
        </div>
      )}
    </div>
  );
};

export default ReviewCard;
