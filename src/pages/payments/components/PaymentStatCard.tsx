import React from "react";

type PaymentStatCardProps = {
  label: string;
  value: string | number;
  icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
  accent?: string;
};

const PaymentStatCard: React.FC<PaymentStatCardProps> = ({
  label,
  value,
  icon: Icon,
  accent = "from-teal-500 to-emerald-500",
}) => (
  <div className="rounded-2xl border border-slate-100 bg-white shadow-sm p-4 flex items-center gap-3">
    <div
      className={`h-12 w-12 rounded-xl bg-gradient-to-br ${accent} text-white flex items-center justify-center shadow`}
    >
      <Icon className="h-6 w-6" />
    </div>
    <div className="space-y-1">
      <p className="text-xs uppercase tracking-wide text-slate-500">{label}</p>
      <p className="text-xl font-semibold text-slate-900">{value}</p>
    </div>
  </div>
);

export default PaymentStatCard;
