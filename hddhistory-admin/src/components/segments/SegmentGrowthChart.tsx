import React from "react";

interface HistoryPoint {
  date: string;
  count: number;
}

interface Props {
  history: HistoryPoint[];
  width?: number;
  height?: number;
}

const formatTick = (iso: string) => {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}`;
};

/**
 * Self-contained inline SVG line chart for segment growth — there is no chart
 * library in this project and one is not worth pulling in for a single line.
 * Axis-light: min/max value labels instead of a full y-axis, and only a
 * handful of sparse x-axis date ticks regardless of history length.
 */
const SegmentGrowthChart: React.FC<Props> = ({ history, width = 600, height = 160 }) => {
  if (history.length === 0) {
    return (
      <p className="rounded border border-dashed border-gray-300 px-3 py-6 text-center text-sm text-gray-500">
        Chưa có lịch sử tăng trưởng — snapshot được chụp mỗi đêm, quay lại sau
        vài ngày để thấy biểu đồ.
      </p>
    );
  }

  const padding = { top: 16, right: 12, bottom: 22, left: 34 };
  const innerW = Math.max(1, width - padding.left - padding.right);
  const innerH = Math.max(1, height - padding.top - padding.bottom);

  const counts = history.map((h) => h.count);
  const maxCount = Math.max(...counts, 1);
  const minCount = Math.min(...counts, 0);
  const span = Math.max(maxCount - minCount, 1);

  const xAt = (i: number) =>
    padding.left + (history.length === 1 ? innerW / 2 : (i / (history.length - 1)) * innerW);
  const yAt = (count: number) =>
    padding.top + innerH - ((count - minCount) / span) * innerH;

  const points = history.map((h, i) => `${xAt(i)},${yAt(h.count)}`).join(" ");

  // First, middle, last — de-duplicated so short series do not repeat a tick.
  const tickIdxs = Array.from(
    new Set([0, Math.floor((history.length - 1) / 2), history.length - 1]),
  );

  const last = history[history.length - 1];

  return (
    <svg
      viewBox={`0 0 ${width} ${height}`}
      width="100%"
      height={height}
      role="img"
      aria-label={`Biểu đồ tăng trưởng: từ ${history[0].count} lên ${last.count} user`}
    >
      <line
        x1={padding.left}
        y1={padding.top + innerH}
        x2={width - padding.right}
        y2={padding.top + innerH}
        stroke="#e5e7eb"
      />

      <text x={2} y={padding.top + 8} fontSize="10" fill="#9ca3af">
        {maxCount}
      </text>
      <text x={2} y={padding.top + innerH} fontSize="10" fill="#9ca3af">
        {minCount}
      </text>

      <polyline points={points} fill="none" stroke="#4f46e5" strokeWidth={2} />

      {history.map((h, i) => (
        <circle
          key={h.date}
          cx={xAt(i)}
          cy={yAt(h.count)}
          r={i === history.length - 1 ? 3 : 2}
          fill="#4f46e5"
        />
      ))}

      {tickIdxs.map((i) => (
        <text
          key={i}
          x={xAt(i)}
          y={height - 6}
          fontSize="10"
          fill="#9ca3af"
          textAnchor="middle"
        >
          {formatTick(history[i].date)}
        </text>
      ))}

      <text
        x={width - padding.right}
        y={padding.top + 8}
        fontSize="11"
        fontWeight={600}
        fill="#4f46e5"
        textAnchor="end"
      >
        {last.count}
      </text>
    </svg>
  );
};

export default SegmentGrowthChart;
