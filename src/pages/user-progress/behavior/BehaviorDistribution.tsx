import React from "react";
import { INameCount } from "../../../types/interface/analytics.interface";

const CountTable = ({
  title,
  rows,
  emptyLabel,
}: {
  title: string;
  rows: INameCount[];
  emptyLabel: string;
}) => {
  const max = rows.reduce((acc, row) => Math.max(acc, row.count), 0);

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4">
      <h3 className="text-sm font-semibold text-gray-900 mb-2">{title}</h3>
      {rows.length === 0 ? (
        <p className="text-sm text-gray-500">{emptyLabel}</p>
      ) : (
        <ul className="space-y-1">
          {rows.map((row) => (
            <li key={row.name} className="flex items-center gap-2 text-sm">
              <span
                className="flex-1 truncate font-mono text-xs text-gray-700"
                title={row.name}
              >
                {row.name}
              </span>
              <span className="h-1.5 w-24 rounded-full bg-gray-100">
                <span
                  className="block h-1.5 rounded-full bg-blue-500"
                  style={{ width: `${max ? (row.count / max) * 100 : 0}%` }}
                />
              </span>
              <span className="w-10 text-right font-semibold text-gray-900">
                {row.count}
              </span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};

export default function BehaviorDistribution({
  topScreens,
  topEvents,
}: {
  topScreens: INameCount[];
  topEvents: INameCount[];
}) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
      <CountTable
        title="Top screen được xem"
        rows={topScreens ?? []}
        emptyLabel="Chưa có screen view."
      />
      <CountTable
        title="Top event được bắn"
        rows={topEvents ?? []}
        emptyLabel="Chưa có event."
      />
    </div>
  );
}
