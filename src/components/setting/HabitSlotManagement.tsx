import { useCallback, useEffect, useState } from "react";
import { habitConfigService } from "../../services/habitConfigService";
import { useNotification } from "../../utils/hooks/useNotification";

const DEFAULT_FREE_SLOTS = 3;
const MAX_FREE_SLOTS = 100;

const HabitSlotManagement = () => {
  const { showSuccess, showError } = useNotification();

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [slotsInput, setSlotsInput] = useState(String(DEFAULT_FREE_SLOTS));
  const [fieldError, setFieldError] = useState<string | null>(null);

  const validate = (value: string): string | null => {
    const parsed = Number(value);
    if (!value || !Number.isInteger(parsed) || parsed < 1) {
      return "Giá trị phải là số nguyên lớn hơn hoặc bằng 1";
    }
    if (parsed > MAX_FREE_SLOTS) {
      return `Giá trị tối đa là ${MAX_FREE_SLOTS}`;
    }
    return null;
  };

  const fetchConfig = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const res = await habitConfigService.get();
      setSlotsInput(String(res.freeActiveSlots ?? DEFAULT_FREE_SLOTS));
    } catch (err) {
      console.error("Failed to fetch habit config", err);
      setError("Tải cấu hình habit thất bại");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchConfig();
  }, [fetchConfig]);

  const handleSlotsChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setSlotsInput(value);
    setFieldError(validate(value));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const validation = validate(slotsInput);
    if (validation) {
      setFieldError(validation);
      return;
    }

    try {
      setSaving(true);
      const saved = await habitConfigService.update({
        freeActiveSlots: Number(slotsInput),
      });
      setSlotsInput(String(saved.freeActiveSlots ?? slotsInput));
      showSuccess("Lưu cấu hình habit thành công");
    } catch (err) {
      console.error("Failed to save habit config", err);
      showError("Lưu cấu hình habit thất bại");
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="rounded-xl border border-gray-200 bg-white p-8 text-center text-gray-500">
        Loading habit config...
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-xl border border-red-200 bg-red-50 p-8 text-center">
        <p className="mb-4 text-sm text-red-600">{error}</p>
        <button
          type="button"
          onClick={fetchConfig}
          className="rounded-lg border border-red-300 px-4 py-2 text-sm font-medium text-red-700 transition hover:bg-red-100"
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="max-w-2xl">
      <form
        onSubmit={handleSubmit}
        className="space-y-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm"
      >
        <div>
          <h2 className="mb-1 text-lg font-medium text-gray-900">
            Habit slots
          </h2>
          <p className="text-sm text-gray-500">
            Số thói quen được phép hoạt động đồng thời với người dùng miễn phí.
            Người dùng Premium luôn không giới hạn.
          </p>
        </div>

        <div>
          <label
            htmlFor="habit-free-slots"
            className="mb-1 block text-sm font-medium text-gray-700"
          >
            Free active habit slots
          </label>
          <input
            id="habit-free-slots"
            type="number"
            min={1}
            max={MAX_FREE_SLOTS}
            step={1}
            value={slotsInput}
            onChange={handleSlotsChange}
            onBlur={handleSlotsChange}
            className={`w-40 rounded-md border px-3 py-2 text-sm focus:outline-none focus:ring-2 ${
              fieldError
                ? "border-red-400 focus:ring-red-400"
                : "border-gray-300 focus:ring-indigo-500"
            }`}
          />
          {fieldError && (
            <p className="mt-1 text-sm text-red-600">{fieldError}</p>
          )}
          <p className="mt-1 text-sm text-gray-500">
            Vượt giới hạn này, người dùng miễn phí phải tạm dừng một thói quen
            (hoặc nâng cấp Premium) mới bật thêm được thói quen mới.
          </p>
        </div>

        <div className="flex justify-end">
          <button
            type="submit"
            disabled={saving || Boolean(fieldError)}
            className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {saving ? "Saving..." : "Save changes"}
          </button>
        </div>
      </form>
    </div>
  );
};

export default HabitSlotManagement;
