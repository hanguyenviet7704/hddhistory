import React from "react";

import { IHeatmapCell } from "../../types/interface/dashboard.interface";
import { SERIES, formatNumber } from "./dashboardTheme";

interface Props {
  cells: IHeatmapCell[];
}

// Mongo's `$dayOfWeek` is 1 = Sunday. Displayed Monday-first, the way a week is
// read here, so Sunday moves to the bottom row.
const ROWS = [
  { weekday: 2, label: "Thứ 2" },
  { weekday: 3, label: "Thứ 3" },
  { weekday: 4, label: "Thứ 4" },
  { weekday: 5, label: "Thứ 5" },
  { weekday: 6, label: "Thứ 6" },
  { weekday: 7, label: "Thứ 7" },
  { weekday: 1, label: "CN" },
];

const HOURS = Array.from({ length: 24 }, (_, hour) => hour);

const weekdayLabel = (weekday: number) =>
  ROWS.find((row) => row.weekday === weekday)?.label ?? String(weekday);

/**
 * Weekday × hour grid of how many distinct people were active.
 *
 * A grid rather than 7 line charts because the question it answers is "when do
 * we push a reminder" — that is a scan for the darkest cell, not a comparison
 * of curves. Intensity is one hue at varying strength (magnitude, so a single
 * ramp), and every cell carries its exact count in the tooltip, since opacity
 * alone is not a readable value.
 */
const ActivityHeatmap: React.FC<Props> = ({ cells }) => {
  const byKey = new Map(
    cells.map((cell) => [`${cell.weekday}-${cell.hour}`, cell.users])
  );
  const max = Math.max(...cells.map((cell) => cell.users), 1);
  const peak = cells.reduce<IHeatmapCell | null>(
    (best, cell) => (!best || cell.users > best.users ? cell : best),
    null
  );

  return (
    <div>
      <div className="overflow-x-auto">
        <div className="min-w-[640px]">
          <div
            className="grid gap-[2px]"
            style={{ gridTemplateColumns: `44px repeat(24, minmax(0, 1fr))` }}
          >
            <span />
            {HOURS.map((hour) => (
              <span
                key={hour}
                className="text-center text-[10px] leading-4 text-gray-400"
              >
                {hour % 2 === 0 ? hour : ""}
              </span>
            ))}

            {ROWS.map((row) => (
              <React.Fragment key={row.weekday}>
                <span className="pr-1 text-right text-[11px] leading-6 text-gray-500">
                  {row.label}
                </span>
                {HOURS.map((hour) => {
                  const users = byKey.get(`${row.weekday}-${hour}`) ?? 0;
                  const isPeak =
                    peak?.weekday === row.weekday && peak?.hour === hour;
                  return (
                    <div
                      key={hour}
                      title={`${row.label}, ${hour}:00 — ${formatNumber(
                        users
                      )} người`}
                      className={`h-6 rounded-[3px] ${
                        isPeak ? "ring-2 ring-blue-700" : ""
                      }`}
                      style={{
                        backgroundColor: SERIES.active,
                        // A floor of 0.05 keeps empty cells visible as cells
                        // rather than as holes in the grid.
                        opacity: users ? 0.12 + (users / max) * 0.88 : 0.05,
                      }}
                    />
                  );
                })}
              </React.Fragment>
            ))}
          </div>
        </div>
      </div>

      <div className="mt-3 flex flex-wrap items-center gap-3 text-xs text-gray-500">
        <span className="flex items-center gap-1.5">
          Ít
          <span className="flex gap-[2px]">
            {[0.12, 0.35, 0.58, 0.8, 1].map((opacity) => (
              <span
                key={opacity}
                className="h-3 w-5 rounded-[2px]"
                style={{ backgroundColor: SERIES.active, opacity }}
              />
            ))}
          </span>
          Nhiều
        </span>
        {peak && peak.users > 0 && (
          <span>
            Đậm nhất:{" "}
            <strong className="text-gray-700">
              {weekdayLabel(peak.weekday)} {peak.hour}:00
            </strong>{" "}
            ({formatNumber(peak.users)} người) — ô viền đậm
          </span>
        )}
      </div>
    </div>
  );
};

export default ActivityHeatmap;
