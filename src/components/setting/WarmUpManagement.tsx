import { useCallback, useEffect, useState } from "react";
import {
  IWarmUpConfig,
  WarmUpConfigPayload,
  WarmUpInactivityUnit,
} from "../../types/interface/warmUpConfig.interface";
import { warmUpConfigService } from "../../services/warmUpConfigService";
import { useNotification } from "../../utils/hooks/useNotification";

const defaultConfig: IWarmUpConfig = {
  enabled: false,
  inactivityValue: 3,
  inactivityUnit: "days",
};

const UNIT_OPTIONS: { value: WarmUpInactivityUnit; label: string }[] = [
  { value: "seconds", label: "Seconds" },
  { value: "minutes", label: "Minutes" },
  { value: "hours", label: "Hours" },
  { value: "days", label: "Days" },
];

const WarmUpManagement = () => {
  const { showSuccess, showError } = useNotification();

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [config, setConfig] = useState<IWarmUpConfig>(defaultConfig);
  const [inactivityValueInput, setInactivityValueInput] = useState("3");
  const [fieldError, setFieldError] = useState<string | null>(null);

  const fetchConfig = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const res = await warmUpConfigService.get();
      setConfig({
        ...res,
        inactivityUnit: res.inactivityUnit ?? "days",
      });
      setInactivityValueInput(String(res.inactivityValue ?? 3));
    } catch (err) {
      console.error("Failed to fetch warm-up config", err);
      setError("Tải cấu hình warm-up thất bại");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchConfig();
  }, [fetchConfig]);

  const handleToggleEnabled = () => {
    setConfig((prev) => ({ ...prev, enabled: !prev.enabled }));
  };

  const handleInactivityValueChange = (
    e: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const value = e.target.value;
    setInactivityValueInput(value);

    const parsed = Number(value);
    if (!value || !Number.isInteger(parsed) || parsed < 1) {
      setFieldError("Giá trị phải là số nguyên lớn hơn hoặc bằng 1");
    } else {
      setFieldError(null);
    }
  };

  const handleUnitChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setConfig((prev) => ({
      ...prev,
      inactivityUnit: e.target.value as WarmUpInactivityUnit,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const parsedValue = Number(inactivityValueInput);
    if (
      !inactivityValueInput ||
      !Number.isInteger(parsedValue) ||
      parsedValue < 1
    ) {
      setFieldError("Giá trị phải là số nguyên lớn hơn hoặc bằng 1");
      return;
    }

    const payload: WarmUpConfigPayload = {
      enabled: config.enabled,
      inactivityValue: parsedValue,
      inactivityUnit: config.inactivityUnit,
    };

    try {
      setSaving(true);
      const saved = await warmUpConfigService.update(payload);
      setConfig({
        ...saved,
        inactivityUnit: saved.inactivityUnit ?? "days",
      });
      setInactivityValueInput(String(saved.inactivityValue ?? parsedValue));
      showSuccess("Lưu cấu hình warm-up thành công");
    } catch (err) {
      console.error("Failed to save warm-up config", err);
      showError("Lưu cấu hình warm-up thất bại");
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="rounded-xl border border-gray-200 bg-white p-8 text-center text-gray-500">
        Loading warm-up config...
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
            Lesson Warm-up
          </h2>
          <p className="text-sm text-gray-500">
            Cấu hình gợi ý warm-up cho người dùng quay lại học sau một thời
            gian không hoạt động.
          </p>
        </div>

        <div className="flex items-center justify-between rounded-md border border-gray-200 px-4 py-3">
          <div>
            <p className="text-sm font-medium text-gray-900">Enabled</p>
            <p className="text-sm text-gray-500">
              Bật/tắt tính năng warm-up cho toàn bộ người dùng.
            </p>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={config.enabled}
            aria-label="Toggle warm-up enabled"
            onClick={handleToggleEnabled}
            className={`relative inline-flex h-6 w-11 shrink-0 items-center rounded-full transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 focus-visible:ring-offset-2 ${
              config.enabled ? "bg-indigo-600" : "bg-gray-300"
            }`}
          >
            <span
              className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                config.enabled ? "translate-x-6" : "translate-x-1"
              }`}
            />
          </button>
        </div>

        <div>
          <label
            htmlFor="warm-up-inactivity-value"
            className="mb-1 block text-sm font-medium text-gray-700"
          >
            Inactivity threshold
          </label>
          <div className="flex items-center gap-2">
            <input
              id="warm-up-inactivity-value"
              type="number"
              min={1}
              step={1}
              value={inactivityValueInput}
              onChange={handleInactivityValueChange}
              onBlur={handleInactivityValueChange}
              className={`w-40 rounded-md border px-3 py-2 text-sm focus:outline-none focus:ring-2 ${
                fieldError
                  ? "border-red-400 focus:ring-red-400"
                  : "border-gray-300 focus:ring-indigo-500"
              }`}
            />
            <select
              id="warm-up-inactivity-unit"
              aria-label="Inactivity threshold unit"
              value={config.inactivityUnit}
              onChange={handleUnitChange}
              className="rounded-md border border-gray-300 bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              {UNIT_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>
          {fieldError ? (
            <p className="mt-1 text-sm text-red-600">{fieldError}</p>
          ) : (
            <p className="mt-1 text-sm text-gray-500">
              Amount of inactivity time before a returning user is offered the
              lesson warm-up.
            </p>
          )}
        </div>

        <div className="flex justify-end pt-2">
          <button
            type="submit"
            disabled={saving || !!fieldError}
            className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:bg-indigo-300"
          >
            {saving ? (
              <>
                <span className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                Saving...
              </>
            ) : (
              "Save changes"
            )}
          </button>
        </div>
      </form>
    </div>
  );
};

export default WarmUpManagement;
