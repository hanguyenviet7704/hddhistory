import React from "react";
import { ExclamationTriangleIcon } from "@heroicons/react/24/outline";

interface SectionCardProps {
  title: string;
  description?: string;
  icon?: React.ComponentType<React.SVGProps<SVGSVGElement>>;
  headerRight?: React.ReactNode;
  /** [field, message] pairs surfaced at the top of the card body, in addition to any inline placement. */
  errorSummary?: [string, string][];
  children: React.ReactNode;
}

const SectionCard: React.FC<SectionCardProps> = ({
  title,
  description,
  icon: Icon,
  headerRight,
  errorSummary = [],
  children,
}) => (
  <div className="rounded-2xl border border-slate-100 bg-white shadow-sm">
    <div className="flex items-start justify-between gap-3 p-4 border-b border-slate-100">
      <div className="flex items-start gap-3">
        {Icon && (
          <div className="h-9 w-9 flex-shrink-0 rounded-lg bg-teal-50 text-teal-700 flex items-center justify-center">
            <Icon className="h-5 w-5" />
          </div>
        )}
        <div>
          <p className="text-sm font-semibold text-slate-900">{title}</p>
          {description && <p className="text-xs text-slate-500 mt-0.5 max-w-xl">{description}</p>}
        </div>
      </div>
      {headerRight}
    </div>

    <div className="p-4 space-y-4">
      {errorSummary.length > 0 && (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 space-y-1">
          {errorSummary.map(([field, message]) => (
            <p key={field} className="text-xs text-red-700 flex items-start gap-1.5">
              <ExclamationTriangleIcon className="h-3.5 w-3.5 flex-shrink-0 mt-0.5" />
              <span>
                <code className="font-mono text-[11px] text-red-800">{field}</code>: {message}
              </span>
            </p>
          ))}
        </div>
      )}
      {children}
    </div>
  </div>
);

export default SectionCard;
