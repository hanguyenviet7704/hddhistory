import React from "react";
import { ChatBubbleLeftRightIcon, PlusIcon } from "@heroicons/react/24/outline";
import { emptyReview, ReviewDraft } from "../paywallConfigDraft";
import ReviewCard from "./ReviewCard";
import SectionCard from "./SectionCard";

interface ReviewsSectionProps {
  value: ReviewDraft[];
  onChange: (next: ReviewDraft[]) => void;
  disabled?: boolean;
  fieldErrors: Record<string, string>;
}

/**
 * The paywall's "What people say" carousel. Order here is display order in
 * the app. Not gated by an enabled switch like the campaigns above -- the
 * list itself, empty or not, is the whole state: empty means the app's 3
 * bundled reviews keep showing, any row means this list replaces them.
 */
const ReviewsSection: React.FC<ReviewsSectionProps> = ({
  value,
  onChange,
  disabled = false,
  fieldErrors,
}) => {
  const updateReview = (index: number, next: ReviewDraft) => {
    onChange(value.map((r, i) => (i === index ? next : r)));
  };

  const removeReview = (index: number) => {
    onChange(value.filter((_, i) => i !== index));
  };

  const addReview = () => {
    onChange([...value, emptyReview()]);
  };

  const moveReview = (index: number, direction: -1 | 1) => {
    const target = index + direction;
    if (target < 0 || target >= value.length) return;
    const next = [...value];
    [next[index], next[target]] = [next[target], next[index]];
    onChange(next);
  };

  return (
    <SectionCard
      title="Đánh giá người dùng (carousel)"
      description={
        'Danh sách đánh giá hiển thị dạng carousel trên paywall. Thứ tự bên dưới là thứ tự hiển thị trong app. Để trống toàn bộ thì app dùng 3 đánh giá mặc định built-in.'
      }
      icon={ChatBubbleLeftRightIcon}
    >
      {value.length === 0 ? (
        <p className="text-xs text-slate-500">
          Chưa có review nào — app sẽ dùng 3 đánh giá mặc định built-in.
        </p>
      ) : (
        <div className="space-y-2">
          {value.map((review, index) => (
            <ReviewCard
              key={review._localId}
              index={index}
              count={value.length}
              value={review}
              onChange={(next) => updateReview(index, next)}
              onRemove={() => removeReview(index)}
              onMoveUp={() => moveReview(index, -1)}
              onMoveDown={() => moveReview(index, 1)}
              disabled={disabled}
              fieldErrors={fieldErrors}
            />
          ))}
        </div>
      )}

      <button
        type="button"
        onClick={addReview}
        disabled={disabled}
        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-dashed border-slate-300 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50"
      >
        <PlusIcon className="h-4 w-4" />
        Thêm review
      </button>
    </SectionCard>
  );
};

export default ReviewsSection;
