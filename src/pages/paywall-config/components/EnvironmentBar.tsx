import React from "react";
import { BeakerIcon, ShieldExclamationIcon } from "@heroicons/react/24/outline";
import { PaywallEnvironment } from "../../../types/enum/paywall-config.enum";

interface EnvironmentBarProps {
  environment: PaywallEnvironment;
  onSwitch: (env: PaywallEnvironment) => void;
  disabled?: boolean;
}

// The current environment must be unmistakable, not a small <select> --
// publishing to prod is live with no staging step (see PaywallConfigPage).
const EnvironmentBar: React.FC<EnvironmentBarProps> = ({
  environment,
  onSwitch,
  disabled = false,
}) => {
  const isProd = environment === PaywallEnvironment.PROD;

  return (
    <div
      className={`rounded-2xl border p-4 flex flex-col md:flex-row md:items-center md:justify-between gap-3 ${
        isProd ? "bg-red-50 border-red-300" : "bg-teal-50 border-teal-200"
      }`}
    >
      <div className="flex items-center gap-3">
        <div
          className={`h-10 w-10 flex-shrink-0 rounded-full flex items-center justify-center ${
            isProd ? "bg-red-600 text-white" : "bg-teal-600 text-white"
          }`}
        >
          {isProd ? (
            <ShieldExclamationIcon className="h-6 w-6" />
          ) : (
            <BeakerIcon className="h-6 w-6" />
          )}
        </div>
        <div>
          <p className={`text-sm font-bold tracking-wide ${isProd ? "text-red-800" : "text-teal-800"}`}>
            {isProd ? "PRODUCTION" : "DEVELOPMENT"}
          </p>
          <p className={`text-xs ${isProd ? "text-red-700" : "text-teal-700"}`}>
            {isProd
              ? "Publishing here goes live to every production user immediately - there is no staging step."
              : "Safe to experiment - only dev-flavor apps read this value."}
          </p>
        </div>
      </div>

      <div
        className="inline-flex rounded-xl border border-slate-200 bg-white p-1 gap-1"
        role="group"
        aria-label="Environment"
      >
        <button
          type="button"
          onClick={() => onSwitch(PaywallEnvironment.DEV)}
          disabled={disabled}
          aria-pressed={!isProd}
          className={`min-h-[44px] px-5 py-2 rounded-lg text-sm font-semibold transition disabled:opacity-50 ${
            !isProd
              ? "bg-teal-600 text-white shadow"
              : "text-slate-600 hover:bg-slate-50"
          }`}
        >
          Dev
        </button>
        <button
          type="button"
          onClick={() => onSwitch(PaywallEnvironment.PROD)}
          disabled={disabled}
          aria-pressed={isProd}
          className={`min-h-[44px] px-5 py-2 rounded-lg text-sm font-semibold transition disabled:opacity-50 ${
            isProd ? "bg-red-600 text-white shadow" : "text-slate-600 hover:bg-slate-50"
          }`}
        >
          Prod
        </button>
      </div>
    </div>
  );
};

export default EnvironmentBar;
