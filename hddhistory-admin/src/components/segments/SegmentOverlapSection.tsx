import React, { useState } from "react";
import {
  Button,
  CircularProgress,
  FormControl,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Typography,
} from "@mui/material";

import { segmentService } from "../../services/segmentService";
import { ISegment, SegmentOverlap } from "../../types/interface/segment.interface";
import SegmentVennDiagram from "./SegmentVennDiagram";

interface Props {
  segments: ISegment[];
}

/**
 * Pairwise overlap: pick two segments, see |A|, |B|, |A∩B| and an illustrative
 * Venn. Computed on demand only — like a single stats call, this can be slow,
 * so nothing runs until "So sánh" is pressed.
 */
const SegmentOverlapSection: React.FC<Props> = ({ segments }) => {
  const [aId, setAId] = useState("");
  const [bId, setBId] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<SegmentOverlap | null>(null);

  const canCompare = Boolean(aId) && Boolean(bId) && aId !== bId && !loading;

  const compare = async () => {
    if (!canCompare) return;
    setLoading(true);
    setError(null);
    try {
      const res = await segmentService.overlap(aId, bId);
      setResult(res.data);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không so sánh được, thử lại.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Paper variant="outlined" className="p-5">
      <Typography variant="h6" className="mb-1">
        So sánh chồng lấp
      </Typography>
      <p className="mb-4 max-w-2xl text-sm text-gray-500">
        Chọn hai phân khúc để xem có bao nhiêu user thuộc cả hai. Sơ đồ chỉ mang
        tính minh hoạ (kích thước vòng tròn và phần chồng lấp là gần đúng),
        các số bên dưới mới là số chính xác.
      </p>

      {segments.length < 2 ? (
        <p className="text-sm text-gray-500">
          Cần ít nhất 2 phân khúc để so sánh.
        </p>
      ) : (
        <>
          <div className="flex flex-wrap items-start gap-3">
            <FormControl size="small" className="min-w-[220px]">
              <InputLabel id="segment-overlap-a">Phân khúc A</InputLabel>
              <Select
                labelId="segment-overlap-a"
                label="Phân khúc A"
                value={aId}
                onChange={(e) => setAId(e.target.value)}
              >
                {segments.map((s) => (
                  <MenuItem key={s._id} value={s._id} disabled={s._id === bId}>
                    {s.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <FormControl size="small" className="min-w-[220px]">
              <InputLabel id="segment-overlap-b">Phân khúc B</InputLabel>
              <Select
                labelId="segment-overlap-b"
                label="Phân khúc B"
                value={bId}
                onChange={(e) => setBId(e.target.value)}
              >
                {segments.map((s) => (
                  <MenuItem key={s._id} value={s._id} disabled={s._id === aId}>
                    {s.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <Button
              variant="contained"
              onClick={compare}
              disabled={!canCompare}
              sx={{ minWidth: 104, height: 40 }}
            >
              {loading ? <CircularProgress size={18} color="inherit" /> : "So sánh"}
            </Button>
          </div>

          {error && <p className="mt-3 text-sm text-red-600">{error}</p>}

          {result && (
            <div className="mt-5 grid gap-6 md:grid-cols-[1fr_240px]">
              <SegmentVennDiagram
                nameA={result.a.name}
                nameB={result.b.name}
                countA={result.a.count}
                countB={result.b.count}
                intersection={result.intersection}
              />
              <div className="flex flex-col gap-2 self-center text-sm">
                <div className="flex justify-between gap-3">
                  <span className="text-gray-500">|A| — {result.a.name}</span>
                  <span className="font-semibold tabular-nums">{result.a.count}</span>
                </div>
                <div className="flex justify-between gap-3">
                  <span className="text-gray-500">|B| — {result.b.name}</span>
                  <span className="font-semibold tabular-nums">{result.b.count}</span>
                </div>
                <div className="flex justify-between gap-3 border-t pt-2">
                  <span className="text-gray-500">|A ∩ B|</span>
                  <span className="font-semibold tabular-nums">{result.intersection}</span>
                </div>
              </div>
            </div>
          )}
        </>
      )}
    </Paper>
  );
};

export default SegmentOverlapSection;
