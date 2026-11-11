import React from "react";

interface ToggleSwitchProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label?: string;
  description?: string;
  disabled?: boolean;
  /** Renders as a full-width row: label + hint pinned left, switch pinned right. */
  fullWidth?: boolean;
}

// Hand-rolled accessible switch: a visually-hidden native checkbox drives a
// styled track/thumb via `peer-*` so keyboard focus, the native change
// event and the focus ring all keep working for free.
const ToggleSwitch: React.FC<ToggleSwitchProps> = ({
  checked,
  onChange,
  label,
  description,
  disabled = false,
  fullWidth = false,
}) => (
  <label
    className={`flex items-center gap-3 ${fullWidth ? "w-full justify-between" : ""} ${
      disabled ? "cursor-not-allowed opacity-60" : "cursor-pointer"
    }`}
  >
    {(label || description) && (
      <span className={fullWidth ? "text-left" : "text-right"}>
        <span className="block text-sm font-medium text-slate-800">{label}</span>
        {description && (
          <span className="block text-xs text-slate-500 mt-0.5">{description}</span>
        )}
      </span>
    )}
    <span className="relative inline-flex h-6 w-11 flex-shrink-0 items-center">
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        disabled={disabled}
        className="peer sr-only"
      />
      <span className="absolute inset-0 rounded-full bg-slate-300 peer-checked:bg-teal-600 transition-colors peer-focus-visible:ring-2 peer-focus-visible:ring-teal-500 peer-focus-visible:ring-offset-2" />
      <span className="absolute left-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform peer-checked:translate-x-5" />
    </span>
  </label>
);

export default ToggleSwitch;
