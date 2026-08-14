import React from "react";

interface Props {
  nameA: string;
  nameB: string;
  countA: number;
  countB: number;
  intersection: number;
}

const WIDTH = 420;
const HEIGHT = 220;
const MAX_R = 88;
const MIN_R = 26;

/**
 * Illustrative two-circle Venn diagram: circle area roughly proportional to
 * each segment's count (radius ∝ sqrt(count) so AREA scales linearly), and
 * the distance between centers interpolated from "fully apart" (no overlap)
 * to "fully nested" (the smaller sits entirely inside the larger) by
 * intersection / min(|A|, |B|). Not geometrically exact — there is no single
 * correct picture for two circles from three numbers — just a fast visual
 * sense of "barely overlap" vs "mostly the same people".
 */
const SegmentVennDiagram: React.FC<Props> = ({
  nameA,
  nameB,
  countA,
  countB,
  intersection,
}) => {
  const maxCount = Math.max(countA, countB, 1);
  const scale = MAX_R / Math.sqrt(maxCount);
  const rA = Math.max(MIN_R, Math.sqrt(countA) * scale);
  const rB = Math.max(MIN_R, Math.sqrt(countB) * scale);

  const minCount = Math.min(countA, countB);
  const ratio = minCount > 0 ? Math.min(1, intersection / minCount) : 0;

  const dApart = rA + rB + 6;
  const dNested = Math.abs(rA - rB);
  const d = dApart - ratio * (dApart - dNested);

  const cx = WIDTH / 2;
  const cy = HEIGHT / 2;
  const cxA = cx - d / 2;
  const cxB = cx + d / 2;

  return (
    <svg
      viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
      width="100%"
      height={HEIGHT}
      role="img"
      aria-label={`Sơ đồ minh hoạ: ${nameA} (${countA}), ${nameB} (${countB}), giao ${intersection}`}
    >
      <circle cx={cxA} cy={cy} r={rA} fill="#6366f1" opacity={0.35} stroke="#4f46e5" />
      <circle cx={cxB} cy={cy} r={rB} fill="#f59e0b" opacity={0.35} stroke="#d97706" />
      <text x={cxA} y={Math.max(14, cy - rA - 8)} textAnchor="middle" fontSize="12" fill="#4f46e5">
        {nameA} ({countA})
      </text>
      <text x={cxB} y={Math.max(14, cy - rB - 8)} textAnchor="middle" fontSize="12" fill="#d97706">
        {nameB} ({countB})
      </text>
    </svg>
  );
};

export default SegmentVennDiagram;
